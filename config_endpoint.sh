#!/bin/bash

cp /config/app-config.json /var/www/html/assets/config/app-config.json

sleep $EXTERNAL_IP_CHECK_DELAY

## If loadbalancer is available on the target, below instruction will fetch external IP of oes-gate
ENDPOINT_IP=$(kubectl get svc oes-gate-svc -o jsonpath="{.status.loadBalancer.ingress[].ip}")

## If external IP is not available
if [ -z "$ENDPOINT_IP" ]; then
  ## Fetch the IP of the host & nodeport and replace in app-config.js
  ENDPOINT_IP=$(kubectl config view --minify -o jsonpath="{.clusters[].cluster.server}" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  PORT=$(kubectl get svc oes-gate-svc -o jsonpath="{.spec.ports[].nodePort}")
  sed -i "s/oes-gate-svc/$ENDPOINT_IP/g" /var/www/html/assets/config/app-config.json
  sed -i "s/8084/$PORT/g" /var/www/html/assets/config/app-config.json
else
  ## Substitute oes-gate external IP in app-config.js
  sed -i "s/oes-gate-svc/$ENDPOINT_IP/g" /var/www/html/assets/config/app-config.json
fi
