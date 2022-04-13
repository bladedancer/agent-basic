#!/bin/bash

ORIG_DIR=$CWD
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $ROOTDIR/..
. ./env.sh
cd $ROOTDIR

axway --env $PLATFORM_ENV central delete deployment nginxv2 -s $ENVIRONMENT -y
sleep 10

kubectl apply -f backend/v2-dep.yaml

axway --env $PLATFORM_ENV central apply -f proxy/vapi.yaml
axway --env $PLATFORM_ENV central apply -f proxy/releasetag.yaml
sleep 20


cat << EOF > proxy/deployment.yaml
apiVersion: v1alpha1
group: management
kind: Deployment
name: nginx
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v2
spec:
  virtualAPIRelease: nginx-2.0.0
  virtualHost: nginx
EOF

axway --env $PLATFORM_ENV central apply -f proxy/deployment.yaml

echo =========
echo = Test  =
echo =========
K8_INGRESS=$(kubectl describe -n kube-system service/traefik | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
echo curl -ki --resolve nginx.ampgw.com:8443:$K8_INGRESS https://nginx.ampgw.com:8443/api/v2/demo/hello

cd $ORIG_DIR