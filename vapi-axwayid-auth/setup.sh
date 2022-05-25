#!/bin/bash

ORIG_DIR=$CWD
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $ROOTDIR/..
. ./env.sh
cd $ROOTDIR

VAPI=webhooksite-axwayid
APP=gmapp

axway --env $PLATFORM_ENV central delete accessrequest $APP -s $ENVIRONMENT -y
axway --env $PLATFORM_ENV central delete deployment $VAPI -s $ENVIRONMENT -y
sleep 20
axway --env $PLATFORM_ENV central delete virtualapi $VAPI -y
sleep 20

echo ================================
echo === Creating Service Account ===
echo ================================
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in private_key.pem -out public_key.pem -outform pem
axway --env $PLATFORM_ENV service-account remove $ENVIRONMENT-$APP
ACC=$(axway --env $PLATFORM_ENV service-account create --name $ENVIRONMENT-$APP --public-key ./public_key.pem --json --role api_central_admin)
CLIENT_ID=$(echo $ACC | jq -r .client.client_id)
echo "CLIENT_ID: ${CLIENT_ID}"

axway --env $PLATFORM_ENV central apply -f ./vapi.yaml
axway --env $PLATFORM_ENV central apply -f ./releasetag.yaml
sleep 30

kubectl delete secret generic webhooksite-axwayid-secret-axwayid -n ${AMGPW_NAMESPACE:-default}
kubectl create secret generic webhooksite-axwayid-secret-axwayid -n ${AMGPW_NAMESPACE:-default} --from-literal key=SuperSecretKey

cat << EOF > ./deployment.yaml
apiVersion: v1alpha1
group: management
kind: ExternalSecret
name: $ENVIRONMENT-$VAPI
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
name: $ENVIRONMENT-$VAPI
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  domain: "$VAPI.$ENVIRONMENT.sandbox.ampc.axwaytest.net"
  secret:
    kind: ExternalSecret
    name: $ENVIRONMENT-$VAPI
---
apiVersion: v1alpha1
group: management
kind: Deployment
name: $VAPI
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
tags:
  - v1
spec:
  virtualAPIRelease: $VAPI-1.0.0
  virtualHost: $ENVIRONMENT-$VAPI
EOF

axway --env $PLATFORM_ENV central apply -f ./deployment.yaml


cat << EOF > ./accessrequest.yaml
group: management
apiVersion: v1alpha1
kind: ManagedApplication
name: $APP
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
spec: {}
---
group: management
apiVersion: v1alpha1
kind: AccessRequest
name: $APP
metadata:
  scope:
    kind: Environment
    name: $ENVIRONMENT
spec:
  apiServiceInstance: $VAPI-ins
  managedApplication: $APP
  data:
    apiId: "$VAPI"
    subscriptionId: "$APP"
    clientType: "JWT"
    clientId: $CLIENT_ID
EOF

axway --env $PLATFORM_ENV central apply -f ./accessrequest.yaml

echo =========
echo = Test  =
echo =========
TOKEN=$(axway auth login --client-id  $CLIENT_ID --secret-file  private_key.pem --json | jq -r .auth.tokens.access_token)


K8_INGRESS=$(kubectl describe -n kube-system service/traefik | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
echo curl -ki --resolve $VAPI.$ENVIRONMENT.sandbox.ampc.axwaytest.net:8443:$K8_INGRESS -H \"Authorization: Bearer $TOKEN\" https://$VAPI.$ENVIRONMENT.sandbox.ampc.axwaytest.net:8443/hook/demo

cd $ORIG_DIR