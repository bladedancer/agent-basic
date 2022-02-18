#!/bin/sh

. ./env.sh
./setup-cluster.sh
./setup-prometheus.sh
./setup-ampgw.sh
./setup-vapi.sh
