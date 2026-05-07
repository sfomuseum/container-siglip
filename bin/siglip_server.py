import argparse
import base64
import os
from io import BytesIO
import logging
from contextlib import asynccontextmanager
import asyncio
import time

import uvicorn
from fastapi import FastAPI, HTTPException, Body
from fastapi.concurrency import run_in_threadpool
from transformers import AutoProcessor, AutoModel
import torch
from PIL import Image

parser = argparse.ArgumentParser(description="SigLIP embeddings server")
parser.add_argument("--model_name", default="google/siglip2-so400m-patch16-naflex")
parser.add_argument("--host", default="localhost")
parser.add_argument("--port", type=int, default=5000)
parser.add_argument("--local_files", default=True, action="store_true")

_args = parser.parse_args()

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

torch.set_num_threads(os.cpu_count() // 2)
torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.benchmark = True

def _decode_image(b64: str, processor: AutoProcessor) -> torch.Tensor:
    img_bytes = base64.b64decode(b64)
    with Image.open(BytesIO(img_bytes)) as im:
        img = im.convert("RGB")
    return img

def _normalize(vec: torch.Tensor) -> torch.Tensor:
    return vec / vec.norm(p=2, dim=-1, keepdim=True)

@asynccontextmanager
async def lifespan(app: FastAPI):

    hf_offline = os.getenv("HF_HUB_OFFLINE") if _args.local_files else None
    
    if hf_offline:
        os.environ["HF_HUB_OFFLINE"] = "1"

    processor = AutoProcessor.from_pretrained(
        _args.model_name,
        local_files_only=_args.local_files,
    )
    
    base = AutoModel.from_pretrained(
        _args.model_name,
        local_files_only=_args.local_files,
    ).eval()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = base.to(device).eval()
    compiled = torch.compile(model, mode="max-autotune")  # compile after moving

    log.info("Model loaded")

    app.state.processor = processor
    app.state.model = model
    app.state.device = device
    
    yield
    
app = FastAPI(title="SigLIP Service", lifespan=lifespan)

@app.post("/embeddings")
async def embeddings(payload: dict = Body(...)):

    if "content" not in payload:
        raise HTTPException(status_code=400, detail="Missing 'content'")

    inputs = app.state.processor(text=payload["content"], return_tensors="pt").to(app.state.device, non_blocking=True)

    _start_time = time.perf_counter()
    
    with torch.inference_mode():
        out = await run_in_threadpool(
            lambda: app.state.model.get_text_features(**inputs)
        )
        
    vec = _normalize(out.pooler_output.squeeze(0))

    elapsed = time.perf_counter() - _start_time
    log.info("Text embeddings request processed in %.3f seconds", elapsed)

    return {"embeddings": vec.tolist(), "model": _args.model_name}
    
@app.post("/embeddings/image")
async def embeddings_image(payload: dict = Body(...)):

    try:
        img_b64 = payload["image_data"][0]["data"]
    except (KeyError, IndexError) as exc:
        log.error("Malformed payload: %s", exc)
        raise HTTPException(status_code=400, detail="Missing or malformed 'image_data'")

    try:
        img = await asyncio.to_thread(_decode_image, img_b64, app.state.processor)
    except Exception as exc:
        log.exception("Image decoding failed")
        raise HTTPException(status_code=400, detail="Invalid image data")

    _start_time = time.perf_counter()
    
    inputs = app.state.processor(images=img, return_tensors="pt")
    inputs = {k: v.to(app.state.device) for k, v in inputs.items()}
        
    with torch.inference_mode():        
        out = await run_in_threadpool(
            lambda: app.state.model.get_image_features(**inputs)
        )
        
    vec = _normalize(out.pooler_output.squeeze(0))

    elapsed = time.perf_counter() - _start_time
    log.info("Image embeddings request processed in %.3f seconds", elapsed)

    return {"embeddings": vec.tolist(), "model": _args.model_name}

if __name__ == "__main__":
    uvicorn.run(app, host=_args.host, port=_args.port, loop="uvloop")
