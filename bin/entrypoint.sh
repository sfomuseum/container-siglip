#!/bin/sh

set -e
exec python /usr/local/bin/siglip_server/main.py --host 0.0.0.0 --model_name "${MODEL_NAME}"
