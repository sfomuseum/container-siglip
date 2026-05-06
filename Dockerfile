# Build
FROM python:3.14-slim-bookworm AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

ARG MODEL_NAME=google/siglip2-so400m-patch16-naflex
ARG HF_TOKEN

ENV HF_HOME=/app/.cache/huggingface

RUN if [ -n "$HF_TOKEN" ]; then \
        hf download ${MODEL_NAME} --token ${HF_TOKEN}; \
    else \
        hf download ${MODEL_NAME}; \
    fi

# Server
FROM python:3.14-slim-bookworm

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