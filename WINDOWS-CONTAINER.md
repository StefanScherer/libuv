# Debug in Windows Containers

## Build the Docker image

To install all Windows development tools just create the Docker image

```
docker build -t build-libuv .
```

## Run the test

Now run the container

```
docker run -it build-libuv vcbuild.bat test
```

If you want to do some manual steps run it with

```
docker run -it build-libuv cmd
```
