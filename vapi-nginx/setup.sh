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

kubectl apply -f backend/v1-dep.yaml

axway --env $PLATFORM_ENV central apply -f proxy/vapi.yaml
axway --env $PLATFORM_ENV central apply -f proxy/releasetag.yaml
sleep 20


cat << EOF > proxy/deployment.yaml
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
  domain: "nginx.$ENVIRONMENT.sandbox.ampc.axwaytest.net"
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

axway --env $PLATFORM_ENV central apply -f proxy/deployment.yaml

echo =========
echo = Test  =
echo =========
echo curl -i https://nginx.$ENVIRONMENT.sandbox.ampc.axwaytest.net/demo/hello

cd $ORIG_DIR