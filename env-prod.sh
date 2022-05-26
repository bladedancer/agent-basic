#!/bin/sh

export ENVIRONMENT=ocdemo
export ENVIRONMENT_TITLE="Minishift Env"

export PLATFORM_ENV=prod
export CENTRAL_AUTH_URL=https://login.axway.com/auth
export CENTRAL_URL=https://apicentral.axway.com
export CENTRAL_USAGEREPORTING_URL=https://lighthouse.admin.axway.com
export CENTRAL_DEPLOYMENT=prod
export CENTRAL_PLATFORM_URL=https://platform.axway.com
export TRACEABILITY_HOST=ingestion.datasearch.axway.com:5044
export TRACEABILITY_PROTOCOL=tcp
export TRACEABILITY_REDACTION_PATH_SHOW=[{keyMatch:".*"}]
export TRACEABILITY_REDACTION_QUERYARGUMENT_SHOW=[{keyMatch:".*"}]
export TRACEABILITY_REDACTION_REQUESTHEADER_SHOW=[{keyMatch:".*"}]
export TRACEABILITY_REDACTION_RESPONSEHEADER_SHOW=[{keyMatch:".*"}]

export AMGPW_NAMESPACE=ampgw

axway --env $PLATFORM_ENV auth login 

axway central config set --platform=$PLATFORM_ENV
axway central config set --baseUrl=$CENTRAL_URL
