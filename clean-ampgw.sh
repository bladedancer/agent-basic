#!/bin/bash

. ./env.sh

axway --env $PLATFORM_ENV central delete env $ENVIRONMENT -y

helm delete ampgw -n ${AMGPW_NAMESPACE:-default} --wait

if [ ! -z "${AMGPW_NAMESPACE}" ]; then
  kubectl delete namespace ${AMGPW_NAMESPACE}
fi

axway --env $PLATFORM_ENV service-account remove $ENVIRONMENT
