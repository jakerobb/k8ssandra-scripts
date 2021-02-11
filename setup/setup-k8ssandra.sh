#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Installing K8ssandra...${NOCOLOR}"

if [[ "$KUBE_ENV" == "k3d" ]]; then
  STORAGE_CLASS=local-path
else
  STORAGE_CLASS=standard
fi

set -x
helm install ${RELEASENAME} ${K8SSANDRA_DIR}/charts/k8ssandra  --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE}


