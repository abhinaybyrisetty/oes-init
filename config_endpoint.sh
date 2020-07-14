#!/bin/bash -x

if [ $# -gt 1 ]
then
   echo "Invalid input, only one argument expected"
   exit
fi

COMPONENT=$1

case "$COMPONENT" in

  oes-ui)
    cp /config/* /var/www/html/assets/config/
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
    cp /config/* /opt/spinnaker/config/
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
    cp /config/* /opt/opsmx/
    sleep $EXTERNAL_IP_CHECK_DELAY
    ## If loadbalancer is available on the target, below instruction will fetch external IP of oes-ui
    ENDPOINT_IP=$(kubectl get svc spin-deck -o jsonpath="{.status.loadBalancer.ingress[].ip}")
    PORT=9000

    ## If spin-deck load balancer is separate
    if [ -z "$ENDPOINT_IP" ]; then
      ENDPOINT_IP=$(kubectl get svc spin-deck-ui -o jsonpath="{.status.loadBalancer.ingress[].ip}")
      PORT=9000
    fi

    ## If external IP is not available
    if [ -z "$ENDPOINT_IP" ]; then
      ## Fetch the IP of the host and replace in spinnaker.yaml
      ENDPOINT_IP=$(kubectl get ep kubernetes -n default -o jsonpath="{.subsets[].addresses[].ip}")
      PORT=$(kubectl get svc spin-gate -o jsonpath="{.spec.ports[].nodePort}")
      sed -i "s/SPIN_GATE_LOADBALANCER_IP_PORT/$ENDPOINT_IP:$PORT/g" /opt/opsmx/spinnaker.yaml
      #sed -i "s/spin-gate:8084/$ENDPOINT_IP:$PORT/g" /opt/opsmx/spinnaker.yaml
    else
      ## Substitute oes-ui external IP in spinnaker.yaml
      sed -i "s/SPIN_GATE_LOADBALANCER_IP_PORT/$ENDPOINT_IP:$PORT/g" /opt/opsmx/spinnaker.yaml
    fi
    ;;
  *)
    echo "Invalid input"
    ;;

esac
