# container-siglip2

## Apple `container`

### Running

```
container run --rm --memory 5G -p 127.0.0.1:5000:5000/tcp siglip-server /usr/local/bin/python /usr/local/bin/siglip_server.py --host 0.0.0.0
```

## Docker