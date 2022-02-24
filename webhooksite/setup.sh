#!/bin/bash

ORIG_DIR=$CWD
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $ROOTDIR/..
. ./env.sh
cd $ROOTDIR

axway --env $PLATFORM_ENV central delete deployment webhooksite -s $ENVIRONMENT -y
sleep 10
axway --env $PLATFORM_ENV central delete virtualapi webhooksite -y
sleep 10

axway --env $PLATFORM_ENV central apply -f ./vapi.yaml
axway --env $PLATFORM_ENV central apply -f ./releasetag.yaml
sleep 20

cat << EOF > ./deployment.yaml
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
  domain: "webhook.$ENVIRONMENT.sandbox.ampc.axwaytest.net"
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

axway --env $PLATFORM_ENV central apply -f ./deployment.yaml

echo =========
echo = Test  =
echo =========
echo curl -i https://webhook.$ENVIRONMENT.sandbox.ampc.axwaytest.net/hook/demo

cd $ORIG_DIR