# Build
FROM python:3.14.4-slim-bookworm AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uv/bin/
COPY requirements.txt .

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends build-essential

RUN --mount=type=bind,source=requirements.txt,target=requirements.txt \
    --mount=type=cache,target=/root/.cache/uv \
    /uv/bin/uv pip install --system --no-cache -r requirements.txt

ARG MODEL_NAME=google/siglip2-so400m-patch16-naflex

COPY ./.cache/${MODEL_NAME}/hub /app/.cache/huggingface/hub

# Server
FROM python:3.14.4-slim-bookworm

RUN useradd -m siglip
USER siglip
WORKDIR /home/siglip/app

ARG MODEL_NAME=google/siglip2-so400m-patch16-naflex

ENV MODEL_NAME=${MODEL_NAME} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/home/siglip/app/.cache/huggingface

COPY --from=builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder --chown=siglip:siglip /app/.cache /home/siglip/app/.cache

COPY bin/siglip_server.py /usr/local/bin
COPY --chown=siglip:siglip bin/entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]