#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Ensuring Reaper is ready...${NOCOLOR}"
until kubectl wait --for=condition=available -n ${NAMESPACE} deployment ${RELEASE_NAME}-reaper-k8ssandra &> /dev/null; do sleep 1; done

accessClusterResource "Reaper" 8080 "/webui" "reaper" 4000 "${RELEASE_NAME}-reaper-k8ssandra-reaper-service"
