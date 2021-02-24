#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

SERVICE_NAME=$1

if [[ -z "${SERVICE_NAME}" ]]; then
  echo -e "${BOLDRED}Usage: $0 [serviceName]${NOCOLOR}"
  echo -e "${BOLDCYAN}Services in ${NAMESPACE}:${NOCOLOR}"
  kubectl get service -n ${NAMESPACE}
  exit 1
fi

set +e
SERVICE_JSON=$(kubectl get service -n ${NAMESPACE} "${SERVICE_NAME}" -o json 2> /dev/null)
KUBECTL_EXIT_CODE=$?
if [[ "${KUBECTL_EXIT_CODE}" -ne 0 ]]; then
  echo -e "${BOLDRED}Service ${SERVICE_NAME} does not exist. (kubectl exit code ${KUBECTL_EXIT_CODE})${NOCOLOR}"
  exit 1
fi

SELECTOR=$(jq -r '.spec.selector | to_entries[] | [.key, .value] | join("=")' 2> /dev/null <<< "${SERVICE_JSON}")
JQ_EXIT_CODE=$?
if [[ "${JQ_EXIT_CODE}" -ne 0 ]]; then
  echo -e "${BOLDRED}Service ${SERVICE_NAME} does not have a selector and is therefore not supported by this script. (jq exit code ${JQ_EXIT_CODE})${NOCOLOR}"
  exit 1
fi
PODS=$(sed 's|^|--selector=|' <<< "${SELECTOR}" | xargs kubectl -n ${NAMESPACE} get pods -o=json | jq -r '.items | sort_by(.metadata.creationTimestamp) | .[].metadata.name')

if [[ -n "${PODS}" ]]; then
  while IFS= read -r POD ; do
    echo -e "${BOLDCYAN}${POD}${NOCOLOR}"
    POD_JSON=$(kubectl get pod -n ${NAMESPACE} ${POD} -o json)
    CREATION_TIMESTAMP=$(jq -r '.metadata.creationTimestamp' <<< "${POD_JSON}")
    echo -e "${BOLDBLUE}Created: ${NOCOLOR}$(date -jf "%s" $(date -juf "%Y-%m-%dT%H:%M:%SZ" "${CREATION_TIMESTAMP}" +%s) "+%A, %d %h %Y at %l:%M:%S %p" | sed 's/  / /g')"
    jq -r '.status.conditions[] | {type: .type, status: .status} | join(": ")' <<< "${POD_JSON}" | sed -E "s|^([^:]*): (True)?(False)?(.*)$|${BOLDBLUE}\1: ${BOLDGREEN}\2${BOLDRED}\3${YELLOW}\4${NOCOLOR}|g"
    pod-events.sh "${COLORMODE}" "${POD}"
    echo
  done <<< "${PODS}"
else
  echo -e "${MAGENTA}No matching pods.${NOCOLOR}\n"
fi
