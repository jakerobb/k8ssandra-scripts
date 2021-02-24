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

set +e
cd ${K8SSANDRA_DIR}
if [[ -n "$1" ]]; then
  HELM_OUTPUT=$(set -x; helm template --debug ${RELEASE_NAME} charts/k8ssandra --show-only "$1" \
                     --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE} 2> /dev/null)
  EXIT_CODE=$?
  if [[ "${EXIT_CODE}" -ne 0 ]]; then
    echo -e "\n${BOLDRED}Helm returned exit code ${EXIT_CODE}. This usually means there was a template compilation error, which is masked when using --show-only.${NOCOLOR}"
    echo -e "\n${RED}Invoking again without that option...${NOCOLOR}"
    (
      set -x
      helm template --debug ${RELEASE_NAME} charts/k8ssandra \
                    --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE}
    )
  else
    cat <<< "${HELM_OUTPUT}"
  fi
else
  (
    set -x
    helm template --debug ${RELEASE_NAME} charts/k8ssandra \
                  --set cassandra.cassandraLibDirVolume.storageClass=${STORAGE_CLASS} -n ${NAMESPACE} --create-namespace -f ${VALUES_FILE}
  )
fi
