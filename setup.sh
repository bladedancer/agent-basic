#!/bin/sh

. ./env.sh
./setup-eks.sh
./setup-dns.sh
./setup-cluster.sh
./setup-prometheus.sh
./setup-ampgw.sh
./vapi-webhooksite/setup.sh
./vapi-nginx/setup.sh
