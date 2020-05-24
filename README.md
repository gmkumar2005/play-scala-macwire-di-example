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
kubectl delete Task deploy-using-kubectl -n play-demo && kubectl apply -f deploy-using-kubectl.yaml -n play-demo


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

## Tetkoncd permissions
```
kubectl create clusterrolebinding tetkon-admin-sa --clusterrole=cluster-admin --serviceaccount=default:tetkon-admin-sa -n play-demo


kubectl create rolebinding default \
  --clusterrole=cluster-admin \
  --serviceaccount=tekton-pipelines:default \
  --namespace=tekton-pipelines

Add --allow-privileged=true to:
#kube-apiserver config
sudo vim /var/snap/microk8s/current/args/kube-apiserver
sudo systemctl restart snap.microk8s.daemon-apiserver.service

```

## Run play-demo image locally
```
podman search registry.192.168.23.31.nip.io/ 
podman run -it --rm -p 9000:9000 registry.192.168.23.31.nip.io/play-demo/greeting-app:latest

```
## Deploy and expose to microk8s - use localhost:32000 since it is already added to insecure registries
```
kubectl create deployment greeting-app --image=localhost:32000/play-demo/greeting-app:latest -n play-demo 
kubectl expose deployment greeting-app --type=NodePort --port=9000 -n play-demo 
```
## Create ingress yaml greeting-app-deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: greeting-app
  labels:
    app: greeting-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: greeting-app
  template:
    metadata:
      labels:
        app: greeting-app
    spec:
      containers:
        - name: greeting-app
          image: localhost:32000/play-demo/greeting-app:latest
          ports:
            - containerPort: 9000
```

## Create ingress yaml greeting-app-ingress.yaml
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: play-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - host: play-app.192.168.23.31.nip.io
    http:
      paths:
        - path: /
          backend:
            serviceName: greeting-app
            servicePort: 9000
```

## Create service yaml greeting-app-service.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: greeting-app
spec:
  selector:
    app: greeting-app
  ports:
    - protocol: TCP
      port: 9000
      targetPort: 9000
```
## Apply the manifest
```
kubectl apply -f manifest/greeting-app-deployment.yaml -n play-demo
kubectl apply -f manifest/greeting-app-service.yaml -n play-demo
kubectl apply -f manifest/greeting-app-ingress.yaml -n play-demo
```
## Create a Task deploy-using-kubectl.yaml
```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: deploy-using-kubectl
spec:
  params:
    - name: path
      type: string
      description: Path to the manifest to apply
    - name: yamlPathToImage
      type: string
      description: |
        The path to the image to replace in the yaml manifest (arg to yq)
    - name: namespace
      type: string
      description : |
        image will be deployed in this namesapce
  resources:
    inputs:
      - name: source
        type: git
      - name: image
        type: image
  steps:
    - name: replace-image
      image: mikefarah/yq
      command: ["yq"]
      args:
        - "w"
        - "-i"
        - "$(params.path)"
        - "$(params.yamlPathToImage)"
        - "$(resources.inputs.image.url)"
    - name: run-kubectl
      image: lachlanevenson/k8s-kubectl
      command: ["kubectl"]
      args:
        - "apply"
        - "-f"
        - "$(params.path)"
        - "-n"
        - "$(params.namespace)"
```
##Configuring Pipeline execution credentials
```
kubectl create clusterrole tekton-role \
               --verb=* \
               --resource=deployments,deployments.apps  

kubectl create clusterrolebinding tutorial-binding \
  --clusterrole=tekton-role \
  --serviceaccount=default:default 
```

## Deployment options
```
# kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
# kubectl set image deployments/greeting-app greeting-app=localhost:32000/play-demo/greeting-app:latest -n play-demo
```

## Remove unwanted tekton pods
```
kubectl delete pod --field-selector=status.phase==Succeeded -n play-demo
kubectl delete pod --field-selector=status.phase==Terminated  -n play-demo
kubectl delete pod --field-selector=status.phase==Failed  -n play-demo
```

## Debug yq
```
podman run --rm -v "${PWD}":/workdir mikefarah/yq  yq w  tektoncd/manifest/greeting-app-deployment.yaml "spec.template.spec.containers[0].image" "hello"

```