#!/bin/bash

. ./env.sh

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

K8_INGRESS=$(kubectl describe -n kube-system service/traefik | grep "LoadBalancer Ingress" | awk "{print \$3}" | sed "s/,//")
curl -X POST -H "Content-Type: application/json" -d @./grafanaenvoy-dashboard.json http://$K8_INGRESS/api/dashboards/db -u admin:password

echo ============
echo = Connect  =
echo ============
echo "Grafana http://$K8_INGRESS:3000 (admin/password)"
echo "Prometheus http://$K8_INGRESS:9090"

