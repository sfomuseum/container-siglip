container:
	container build --tag siglip-server --file Dockerfile .

docker:
	docker buildx build --debug --platform=linux/amd64 --no-cache=true -f Dockerfile -t siglip_server .
