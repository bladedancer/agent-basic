#!/bin/bash

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

if [ "$ENV" = "preprod" ]; then
 . $script_dir/env-preprod.sh
else
 . $script_dir/env-prod.sh
fi