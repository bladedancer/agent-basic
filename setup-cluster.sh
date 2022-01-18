#!/bin/bash

kubectl cluster-info

echo ===============================
echo === Configure docker secret ===
echo ===============================
kubectl delete secret regcred
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson


