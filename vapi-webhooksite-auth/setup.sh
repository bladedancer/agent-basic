#!/bin/bash

ORIG_DIR=$CWD
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $ROOTDIR/..
. ./env.sh
cd $ROOTDIR

kubectl delete secret webhooksite-secret -n ${AMGPW_NAMESPACE:-default}
kubectl create secret generic webhooksite-secret \
    -n ${AMGPW_NAMESPACE:-default} \
    --from-literal apikey=SomeExamplePassword

axway --env $PLATFORM_ENV central delete deployment webhooksite-auth -s $ENVIRONMENT -y
sleep 20
axway --env $PLATFORM_ENV central delete virtualapi webhooksite-auth -y
sleep 20

axway --env $PLATFORM_ENV central apply -f ./vapi.yaml
axway --env $PLATFORM_ENV central apply -f ./vapi-rules.yaml
axway --env $PLATFORM_ENV central apply -f ./vapi-virtualservice.yaml
axway --env $PLATFORM_ENV central apply -f ./releasetag.yaml
sleep 20

cat << EOF > ./deployment.yaml
apiVersion: v1alpha1
group: management
kind: ExternalSecret
name: $ENVIRONMENT-webhooksite-auth
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
name: $ENVIRONMENT-webhooksite-auth
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  domain: "webhooksite-auth.$ENVIRONMENT.sandbox.ampc.axwaytest.net"
  secret:
    kind: ExternalSecret
    name: $ENVIRONMENT-webhooksite-auth
---
apiVersion: v1alpha1
group: management
kind: Deployment
name: webhooksite-auth
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  virtualAPIRelease: webhooksite-auth-1.0.0
  virtualHost: $ENVIRONMENT-webhooksite-auth
EOF

axway --env $PLATFORM_ENV central apply -f ./deployment.yaml

echo =========
echo = Test  =
echo =========
K8_INGRESS=$(kubectl describe -n kube-system service/traefik | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
echo curl -ki --resolve webhooksite-auth.$ENVIRONMENT.sandbox.ampc.axwaytest.net:8443:$K8_INGRESS https://webhooksite-auth.$ENVIRONMENT.sandbox.ampc.axwaytest.net:8443/hook/demo

cd $ORIG_DIR