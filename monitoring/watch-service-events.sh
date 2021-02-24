#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

SERVICE_NAME=$1

if [[ -z "${SERVICE_NAME}" ]]; then
  echo -e "${BOLDRED}Usage: $(basename "$0") [serviceName]${NOCOLOR}"
  echo -e "${BOLDCYAN}Services in ${NAMESPACE}:${NOCOLOR}"
  kubectl get service -n ${NAMESPACE}
  exit 1
fi

watch -cd service-pod-events.sh ${COLORMODE} ${SERVICE_NAME}
