#!/bin/bash

. ./env.sh


echo ================================
echo === Create Namespace ${AMGPW_NAMESPACE:-default}
echo ================================
if [ ! -z "${AMGPW_NAMESPACE}" ]; then
  kubectl create namespace ${AMGPW_NAMESPACE}
fi

echo ================================
echo === Creating Service Account ===
echo ================================

openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in private_key.pem -out public_key.pem -outform pem
axway --env $PLATFORM_ENV service-account remove $ENVIRONMENT
ACC=$(axway --env $PLATFORM_ENV service-account create --name $ENVIRONMENT --public-key ./public_key.pem --json --role api_central_admin)
CLIENT_ID=$(echo $ACC | jq -r .client.client_id)
ORG_ID=$(echo $ACC | jq -r .org.id)

echo ==============================
echo === Creating Listener Cert ===
echo ==============================
openssl req -x509 -newkey rsa:4096 -keyout $ENVIRONMENT-listener-private-key.pem -nodes -out $ENVIRONMENT-listener-certificate.pem -days 365 -subj '/CN=*.ampgw.com/O=Axway/C=IE'

echo =============================
echo === Creating AmpGw Secret ===
echo =============================
kubectl delete secret ampgw-secret -n ${AMGPW_NAMESPACE:-default}
kubectl create secret generic ampgw-secret \
    -n ${AMGPW_NAMESPACE:-default} \
    --from-file serviceAccPrivateKey=private_key.pem \
    --from-file serviceAccPublicKey=public_key.pem \
    --from-file listenerPrivateKey=$ENVIRONMENT-listener-private-key.pem  \
    --from-file listenerCertificate=$ENVIRONMENT-listener-certificate.pem \
    --from-literal orgId=$ORG_ID \
    --from-literal clientId=$CLIENT_ID

echo ================================
echo === Deleting Environment    ===
echo ================================
axway --env $PLATFORM_ENV central delete env $ENVIRONMENT -y

echo ============================
echo === Installing Dataplane ===
echo ============================
cat << EOF > override.yaml
global:
  environment: $ENVIRONMENT
  environmentTitle: $ENVIRONMENT_TITLE
  listenerPort: 8443
  exposeProxyAdminPort: true
  proxyAdminPort: 9901
  tlsExternalSecretName: ampgw-secret

ampgw-traceability-agent:
  env:
    CENTRAL_AUTH_URL: $CENTRAL_AUTH_URL
    CENTRAL_URL: $CENTRAL_URL
    CENTRAL_DEPLOYMENT: $CENTRAL_DEPLOYMENT
    CENTRAL_PLATFORM_URL: $CENTRAL_PLATFORM_URL
    CENTRAL_USAGEREPORTING_URL: $CENTRAL_USAGEREPORTING_URL
    TRACEABILITY_HOST: $TRACEABILITY_HOST
    TRACEABILITY_PROTOCOL: $TRACEABILITY_PROTOCOL
    TRACEABILITY_REDACTION_PATH_SHOW: "$TRACEABILITY_REDACTION_PATH_SHOW"
    TRACEABILITY_REDACTION_QUERYARGUMENT_SHOW: "$TRACEABILITY_REDACTION_QUERYARGUMENT_SHOW"
    TRACEABILITY_REDACTION_REQUESTHEADER_SHOW: "$TRACEABILITY_REDACTION_REQUESTHEADER_SHOW"
    TRACEABILITY_REDACTION_RESPONSEHEADER_SHOW: "$TRACEABILITY_REDACTION_RESPONSEHEADER_SHOW"

ampgw-governance-agent:
  readinessProbe:
    timeoutSeconds: 5
  livenessProbe:
    timeoutSeconds: 5
  env:
    CENTRAL_AUTH_URL: $CENTRAL_AUTH_URL
    CENTRAL_URL: $CENTRAL_URL
    CENTRAL_DEPLOYMENT: $CENTRAL_DEPLOYMENT
    CENTRAL_PLATFORM_URL: $CENTRAL_PLATFORM_URL


provisioning:
  platformEnv: $PLATFORM_ENV
  centralUrl: $CENTRAL_URL

ampgw-proxy:
  image:
    repository: envoyproxy/envoy-distroless
    tag: v1.21-latest
    pullPolicy: Always
EOF

helm delete ampgw -n ${AMGPW_NAMESPACE:-default} --wait
helm install ampgw axway-repo/amplifygateway-helm-prod-ampgw -f override.yaml -n ${AMGPW_NAMESPACE:-default} --wait

echo ============================
echo === Waiting for all Pods ===
echo ============================
kubectl -n ${AMGPW_NAMESPACE:-default} wait --timeout 10m --for=condition=Complete jobs --all

