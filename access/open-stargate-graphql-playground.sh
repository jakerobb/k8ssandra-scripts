#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Ensuring Stargate is ready...${NOCOLOR}"
until kubectl wait --for=condition=available -n ${NAMESPACE} deployment ${RELEASE_NAME}-dc1-stargate &> /dev/null; do sleep 1; done

accessClusterResource "Stargate Playground" 8080 "/playground" "stargate" 8080 "${RELEASE_NAME}-stargate-service"
