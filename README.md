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
## run tekton pipeline

```
kubectl apply -f greeting-app-git.yaml -n play-demo
kubectl apply -f greeting-app-registry.yaml -n play-demo
kubectl delete Task greeting-app-build-push -n play-demo && kubectl apply -f greeting-app-build-push.yaml -n play-demo

kubectl delete  TaskRun  greeting-app-taskrun -n play-demo && kubectl apply -f greeting-app-taskrun.yaml -n play-demo
tkn taskrun describe greeting-app-taskrun -n play-demo 
tkn taskrun logs greeting-app-taskrun -n play-demo 

kubectl delete pipeline play-demo-pipeline -n play-demo && kubectl apply -f play-demo-pipeline.yaml -n play-demo

kubectl delete play-demo-pipelinerun.yaml -n play-demo  && kubectl apply -f play-demo-pipelinerun.yaml -n play-demo 

kubectl apply -f play-demo-pipelinerun.yaml -n play-demo 
tkn pipelinerun logs play-demo-pipelinerun-25  -f -n play-demo 

kubectl apply -f sbt-repo-pvc.yaml -n play-demo
podman run -it --rm  busybox  /bin/bash
```