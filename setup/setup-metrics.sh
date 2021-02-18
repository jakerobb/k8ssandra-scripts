#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Installing metrics servier...${NOCOLOR}"
kubectl apply -f conf/metrics-server.yaml

