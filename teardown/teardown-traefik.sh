#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Tearing down Traefik...${NOCOLOR}"
set -x
helm uninstall traefik -n traefik
