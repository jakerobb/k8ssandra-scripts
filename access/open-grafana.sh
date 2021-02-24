#!/usr/bin/env bash
# This is a utility script for opening the Grafana dashboard for a k8ssandra cluster. It:
#  1. Ensures that Grafana is ready (note that there is no timeout; if you've made a mistake, this script will wait forever.)
#  2. Retrieves the username and password from the Kubernetes secret. (Make sure your kubectl is configured with sufficient access.)
#  3. Forwards a local port to the Grafana service in Kubernetes.
#  4. Launches your web browser (on Mac) or just tells you where to go.

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Waiting for Grafana to be ready...${NOCOLOR}"
until kubectl wait --for=condition=available -n ${NAMESPACE} deployment ${RELEASE_NAME}-grafana &> /dev/null; do sleep 1; echo -ne "${BOLDBLUE}.${NOCOLOR}"; done

GRAFANA_CREDS_JSON=$(kubectl get secret -n ${NAMESPACE} ${RELEASE_NAME}-grafana -o json)
GRAFANA_USER=$(jq -r '.data."admin-user"' <<< "${GRAFANA_CREDS_JSON}" | base64 -d)
GRAFANA_PASSWORD=$(jq -r '.data."admin-password"' <<< "${GRAFANA_CREDS_JSON}" | base64 -d)
echo -e "  ${BOLDWHITE}Grafana User:${NOCOLOR} ${GRAFANA_USER}"
echo -e "  ${BOLDWHITE}Grafana Password:${NOCOLOR} ${GRAFANA_PASSWORD}"

accessClusterResource "Grafana" 80 "/" "grafana" 3000 "${RELEASE_NAME}-grafana"

