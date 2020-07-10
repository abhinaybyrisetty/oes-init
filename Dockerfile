FROM bitnami/kubectl:1.18.5
ADD config_endpoint.sh /home/
ENTRYPOINT ["/bin/bash", "/home/config_endpoint.sh"]
