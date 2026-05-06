# container-siglip2

## Apple `container`

### Building

```
$> container build --tag siglip-server --file Dockerfile .
```

### Running

```
$> container run --rm --memory 6G -p 127.0.0.1:5000:5000/tcp siglip-server
```

## Docker

### Building

```
$> docker buildx build --debug --platform=linux/amd64 --no-cache=true -f Dockerfile -t siglip_server .
```

### Running

```
$> docker run --rm -it --memory 6G --platform=linux/amd64 -p 5000:5000 siglip_server 
```

### Examples

```
$> make docker MODEL=google/siglip2-so400m-patch14-384 TAG=siglip-server-so400m-patch14-384
docker buildx build --debug --build-arg MODEL_NAME=google/siglip2-so400m-patch14-384 --platform=linux/amd64 --no-cache=true -f Dockerfile -t siglip-server-so400m-patch14-384 .

...time passes

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/j9kf48mtwrihqphxsigvm4kd0
```

```
$> make docker-run TAG=siglip-server-so400m-patch14-384
docker run --rm -it --platform=linux/amd64 -p 5000:5000 siglip-server-so400m-patch14-384

...huggingface stuff happens

Loading weights: 100%|███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 888/888 [00:00<00:00, 3464.22it/s]
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:5000 (Press CTRL+C to quit)
INFO:     151.101.0.223:34728 - "POST /embeddings HTTP/1.1" 200 OK
INFO:     151.101.0.223:48375 - "POST /embeddings HTTP/1.1" 200 OK
```
