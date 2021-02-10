#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source common.sh

echo -e "${BOLDBLUE}Setting up K8ssandra cluster...${NOCOLOR}"
echo -e "${BOLDCYAN}K8ssandra directory: ${CYAN}${K8SSANDRA_DIR}${NOCOLOR}"
echo -e "${BOLDCYAN}Git branch: ${CYAN}$(cd ${K8SSANDRA_DIR}; git branch --show-current 2>&1)${NOCOLOR}"
echo ""
echo -e "${BOLDCYAN}NAMESPACE: ${CYAN}${NAMESPACE}${NOCOLOR}"
echo -e "${BOLDCYAN}CLUSTERNAME: ${CYAN}${CLUSTERNAME}${NOCOLOR}"
echo -e "${BOLDCYAN}RELEASENAME: ${CYAN}${RELEASENAME}${NOCOLOR}"
echo -e "${BOLDCYAN}KUBE_ENV: ${CYAN}${KUBE_ENV}${NOCOLOR}"
echo -e "${BOLDCYAN}Values:${NOCOLOR}"
yq '.' ${VALUES_FILE}

setup/setup-helm.sh
if [[ "${KUBE_ENV}" == "k3d" ]]; then
  teardown/teardown-kind.sh
  setup/setup-k3d.sh
else
  teardown/teardown-k3d.sh
  setup/setup-kind.sh
fi
setup/setup-dashboard.sh

TRAEFIK_ENABLED="$(getValueFromChartOrValuesFile '.ingress.traefik.enabled')"
if [[ "${TRAEFIK_ENABLED}" == "true" ]]; then
  setup/setup-traefik.sh
fi

setup/setup-k8ssandra.sh
utils/wait-for-ready.sh
utils/get-credentials.sh

