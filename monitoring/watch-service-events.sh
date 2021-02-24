#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

SERVICE_NAME=$1

set +e
if [[ -z "${SERVICE_NAME}" ]]; then
  echo -e "${BOLDCYAN}Services in ${NAMESPACE}:${NOCOLOR}"
  kubectl get service -n ${NAMESPACE}

  SERVICE_NAME="${RELEASE_NAME}-${DATACENTER}-service"
  echo -e "\n${BOLDCYAN}Defaulting to ${SERVICE_NAME}...${NOCOLOR}"
fi

watch -cd service-pod-events.sh ${COLORMODE} ${SERVICE_NAME}
