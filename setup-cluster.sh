#!/bin/bash

. ./env.sh

kubectl cluster-info

echo ================================
echo === Create Namespace ${AMGPW_NAMESPACE:-default}
echo ================================
if [ ! -z "${AMGPW_NAMESPACE}" ]; then
  kubectl create namespace ${AMGPW_NAMESPACE}
fi

echo ===============================
echo === Configure docker secret ===
echo ===============================
axway --env $PLATFORM_ENV service-account remove --name ${ENVIRONMENT}_repo
SECRET=$(echo $RANDOM | md5sum | head -c 20)
REPO_ACC=$(axway --env $PLATFORM_ENV service-account create --name ${ENVIRONMENT}_repo --secret $SECRET --json --role api_central_admin)
CLIENT_ID=$(echo $REPO_ACC | jq -r .client.client_id)

kubectl delete secret -n ${AMGPW_NAMESPACE:-default} docker-registry-credentials
kubectl create secret -n ${AMGPW_NAMESPACE:-default} docker-registry docker-registry-credentials --docker-server=docker.repository.axway.com --docker-username=$CLIENT_ID --docker-password=$SECRET

# TEMP
kubectl delete secret -n ${AMGPW_NAMESPACE:-default} regcred
kubectl create secret -n ${AMGPW_NAMESPACE:-default} docker-registry regcred --docker-server=docker.repository.axway.com --docker-username=$CLIENT_ID --docker-password=$SECRET

echo ================================
echo === Configure axay helm repo ===
echo ================================
helm repo add axway-repo https://helm.repository.axway.com --username=$CLIENT_ID --password=$SECRET --force-update 