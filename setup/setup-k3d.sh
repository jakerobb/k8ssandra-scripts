#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

case ${KUBE_VERSION} in
  1.20.0)
    IMAGE='rancher/k3s:v1.20.0-k3s1'
    ;;
  1.19.1)
    IMAGE='rancher/k3s:v1.19.1-k3s1'
    ;;
  1.18.8)
    IMAGE='rancher/k3s:v1.18.8-k3s1'
    ;;
  1.17.11)
    IMAGE='rancher/k3s:v1.17.1-k3s11'
    ;;
  1.16.15)
    IMAGE='rancher/k3s:v1.16.1-k3s15'
    ;;
  1.15.12)
    IMAGE='rancher/k3s:v1.15.1-k3s12'
    ;;
  *)
    echo -e "\n${BOLDRED}This script does not support Kubernetes version ${KUBE_VERSION} with K3d.${NOCOLOR}"
    exit 1
    ;;
esac

#todo make these idempotent so we don't need to delete the cluster
echo -e "\n${BOLDBLUE}Creating K3d cluster with K8s version ${KUBE_VERSION}...${NOCOLOR}"

k3d cluster create \
  --agents 3 \
  --image "${IMAGE}" \
  --k3s-server-arg "--no-deploy" \
  --k3s-server-arg "traefik" \
  --port "80:32080@loadbalancer" \
  --port "443:32443@loadbalancer" \
  --port "9000:32090@loadbalancer" \
  --port "9042:32091@loadbalancer" \
  --port "9142:32092@loadbalancer" \
  --port "8080:30080@loadbalancer" \
  --port "8081:30081@loadbalancer" \
  --port "8082:30082@loadbalancer" \
  --port "8084:30084@loadbalancer" \
  --port "8085:30085@loadbalancer"

echo -e "\n${BOLDGREEN}Cluster has been created.${NOCOLOR}\n"

kubectl cluster-info
