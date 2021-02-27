#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source common.sh

echo -e "${BOLDBLUE}Setting up K8ssandra cluster...${NOCOLOR}"
printContextWithValues

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
setup/setup-metrics.sh
setup/setup-dashboard.sh

if [[ "${INSTALL_TRAEFIK}" == "true" ]]; then
  setup/setup-traefik.sh
fi

setup/setup-k8ssandra.sh
utils/wait-for-ready.sh
utils/get-credentials.sh

