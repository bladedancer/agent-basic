#!/bin/sh

export ENVIRONMENT=ocdemo
export ENVIRONMENT_TITLE="Minishift Env"

export PLATFORM_ENV=staging
export CENTRAL_AUTH_URL=https://login.axwaytest.net/auth
export CENTRAL_URL=https://gmatthews.dev.ampc.axwaytest.net
export CENTRAL_USAGEREPORTING_URL=https://lighthouse-staging.admin.staging.appctest.com
export CENTRAL_DEPLOYMENT=teams
export CENTRAL_PLATFORM_URL=https://platform.axwaytest.net
export TRACEABILITY_HOST=ingestion.condor.staging.axwaytest.net:5044
export TRACEABILITY_PROTOCOL=tcp
export TRACEABILITY_REDACTION_PATH_SHOW=[{keyMatch:".*"}]
export TRACEABILITY_REDACTION_QUERYARGUMENT_SHOW=[{keyMatch:".*"}]
export TRACEABILITY_REDACTION_REQUESTHEADER_SHOW=[{keyMatch:".*"}]
export TRACEABILITY_REDACTION_RESPONSEHEADER_SHOW=[{keyMatch:".*"}]

export AMGPW_NAMESPACE=ampgw

axway --env $PLATFORM_ENV auth login 

axway central config set --platform=$PLATFORM_ENV
axway central config set --baseUrl=$CENTRAL_URL
