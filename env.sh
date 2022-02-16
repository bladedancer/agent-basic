#!/bin/bash

script_dir=$(dirname ${BASH_SOURCE})

if [ "$ENV" = "preprod" ]; then
 . $script_dir/env-preprod.sh
else
 . $script_dir/env-prod.sh
fi