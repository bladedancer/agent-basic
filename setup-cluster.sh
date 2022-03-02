#!/bin/bash

. ./env.sh

kubectl cluster-info

echo ================================
echo === Create Namespace ${AMGPW_NAMESPACE:-default}
echo ================================
if [ ! -z "${AMGPW_NAMESPACE}" ]; then
  kubectl create namespace ${AMGPW_NAMESPACE}
fi

echo ===============================
echo === Configure docker secret ===
echo ===============================
kubectl delete secret -n ${AMGPW_NAMESPACE:-default} regcred
kubectl create secret generic regcred \
    -n ${AMGPW_NAMESPACE:-default} \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson


