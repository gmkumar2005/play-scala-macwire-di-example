# play-scala-macwire-di-example

This project is used to demonstrate scala project build pipelines using graalvm and tekton

Original project is based on Play samples <https://github.com/playframework/play-samples> 

## Run sbt using graalvm docker image.
### Here we are using demonless podman
Replace the values you use for HOST_WORKSPACE , HOST_IVY_CACHE and HOST_CACHE

```
HOST_WORKSPACE=/home/kiran/workspace/playapp/play-scala-macwire-di-example ;\
HOST_IVY_CACHE=/home/kiran/.ivy2 ; \
HOST_CACHE=/home/kiran/.cache; HOST_SBT_CACHE=/home/kiran/.sbt ; \
podman run -it --rm \
 -v $HOST_WORKSPACE:/workspace \
 -v $HOST_IVY_CACHE:/home/sbtuser/.ivy2 \
 -v $HOST_CACHE:/home/sbtuser/.cache \
 -v $HOST_SBT_CACHE:/home/sbtuser/.sbt \
 -p 9000:9000 \
 hseeberger/scala-sbt:graalvm-ce-20.0.0-java11_1.3.10_2.13.2 /bin/sh -c \
 "cd /workspace &&  ls &&  sbt -Dsbt.ci=true run"
```
## Test if the application is running
The play framework runs on port 9000 by default. To verify the results you can use curl 

```
curl localhost:9000

kiran@lagom-dx4:~/workspace/playapp/play-scala-seed$ curl localhost:9000
<h1>Welcome</h1><p>Your new application is ready.</p>kiran@lagom-dx4:~/workspace/playapp/play-scala-seed$

```

