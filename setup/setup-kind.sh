#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

case ${KUBE_VERSION} in
  1.20.0)
    IMAGE='kindest/node:v1.20.0'
    ;;
  1.19)
    IMAGE='kindest/node:v1.19.7'
    ;;
  1.19.7)
    IMAGE='kindest/node:v1.19.7'
    ;;
  1.19.1)
    IMAGE='kindest/node:v1.19.1'
    ;;
  1.18)
    IMAGE='kindest/node:v1.18.8'
    ;;
  1.18.8)
    IMAGE='kindest/node:v1.18.8'
    ;;
  1.17)
    IMAGE='kindest/node:v1.17.11'
    ;;
  1.17.11)
    IMAGE='kindest/node:v1.17.11'
    ;;
  1.16)
    IMAGE='kindest/node:v1.16.15'
    ;;
  1.16.15)
    IMAGE='kindest/node:v1.16.15'
    ;;
  1.15)
    IMAGE='kindest/node:v1.15.12'
    ;;
  1.15.12)
    IMAGE='kindest/node:v1.15.12'
    ;;
  *)
    echo -e "\n${BOLDRED}This script does not support Kubernetes version ${KUBE_VERSION} with Kind. Find the right image at ${CYAN}https://hub.docker.com/r/kindest/node${NOCOLOR} and add a branch for it in ${BOLDWHITE}setup-kind.sh${NOCOLOR}!${NOCOLOR}"
    exit 1
    ;;
esac

#todo make these idempotent so we don't need to delete the cluster
echo -e "\n${BOLDBLUE}Creating Kind cluster with K8s version ${KUBE_VERSION}...${NOCOLOR}"

kind create cluster --name k8ssandra --image "${IMAGE}" --config ${K8SSANDRA_DIR}/docs/content/en/docs/topics/ingress/traefik/kind-deployment/kind.config.yaml

echo -e "\n${BOLDGREEN}Cluster has been created.${NOCOLOR}\n"

kubectl cluster-info --context kind-k8ssandra
