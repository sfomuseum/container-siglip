# container-siglip2

## Motivation

This package is little more than a Dockerfile and some tools to run inside the container it produces. The container itself is a simple Python FastAPI HTTP server to generate vector embeddings (text and image) using one of Google' SigLIP2 models. The specific model is bundled with the container itself when it is built and the server tool is configured, by default, to only use that local data.

These tools have been demonstrated to work with both [Docker](#) and Apple's [container](#) framework. The goal is to produce a standalone artifact (application) which can be used to generate embeddings without having to install a bunch of additional software. While either the `docker` or the `container` application are still required they are both available with package installers from (presumably) trusted sources.

It's not quite one-click or plug-and-play but it does meaningfull reduce the steps required to set up the tooling necessary to create vector embeddings.

## Apple `container`

### Building

```
$> container build --tag siglip-server --file Dockerfile .
```

### Running

```
$> container run --rm --memory 6G -p 127.0.0.1:5000:5000/tcp siglip-server
```

### Examples

```
$> make container MODEL=google/siglip2-so400m-patch14-384 TAG=siglip-server-so400m-patch14-384 HF_TOKEN=s33kret
container build --build-arg MODEL_NAME=google/siglip2-so400m-patch14-384 --build-arg HF_TOKEN=s33kret --tag siglip-server-so400m-patch14-384 --file Dockerfile .

...time passes

 => => exporting manifest list sha256:4d9f6c5aab770f8f49739440b54806d02982346b5bbd413ea0574a87fc4ab469                                                                                                                        0.0s
 => => sending tarball                                                                                                                                                                                                       58.1s
siglip-server-so400m-patch14-384:latest
```

And then:

```
$> make container-run TAG=siglip-server-so400m-patch14-384
container run --rm --memory 5G -p 127.0.0.1:5000:5000/tcp siglip-server-so400m-patch14-384
Loading weights: 100%|██████████| 
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:5000 (Press CTRL+C to quit)
INFO:     192.168.64.1:63416 - "POST /embeddings HTTP/1.1" 200 OK
```

### Known-knowns

First of all, the `container` is still pre-1.0 so take everything with a grain of salt.

Sometimes, the internal networking layer gets messed up up. The easiest thing is to simply restart `container`:

```
$> container system stop
$> container system start
```

For larger models (like SigLIP) you may need to start the `container builder` process with explicit memory settings to prevent resource extraction.

```
$> container builder start --memory 16g --cpus 8
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

And then:

```
$> make docker-run TAG=siglip-server-so400m-patch14-384
docker run --rm -it --platform=linux/amd64 -p 5000:5000 siglip-server-so400m-patch14-384
Loading weights: 100%|███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████|
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:5000 (Press CTRL+C to quit)
INFO:     151.101.0.223:34728 - "POST /embeddings HTTP/1.1" 200 OK
INFO:     151.101.0.223:48375 - "POST /embeddings HTTP/1.1" 200 OK
```
