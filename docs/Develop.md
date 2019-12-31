

build 
```bash
$ docker build -t swift-dev:5.1.2 .
```

run docker in interactive mode
```
$ docker run -it --rm -v $(pwd):"/src" --workdir "/src" swift-dev:5.1.2
```