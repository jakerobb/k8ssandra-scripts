#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Ensuring Traefik is ready...${NOCOLOR}"
until kubectl wait --for=condition=available -n traefik deployment traefik &> /dev/null; do sleep 1; done

openUrl "http://localhost:9000/dashboard/"
