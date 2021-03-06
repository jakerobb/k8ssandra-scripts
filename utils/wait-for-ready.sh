#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Waiting for Cassandra statefulset to exist...${NOCOLOR}"
# simulate set -x here; I don't want it to repeat every time through the loop.
echo "++ kubectl get statefulset -n ${NAMESPACE} ${CLUSTERNAME}-${DATACENTER}-default-sts"
while : ; do
  kubectl get statefulset -n ${NAMESPACE} ${CLUSTERNAME}-${DATACENTER}-default-sts && break
  sleep 5
done

echo -e "\n${BOLDBLUE}Waiting for Cassandra to start...${NOCOLOR}"
(
  set -x
  kubectl rollout status -n ${NAMESPACE} statefulset ${CLUSTERNAME}-${DATACENTER}-default-sts
)

set +e
EXITCODE=$?
if [[ "${EXITCODE}" -ne 0 ]]; then
  sayError "Cassandra deployment failed. Exit code ${EXITCODE}."
  exit 1
fi

STARGATE_ENABLED="$(getValueFromChartOrValuesFile '.stargate.enabled')"

if [[ "${STARGATE_ENABLED}" == "true" ]]; then
  echo -e "\n${BOLDBLUE}Waiting for Stargate to start...${NOCOLOR}"
  (
    set -x
    kubectl rollout status -n ${NAMESPACE} deployment ${RELEASE_NAME}-${DATACENTER}-stargate
  )
else
  echo -e "\n${BOLDBLUE}Stargate is disabled; nothing to wait for.${NOCOLOR}"
fi

EXITCODE=$?
if [[ "${EXITCODE}" -eq 0 ]]; then
  saySuccess "Cluster is ready!"
else
  sayError "Stargate deployment failed. Exit code ${EXITCODE}."
  exit 2
fi
