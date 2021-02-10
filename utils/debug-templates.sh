#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

if [[ "$KUBE_ENV" == "k3d" ]]; then
  STORAGE_CLASS=local-path
else
  STORAGE_CLASS=standard
fi

if [[ -n "$1" ]]; then
  helm template --debug ${CLUSTERNAME}-k8ssandra ${K8SSANDRA_DIR}/charts/k8ssandra --show-only "$1" \
                --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE}
else
  helm template --debug ${CLUSTERNAME}-k8ssandra ${K8SSANDRA_DIR}/charts/k8ssandra \
                --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE}
fi
