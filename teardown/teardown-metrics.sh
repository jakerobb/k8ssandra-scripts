#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Tearing down metrics server...${NOCOLOR}"
kubectl delete -f conf/metrics-server.yaml

