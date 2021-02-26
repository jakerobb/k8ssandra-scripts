#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Ensuring dashboard is ready...${NOCOLOR}"
until kubectl wait --for=condition=ready -n kubernetes-dashboard pod -l k8s-app=kubernetes-dashboard &> /dev/null; do sleep 1; done

DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get secret | grep dashboard-user | awk '{print $1}') -o json | jq -r '.data.token' | base64 -d)

if [[ "$EUID" -eq 0 ]]; then
  DASHBOARD_PORT=80
  DASHBOARD_PORT_SUFFIX=""
else
  DASHBOARD_PORT=8001
  DASHBOARD_PORT_SUFFIX=":${DASHBOARD_PORT}"
fi

DASHBOARD_URL="http://localhost${DASHBOARD_PORT_SUFFIX}/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo -e "\n${BOLDWHITE}Dashboard URL:${NOCOLOR} ${DASHBOARD_URL}"
echo -e "\n${BOLDWHITE}  Login token:${NOCOLOR}"
echo "------------"
echo "${DASHBOARD_TOKEN}"
echo "------------"

if command -v pbcopy &> /dev/null; then
  echo -e "\n${BOLDBLUE}Copying token to clipboard...${NOCOLOR}"
  pbcopy <<< "${DASHBOARD_TOKEN}"
fi

kill $(cat dashboard-proxy.pid 2> /dev/null) || true

echo -e "\n${BOLDBLUE}Starting kubectl proxy...${NOCOLOR}"
kubectl proxy -p "${DASHBOARD_PORT}" &
PROXY_PID=$!
echo "${PROXY_PID}" > dashboard-proxy.pid
sleep 0.5

if kill -0 ${PROXY_PID} &> /dev/null; then
  openUrl "${DASHBOARD_URL}"
  echo "When you're done, release the port using: kill ${PROXY_PID}"
else
  echo -e "${BOLDRED}Failed to create proxy.${NOCOLOR}"
fi
