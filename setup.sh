#!/bin/sh

. ./env.sh
./setup-eks.sh
./setup-dns.sh
./setup-cluster.sh
./setup-prometheus.sh
./setup-ampgw.sh
./webhooksite/setup.sh
./nginx/setup.sh
