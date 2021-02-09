#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Adding Helm repos...${NOCOLOR}"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

