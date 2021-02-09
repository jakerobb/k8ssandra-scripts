#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Ensuring dashboard is ready...${NOCOLOR}"
until kubectl wait --for=condition=ready -n kubernetes-dashboard pod -l k8s-app=kubernetes-dashboard &> /dev/null; do sleep 1; done

DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') | egrep '^token' | cut -d: -f2 | tr -d ' ')
DASHBOARD_URL="http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo -e "\n${BOLDWHITE}Dashboard URL:${NOCOLOR} ${DASHBOARD_URL}"
echo -e "\n${BOLDWHITE}  Login token:${NOCOLOR}"
echo "------------"
echo "${DASHBOARD_TOKEN}"
echo "------------"

echo -e "\n${BOLDBLUE}Copying token to clipboard...${NOCOLOR}"
pbcopy <<< "${DASHBOARD_TOKEN}"

kill $(cat dashboard-proxy.pid 2> /dev/null) || true

echo -e "\n${BOLDBLUE}Starting kubectl proxy...${NOCOLOR}"
kubectl proxy &
PROXY_PID=$!
echo "${PROXY_PID}" > dashboard-proxy.pid
sleep 0.5

if kill -0 ${PROXY_PID} &> /dev/null; then
  openUrl "${DASHBOARD_URL}"
  echo "When you're done, release the port using: kill ${PROXY_PID}"
else
  echo -e "${BOLDRED}Failed to create proxy.${NOCOLOR}"
fi
