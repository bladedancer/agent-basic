#!/bin/bash

. ./env.sh

echo ===============
echo = Prometheus  =
echo ===============

helm -n prometheus uninstall prometheus
helm repo add --force-update prometheus-community https://prometheus-community.github.io/helm-charts
kubectl create namespace prometheus
helm install prometheus -n prometheus prometheus-community/kube-prometheus-stack \
--set alertmanager.enabled=false \
--set grafana.service.type=LoadBalancer \
--set grafana.service.port=3000 \
--set grafana.adminPassword=password \
--set prometheus.service.type=LoadBalancer \
--set prometheus.service.port=9090

PROM_INGRESS=$(kubectl describe -n prometheus service/prometheus-kube-prometheus-prometheus | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
GRAF_INGRESS=$(kubectl describe -n prometheus service/prometheus-grafana | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
curl -X POST -H "Content-Type: application/json" -d @./grafana/envoy-dashboard.json http://$GRAF_INGRESS:3000/api/dashboards/import -u admin:password

echo ============
echo = Connect  =
echo ============
echo "Grafana http://$GRAF_INGRESS:3000 (admin/password)"
echo "Prometheus http://$PROM_INGRESS:9090"

