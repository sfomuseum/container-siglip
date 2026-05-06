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