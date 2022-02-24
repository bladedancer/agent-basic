#!/bin/bash

ORIG_DIR=$CWD
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $ROOTDIR/..
. ./env.sh
cd $ROOTDIR

axway --env $PLATFORM_ENV central delete deployment nginx -s $ENVIRONMENT -y
sleep 10
axway --env $PLATFORM_ENV central delete virtualapi nginx -y
sleep 10

kubectl apply -f k8s-dep.yaml

axway --env $PLATFORM_ENV central apply -f vapi.yaml
axway --env $PLATFORM_ENV central apply -f releasetag.yaml
sleep 20


cat << EOF > deployment.yaml
apiVersion: v1alpha1
group: management
kind: VirtualHost
name: nginx
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  domain: "nginx.ampgw.com"
  secret:
    kind: Secret
    name: ampgw-tls
---
apiVersion: v1alpha1
group: management
kind: Deployment
name: nginx
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  virtualAPIRelease: nginx-1.0.0
  virtualHost: nginx
EOF

axway --env $PLATFORM_ENV central apply -f deployment.yaml

echo =========
echo = Test  =
echo =========
K8_INGRESS=$(kubectl describe -n kube-system service/traefik | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
echo curl -ki --resolve nginx.ampgw.com:8443:$K8_INGRESS https://nginx.ampgw.com:8443/demo/hello

cd $ORIG_DIR