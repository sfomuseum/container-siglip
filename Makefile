MODEL=google/siglip2-so400m-patch16-naflex
TAG=siglip-server
HF_TOKEN=

container:
	container build --build-arg MODEL_NAME=$(MODEL) --build-arg HF_TOKEN=$(HF_TOKEN) --tag $(TAG) --file Dockerfile .

container-run:
	container run --rm --memory 5G -p 127.0.0.1:5000:5000/tcp $(TAG)

docker:
	docker buildx build --debug --build-arg MODEL_NAME=$(MODEL) --platform=linux/amd64 --no-cache=true -f Dockerfile -t $(TAG) .

docker-run:
	docker run --rm -it --platform=linux/amd64 -p 5000:5000 $(TAG)
