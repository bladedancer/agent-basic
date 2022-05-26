#!/bin/bash

. ./env.sh

echo ================================
echo === Create Namespace ${AMGPW_NAMESPACE:-default}
echo ================================
oc login -u system:admin
oc new-project ${AMGPW_NAMESPACE:-default}

oc cluster-info

echo ===============================
echo === Configure docker secret ===
echo ===============================
oc delete secret -n ${AMGPW_NAMESPACE:-default} regcred
oc create secret generic regcred \
    -n ${AMGPW_NAMESPACE:-default} \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson


