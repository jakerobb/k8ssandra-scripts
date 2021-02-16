#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source common.sh

echo -e "${BOLDBLUE}Setting up K8ssandra cluster...${NOCOLOR}"
printContext

setup/setup-helm.sh
if [[ "${KUBE_ENV}" == "k3d" ]]; then
  teardown/teardown-kind.sh
  teardown/teardown-k3d.sh
  setup/setup-k3d.sh
else
  teardown/teardown-kind.sh
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

