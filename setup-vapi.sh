#!/bin/bash

. ./env.sh

axway --env $PLATFORM_ENV central delete deployment webhooksite -s $ENVIRONMENT -y
sleep 10
axway --env $PLATFORM_ENV central delete virtualapi webhooksite -y
sleep 10

axway --env $PLATFORM_ENV central apply -f vapi/vapi.yaml
axway --env $PLATFORM_ENV central apply -f vapi/releasetag.yaml
sleep 20

cat << EOF > vapi/deployment.yaml
apiVersion: v1alpha1
group: management
kind: VirtualHost
name: $ENVIRONMENT
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  domain: "$ENVIRONMENT.ampgw.com"
  secret:
    kind: Secret
    name: ampgw-tls
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
  virtualHost: $ENVIRONMENT
EOF

axway --env $PLATFORM_ENV central apply -f vapi/deployment.yaml

echo =========
echo = Test  =
echo =========
K8_INGRESS=$(kubectl describe -n kube-system service/traefik | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
echo curl -kv --resolve $ENVIRONMENT.ampgw.com:8443:$K8_INGRESS https://$ENVIRONMENT.ampgw.com:8443/hook/demo
