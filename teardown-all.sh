#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Tearing down...${NOCOLOR}"
echo -e "${BOLDCYAN}NAMESPACE: ${CYAN}${NAMESPACE}${NOCOLOR}"
echo -e "${BOLDCYAN}RELEASENAME: ${CYAN}${RELEASENAME}${NOCOLOR}"
echo -e "${BOLDCYAN}KUBEENV: ${CYAN}${KUBEENV}${NOCOLOR}"

if [[ "$1" == "-p" ]]; then
  teardown/teardown-k8ssandra.sh
  teardown/teardown-traefik.sh
  teardown/teardown-dashboard.sh
fi

if [[ "$KUBEENV" == "k3d" ]]; then
  teardown/teardown-k3d.sh
else
  teardown/teardown-kind.sh
fi
