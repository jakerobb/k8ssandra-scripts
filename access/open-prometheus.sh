#!/usr/bin/env bash
# This is a utility script for opening the Prometheus web UI for a k8ssandra cluster. It:
#  1. Ensures that Prometheus is ready (note that there is no timeout; if you've made a mistake, this script will wait forever.)
#  2. Forwards a local port to the Prometheus service in Kubernetes.
#  3. Launches your web browser (on Mac) or just tells you where to go.

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Waiting for Prometheus pod to be ready...${NOCOLOR}"
until kubectl wait --for=condition=ready -n ${NAMESPACE} pod -l app=prometheus -l operator.prometheus.io/name=releasename-kube-prometheu-prometheus &> /dev/null; do sleep 1; echo -ne "${BOLDBLUE}.${NOCOLOR}"; done

accessClusterResource "Prometheus" 9090 "/graph" "prometheus" 9090 "${RELEASENAME}-kube-prometheu-prometheus"
