#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

if [[ "$KUBE_ENV" == "k3d" ]]; then
  STORAGE_CLASS=local-path
else
  STORAGE_CLASS=standard
fi

printContext

cd ${K8SSANDRA_DIR}
if [[ -n "$1" ]]; then
  set -x
  helm template --debug ${RELEASENAME} charts/k8ssandra --show-only "$1" \
                --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE}
else
  set -x
  helm template --debug ${RELEASENAME} charts/k8ssandra \
                --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE}
fi
