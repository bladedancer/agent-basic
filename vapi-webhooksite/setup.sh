#!/bin/bash

ORIG_DIR=$CWD
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $ROOTDIR/..
. ./env.sh
cd $ROOTDIR


axway --env $PLATFORM_ENV central delete deployment webhooksite -s $ENVIRONMENT -y
sleep 20
axway --env $PLATFORM_ENV central delete virtualapi webhooksite -y
sleep 20

axway --env $PLATFORM_ENV central apply -f ./vapi.yaml
axway --env $PLATFORM_ENV central apply -f ./releasetag.yaml
sleep 20

cat << EOF > ./deployment.yaml
apiVersion: v1alpha1
group: management
kind: ExternalSecret
name: $ENVIRONMENT-webhooksite
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  config:
    provider: Kubernetes
    name: ampgw-secret
    namespace: ampgw
  data:
    kind: TLS
    privateKeyAlias: listenerPrivateKey
    certificateAlias: listenerCertificate
---
apiVersion: v1alpha1
group: management
kind: VirtualHost
name: $ENVIRONMENT-webhooksite
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  domain: "webhooksite.$ENVIRONMENT.sandbox.ampc.axwaytest.net"
  secret:
    kind: ExternalSecret
    name: $ENVIRONMENT-webhooksite
---
apiVersion: v1alpha1
group: management
kind: Deployment
name: webhooksite
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  virtualAPIRelease: webhooksite-1.0.0
  virtualHost: $ENVIRONMENT-webhooksite
EOF

axway --env $PLATFORM_ENV central apply -f ./deployment.yaml

echo =========
echo = Test  =
echo =========
K8_INGRESS=$(kubectl describe -n kube-system service/traefik | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
echo curl -ki --resolve webhooksite.$ENVIRONMENT.sandbox.ampc.axwaytest.net:8443:$K8_INGRESS https://webhooksite.$ENVIRONMENT.sandbox.ampc.axwaytest.net:8443/hook/demo

cd $ORIG_DIR