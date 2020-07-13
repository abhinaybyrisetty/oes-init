#!/bin/bash

if [ $# -gt 1 ]
then
   echo "Invalid input, only one argument expected"
   exit
fi

COMPONENT=$1

case "$COMPONENT" in

  oes-ui)
    cp /config/app-config.json /var/www/html/assets/config/app-config.json
    sleep $EXTERNAL_IP_CHECK_DELAY
    ## If loadbalancer is available on the target, below instruction will fetch external IP of oes-gate
    ENDPOINT_IP=$(kubectl get svc oes-gate-svc -o jsonpath="{.status.loadBalancer.ingress[].ip}")

    ## If external IP is not available
    if [ -z "$ENDPOINT_IP" ]; then
      ## Fetch the IP of the host & nodeport and replace in app-config.js
      ENDPOINT_IP=$(kubectl get ep kubernetes -n default -o jsonpath="{.subsets[].addresses[].ip}")
      PORT=$(kubectl get svc oes-gate-svc -o jsonpath="{.spec.ports[].nodePort}")
      sed -i "s/OES_GATE_IP/$ENDPOINT_IP/g" /var/www/html/assets/config/app-config.json
      sed -i "s/8084/$PORT/g" /var/www/html/assets/config/app-config.json
    else
      ## Substitute oes-gate external IP in app-config.js
      sed -i "s/OES_GATE_IP/$ENDPOINT_IP/g" /var/www/html/assets/config/app-config.json
    fi
    ;;
  oes-gate)
    cp /config/gate.yml /opt/spinnaker/config/gate.yml
    sleep $EXTERNAL_IP_CHECK_DELAY
    ## If loadbalancer is available on the target, below instruction will fetch external IP of oes-ui
    ENDPOINT_IP=$(kubectl get svc oes-ui-svc -o jsonpath="{.status.loadBalancer.ingress[].ip}")

    ## If external IP is not available
    if [ -z "$ENDPOINT_IP" ]; then
      ## Fetch the IP of the host and replace in gate.yml
      ENDPOINT_IP=$(kubectl get ep kubernetes -n default -o jsonpath="{.subsets[].addresses[].ip}")
      sed -i "s/OES_UI_LOADBALANCER_IP/$ENDPOINT_IP/g" /opt/spinnaker/config/gate.yml
    else
      ## Substitute oes-ui external IP in gate.yml
      sed -i "s/OES_UI_LOADBALANCER_IP/$ENDPOINT_IP/g" /opt/spinnaker/config/gate.yml
    fi
    ;;
  sapor)
    echo "Entered SAPOR"
    ;;
  *)
    echo "Invalid input"
    ;;

esac
