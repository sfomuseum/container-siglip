CWD=$(shell pwd)

MODEL=google/siglip2-so400m-patch16-naflex
TAG=siglip-server-so400m-patch16-naflex
HF_TOKEN=

PORT=5000

HF_CACHE := $(HOME)/.cache/huggingface/hub

fetch-model:
	hf download $(if $(HF_TOKEN),--token $(HF_TOKEN),) $(MODEL)

prep-model-context:
	@echo "Staging model: $(REPO_ID)"
	$(eval FOLDER_NAME := models--$(shell echo $(REPO_ID) | sed 's/\//--/g'))
	mkdir -p $(CWD)/.cache/$(REPO_ID)/hub
	cp -r "$(HF_CACHE)/$(FOLDER_NAME)" $(CWD)/.cache/$(REPO_ID)/hub/

container:
	@make prep-model-context REPO_ID=$(MODEL)
	container build --build-arg MODEL_NAME=$(MODEL) --build-arg HF_TOKEN=$(HF_TOKEN) --tag $(TAG) --file Dockerfile .

container-run:
	container run --rm --memory 6G -p 127.0.0.1:$(PORT):5000/tcp $(TAG)

docker:
	@make prep-model-context REPO_ID=$(MODEL)
	docker buildx build --debug --build-arg MODEL_NAME=$(MODEL) --platform=linux/amd64 --no-cache=true -f Dockerfile -t $(TAG) .

docker-run:
	docker run --rm -it --memory 6G --platform=linux/amd64 -p 5000:5000 $(TAG)
