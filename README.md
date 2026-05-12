# container-siglip2

## Motivation

This package is little more than a Dockerfile and some tools to run inside the container it produces. The container itself is a simple Python FastAPI HTTP server to generate vector embeddings (text and image) using one of Google's [SigLIP2](https://huggingface.co/blog/siglip2) models. The specific model is bundled with the container itself when it is built and the server tool is configured, by default, to only use that local data.

These tools have been demonstrated to work with both [Docker](https://docker.com/) and Apple's [container](https://github.com/apple/container/) framework. The goal is to produce a standalone artifact (application) which can be used to generate embeddings without having to install a bunch of additional software.

While at least one of the two `docker` or `container` applications are still required they are both available with package installers from (presumably) trusted sources. It's not quite one-click or plug-and-play but it does meaningfully reduce the steps required to set up the tooling necessary to create vector embeddings.

## Models

This container has been tested with the following models:

* google/siglip2-so400m-patch14-384
* google/siglip2-so400m-patch16-naflex

### Preparing "model context"

Rather than fetching any given model from scratch every time a container is built this package assumes that there is a local copy of that model, copied from your local HuggingFace cache, in the `.cache` folder. The easiest way to configure this is to use the `prep-model-context` Makefile target with model (or "repo ID"). The Makefile target will take of ensuring the correct path and naming conventions. For example:

```
$> make prep-model-context MODEL=google/siglip2-so400m-patch14-384
Staging model: google/siglip2-so400m-patch14-384
mkdir -p /usr/local/sfomuseum/container-siglip/.cache/google/siglip2-so400m-patch14-384/hub
cp -r "/Users/example/.cache/huggingface/hub/models--google--siglip2-so400m-patch14-384" /usr/local/sfomuseum/container-siglip/.cache/google/siglip2-so400m-patch14-384/hub/
```

_Remember: This assumes you have already fetched the model using the `hf download` tool and that it is present in your local HuggingFace cache._

## Building

The easiest way to get started is to use the `container` or `docker` Makefile targets. The following Makefile environment variables are available for these targets:

| Name | Default | Notes |
| --- | --- | --- |
| MODEL | google/siglip2-so400m-patch16-naflex | The name (or "repo ID") of the model you want to build a container with. |
| TAG | siglip-server-so400m-patch16-naflex | The tag you want to assign to the new container. |
| NOCACHE | | Disable build caches. |

### Apple `container`

```
$> make container MODEL=google/siglip2-so400m-patch14-384 TAG=siglip-server-so400m-patch14-384 HF_TOKEN=s33kret
container build --build-arg MODEL_NAME=google/siglip2-so400m-patch14-384 --tag siglip-server-so400m-patch14-384 --file Dockerfile .

...time passes

=> exporting manifest list sha256:4d9f6c5aab770f8f49739440b54806d02982346b5bbd413ea0574a87fc4ab469
0.0s
=> sending tarball
58.1s

siglip-server-so400m-patch14-384:latest
```

### Docker

```
$> make docker MODEL=google/siglip2-so400m-patch14-384 TAG=siglip-server-so400m-patch14-384
docker buildx build --debug --build-arg MODEL_NAME=google/siglip2-so400m-patch14-384 --platform=linux/amd64 --no-cache=true -f Dockerfile -t siglip-server-so400m-patch14-384 .

...time passes

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/j9kf48mtwrihqphxsigvm4kd0
```

## Running

The easiest way to get started is to use the `container-run` or `docker-run` Makefile targets.

| Name | Default | Notes |
| --- | --- | --- |
| TAG | siglip-server-so400m-patch16-naflex | The name of the tag associated with the container you want to run. |
| MEMORY | 16G | The amount of memory to assign to the container. |
| CPUS | 8 | The number of CPUs to assign to the container. |
| WORKERS | 1 | The number of `siglip_server` workers to start. |
| PORT | 5000 | The local port number to forward to the container. |

### Apple `container`

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

### Docker

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

## Known-knowns and other gotchas

### Performance

Running the `siglip_server` tool through a container incurs a noticeable performance cost, compared to running the same code locally on the host machine. This is considered to be an aceeptable, or at least known, tradeoff. The performance cost should be weighed relative to the security considerations of running code in a container environment and/or the hassle of installing dependencies locally. This will vary from situation to situation.

Anecdotally increasing the number of CPUs (with the `--cpus` flag) has more effect than simply increasing RAM (with the `--memory` flag).

### Docker(file)

The `builder` phase of the current [Dockerfile](Dockerfile) should be made its own image for faster building. I have not figured out the necessary command to do that _and_ maintain that image locally rather than pushing up to a third-party registry. Suggestions and pointers are welcome.

### Apple `container`

First of all, [the `container` tool](https://github.com/apple/container/tree/main) is still pre-1.0 so take everything that happens with a grain of salt and some patience. It also requires an Apple Silicon processor and works best under MacOS 26 or higher.

#### Networking

Sometimes, the internal networking layer gets messed up up. The easiest thing is to simply restart `container`:

```
$> container system stop
$> container system start
```

_Honestly, at this stage, restarting `container` is pretty much the easiest solution to most problems you might encounter._

#### Resource exhaustion

For larger models (like SigLIP) you may need to start the `container builder` process with explicit memory settings to prevent resource extraction.

```
$> container builder start --memory 16g --cpus 8
```

#### Disk space

The `container` framework uses a lot of disk space. That data is stored in `~/Library/Application\ Support/com.apple.container`.

```
$> du -h -d 1 ~/Library/Application\ Support/com.apple.container
  0B	/Users/example/Library/Application Support/com.apple.container/.build
 29M	/Users/example/Library/Application Support/com.apple.container/kernels
9.7G	/Users/example/Library/Application Support/com.apple.container/snapshots
6.9G	/Users/example/Library/Application Support/com.apple.container/content
8.0K	/Users/example/Library/Application Support/com.apple.container/networks
4.0K	/Users/example/Library/Application Support/com.apple.container/apiserver
 35G	/Users/example/Library/Application Support/com.apple.container/containers
  0B	/Users/example/Library/Application Support/com.apple.container/volumes
4.0K	/Users/example/Library/Application Support/com.apple.container/plugin-state
  0B	/Users/example/Library/Application Support/com.apple.container/builder
 52G	/Users/example/Library/Application Support/com.apple.container
```

Running `container prune` will often help. For example:

```
$> container builder stop
$> container prune
buildkit
Reclaimed 37.58 GB in disk space
```

Note that if you run `prune` you will need to run the `docker build` or `container build` commands with the `--no-cache` flag (since you will have just deleted their cache files).

#### Saving and loading images

It is possible to save a container to a disk image. This can be useful when you want to produce a container on one machine and then copy it for use on another machine.

```
$> container image save siglip-server-so400m-patch14-384 --output siglip-server-so400m-patch14-384.img
siglip-server-so400m-patch14-384

$> du -h siglip-server-so400m-patch14-384.img
6.8G	siglip-server-so400m-patch14-384.img
```

You would then import it using `container image save --input /path/to/image.img`.
