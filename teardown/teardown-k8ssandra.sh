#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Tearing down K8ssandra installation...${NOCOLOR}"
set -x
helm uninstall ${RELEASENAME} -n ${NAMESPACE}
