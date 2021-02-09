#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source common.sh

echo -e "\n${BOLDBLUE}Updating K8ssandra installation...${NOCOLOR}"

if [[ "$KUBE_ENV" == "k3d" ]]; then
  STORAGE_CLASS=local-path
else
  STORAGE_CLASS=standard
fi

set -x
helm upgrade releasename ${K8SSANDRA_DIR}/charts/k8ssandra --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} -f ${VALUES_FILE}

utils/wait-for-ready.sh
