#!/bin/bash

if [ "$ENV" = "preprod" ]; then
 . ./env-preprod.sh
else
 . ./env-prod.sh
fi