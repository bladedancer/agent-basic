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
openssl req -x509 -newkey rsa:4096 -keyout listener_private_key.pem -nodes -out listener_certificate.pem -days 365 -subj '/CN=*.ampgw.com/O=Axway/C=IE'

echo =============================
echo === Creating AmpGw Secret ===
echo =============================
kubectl delete secret ampgw-secret -n ${AMGPW_NAMESPACE:-default}
kubectl create secret generic ampgw-secret \
    -n ${AMGPW_NAMESPACE:-default} \
    --from-file serviceAccPrivateKey=private_key.pem \
    --from-file serviceAccPublicKey=public_key.pem \
    --from-file listenerPrivateKey=listener_private_key.pem  \
    --from-file listenerCertificate=listener_certificate.pem \
    --from-literal orgId=$ORG_ID \
    --from-literal clientId=$CLIENT_ID

echo ================================
echo === Deleting Environment    ===
echo ================================
axway --env $PLATFORM_ENV central delete env $ENVIRONMENT -y



echo ============================
echo === Installing Dataplane ===
echo ============================
CREDS=$(cat ~/.docker/config.json | jq -r '.auths."axway.jfrog.io".auth' | base64 -d)
IFS=':'
read -a userpass <<< "$CREDS"
helm repo add --force-update ampc-rel https://axway.jfrog.io/artifactory/ampc-helm-release --username ${userpass[0]} --password ${userpass[1]}

helm repo add --force-update --insecure-skip-tls-verify ampc-snap https://artifactory-phx.ecd.axway.int/artifactory/ampc-helm-snapshot

cat << EOF > override.yaml
global:
  environment: $ENVIRONMENT
  environmentTitle: $ENVIRONMENT_TITLE
  listenerPort: 8443
  exposeProxyAdminPort: true
  proxyAdminPort: 9901

imagePullSecrets:
  - name: regcred
ampgw-secret-provider-k8s:
  imagePullSecrets:
  - name: regcred
ampgw-governance-agent:
  imagePullSecrets: 
    - name: regcred
  readinessProbe:
    timeoutSeconds: 5
  livenessProbe:
    timeoutSeconds: 5
  env:
    CENTRAL_AUTH_URL: $CENTRAL_AUTH_URL
    CENTRAL_URL: $CENTRAL_URL
    CENTRAL_USAGEREPORTING_URL: $CENTRAL_USAGEREPORTING_URL
    CENTRAL_DEPLOYMENT: $CENTRAL_DEPLOYMENT
    CENTRAL_PLATFORM_URL: $CENTRAL_PLATFORM_URL
    TRACEABILITY_HOST: $TRACEABILITY_HOST
    TRACEABILITY_PROTOCOL: $TRACEABILITY_PROTOCOL
    TRACEABILITY_REDACTION_PATH_SHOW: "$TRACEABILITY_REDACTION_PATH_SHOW"
    TRACEABILITY_REDACTION_QUERYARGUMENT_SHOW: "$TRACEABILITY_REDACTION_QUERYARGUMENT_SHOW"
    TRACEABILITY_REDACTION_REQUESTHEADER_SHOW: "$TRACEABILITY_REDACTION_REQUESTHEADER_SHOW"
    TRACEABILITY_REDACTION_RESPONSEHEADER_SHOW: "$TRACEABILITY_REDACTION_RESPONSEHEADER_SHOW"

provisioning:
  platformEnv: $PLATFORM_ENV
  centralUrl: $CENTRAL_URL

ampgw-proxy:
  imagePullSecrets:
    - name: regcred
EOF

helm delete ampgw -n ${AMGPW_NAMESPACE:-default} --wait
#helm install ampgw ampc-rel/ampgw -f override.yaml -n ${AMGPW_NAMESPACE:-default} --wait
helm install --insecure-skip-tls-verify ampgw ampc-snap/ampgw --version 0.9.0-POC-0016-obs-SNAPSHOT -f override.yaml -n ${AMGPW_NAMESPACE:-default} --wait

echo ============================
echo === Waiting for all Pods ===
echo ============================
kubectl -n ${AMGPW_NAMESPACE:-default} wait --timeout 10m --for=condition=Complete jobs --all

echo ============================
echo === Add Service Monitor  ===
echo ============================
kubectl apply -f prometheus/envoy-servicemonitor.yaml
kubectl apply -f prometheus/agent-servicemonitor.yaml