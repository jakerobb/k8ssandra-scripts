#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

if [[ "$KUBE_ENV" == "k3d" ]]; then
  STORAGE_CLASS=local-path
else
  STORAGE_CLASS=standard
fi

cd ${K8SSANDRA_DIR}
echo -e "${BOLDBLUE}Value from values file ${zBLUE}${VALUES_FILE}${NOCOLOR}"
(
  set -x
  yq "$1" ${VALUES_FILE}
)

echo -e "\n${BOLDBLUE}Value from charts/k8ssandra/values.yaml${NOCOLOR}"
YAML=$(set -x; helm show values charts/k8ssandra)
yq "$1" <<< "${YAML}"

echo -e "\n${BOLDBLUE}Value currently deployed to Kubernetes:${NOCOLOR}"
set +e
JSON=$(set -x; helm -n ${NAMESPACE} get values -a ${RELEASE_NAME} -o json 2> /dev/null)
EXIT_CODE=$?
if [[ "${EXIT_CODE}" -eq 0 ]]; then
  jq "$1" <<< "${JSON}"
else
  echo -e "${DARKGRAY}No Kubernetes deployment is present or Kubernetes is not available.${NOCOLOR}"
fi
