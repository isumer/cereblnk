#!/usr/bin/env bash
set -euo pipefail
docker build -t acme/orders:"$1" .
kubectl rollout status deploy/orders
terraform apply -auto-approve
systemctl restart orders.service
curl -s http://prometheus:9090/-/healthy >/dev/null
