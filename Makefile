CWD=$(shell pwd)

NOCACHE=

MODEL=google/siglip2-so400m-patch16-naflex
TAG=siglip-server-so400m-patch16-naflex

PORT=5000

HF_CACHE := $(HOME)/.cache/huggingface/hub
HF_TOKEN=

fetch-model:
	hf download $(if $(HF_TOKEN),--token $(HF_TOKEN),) $(MODEL)

prep-model-context:
	@echo "Staging model: $(MODEL)"
	$(eval FOLDER_NAME := models--$(shell echo $(MODEL) | sed 's/\//--/g'))
	mkdir -p $(CWD)/.cache/$(MODEL)/hub
	cp -r "$(HF_CACHE)/$(FOLDER_NAME)" $(CWD)/.cache/$(MODEL)/hub/

container:
	container build $(if $(NOCACHE),--no-cache) --build-arg MODEL_NAME=$(MODEL) --tag $(TAG) --file Dockerfile .

container-run:
	container run --rm --memory 6G -p 127.0.0.1:$(PORT):5000/tcp $(TAG)

docker:
	docker buildx build $(if $(NOCACHE),--no-cache) --build-arg MODEL_NAME=$(MODEL) --platform=linux/amd64 --no-cache=true -f Dockerfile -t $(TAG) .

docker-run:
	docker run --rm -it --memory 6G --platform=linux/amd64 -p $(PORT):5000 $(TAG)
