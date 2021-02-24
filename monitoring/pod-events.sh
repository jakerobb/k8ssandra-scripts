#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

POD_NAME=$1

if [[ -z "${POD_NAME}" ]]; then
  echo -e "${BOLDRED}Usage: $0 [podName]${NOCOLOR}"
  echo -e "${BOLDCYAN}Pods in ${NAMESPACE}:${NOCOLOR}"
  kubectl get pods -n ${NAMESPACE}
  exit 1
fi

EVENTS=$(kubectl get event -n ${NAMESPACE} --field-selector involvedObject.name=${POD} 2>&1)
if [[ "${EVENTS}" != "No resources found in ${NAMESPACE} namespace." ]]; then
  echo -ne "\n${BOLDWHITE}"
  head -n 1 <<< "${EVENTS}"
  echo -ne "${NOCOLOR}"
  tail -n +2 <<< "${EVENTS}"
else
  echo -e "${MAGENTA}All events for this pod have expired.${NOCOLOR}"
fi
