#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Installing Traefik...${NOCOLOR}"

helm install traefik traefik/traefik -n traefik --create-namespace -f ${K8SSANDRA_DIR}/docs/content/en/docs/topics/ingress/traefik/kind-deployment/traefik.values.yaml

echo -e "\n${BOLDBLUE}Waiting for CRDs to load...${NOCOLOR}"

until kubectl -n default wait --for condition=established --timeout=60s crd/traefikservices.traefik.containo.us &> /dev/null; do sleep 1; done

echo -e "\n${BOLDGREEN}Traefik has been installed.${NOCOLOR}\n"
echo -e "\n${BOLDGREEN}Traefik dashboard is available at:${NOCOLOR} http://localhost:9000/dashboard/\n"

