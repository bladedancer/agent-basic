#!/bin/sh

. ./env.sh
./setup-cluster.sh
./setup-ampgw.sh
./vapi-nginx/setup.sh
