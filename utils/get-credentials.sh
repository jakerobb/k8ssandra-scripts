#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Determining credentials...${NOCOLOR}"

SECRET=$(kubectl get secret "${CLUSTERNAME}-superuser" -n ${NAMESPACE} -o=jsonpath='{.data}')
echo -e "${CYAN}Username:${NOCOLOR} $(jq -r '.username' <<< "$SECRET" | base64 -d)"
echo -e "${CYAN}Password:${NOCOLOR} $(jq -r '.password' <<< "$SECRET" | base64 -d)"
