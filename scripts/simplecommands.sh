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


  