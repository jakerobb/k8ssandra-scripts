#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source common.sh

echo -e "${BOLDBLUE}Updating K8ssandra installation...${NOCOLOR}"
printContextWithValues

if [[ "$KUBE_ENV" == "k3d" ]]; then
  STORAGE_CLASS=local-path
else
  STORAGE_CLASS=standard
fi

set -x
helm upgrade ${RELEASE_NAME} ${K8SSANDRA_DIR}/charts/k8ssandra --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} -f ${VALUES_FILE}

utils/wait-for-ready.sh
utils/get-credentials.sh
