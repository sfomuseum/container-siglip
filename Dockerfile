# --- Stage 1: Builder ---
FROM python:3.14-slim-bookworm AS builder

WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download model using the new 'hf' CLI
ARG MODEL_NAME=google/siglip2-so400m-patch16-naflex
ENV HF_HOME=/app/.cache/huggingface
# FIXED: Replaced 'huggingface-cli' with 'hf'
RUN hf download ${MODEL_NAME}

# --- Stage 2: Final Runtime ---
FROM python:3.14-slim-bookworm

# Security: Run as non-root user
RUN useradd -m appuser
USER appuser
WORKDIR /home/appuser/app

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/home/appuser/app/.cache/huggingface

# Copy only installed packages and model cache from builder
# Verify your site-packages path matches the Python version
COPY --from=builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app/.cache /home/appuser/app/.cache

# Copy application code
COPY --chown=appuser:appuser . .

COPY bin/siglip_server.py /usr/local/bin

EXPOSE 5000