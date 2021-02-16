#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "\n${BOLDBLUE}Ensuring Cassandra is ready...${NOCOLOR}"
kubectl rollout status -n ${NAMESPACE} statefulset ${CLUSTERNAME}-dc1-default-sts

CASSANDRA_INGRESS_ENABLED="$(getValueFromChartOrValuesFile '.cassandra.ingress.enabled')"
STARGATE_ENABLED="$(getValueFromChartOrValuesFile '.stargate.enabled')"
STARGATE_CASSANDRA_INGRESS_ENABLED="$(getValueFromChartOrValuesFile '.stargate.ingress.cassandra.enabled')"

if [[ "${CASSANDRA_INGRESS_ENABLED}" == "true" ]]; then
  echo -e "${BOLDBLUE}Using direct-to-Cassandra ingress...${NOCOLOR}"
  INGRESS_HOST="$(getValueFromChartOrValuesFile '.cassandra.ingress.host')"
  if [[ "${INGRESS_HOST}" == "*" || "${INGRESS_HOST}" == "" || "${INGRESS_HOST}" == "null" ]]; then
    INGRESS_HOST=localhost
  fi
  if nslookup "${INGRESS_HOST}" &> /dev/null; then
    openCqlsh "${INGRESS_HOST}"
    exit
  else
    echo -e "${BOLDRED}Unable to resolve ${INGRESS_HOST}; cannot use ingress. ${NOCOLOR}"
    echo -e "${RED}To resolve this, configure a different value for ${MAGENTA}.cassandra.ingress.host${RED} or add an entry in your hosts file or local DNS service. Falling back to port forward...${NOCOLOR}"
  fi
fi

if [[ "${STARGATE_ENABLED}" == "true" && "${STARGATE_CASSANDRA_INGRESS_ENABLED}" == "true" ]]; then
  echo -e "${BOLDBLUE}Using via-Stargate ingress...${NOCOLOR}"
  echo -e "\n${BOLDBLUE}Waiting for Stargate to start...${NOCOLOR}"
  until kubectl wait --for=condition=available -n ${NAMESPACE} deployment ${RELEASENAME}-dc1-stargate &> /dev/null; do sleep 1; done
  echo -e "\n${BOLDGREEN}Stargate is ready!${NOCOLOR}\n"

  INGRESS_HOST="$(getValueFromChartOrValuesFile '.stargate.ingress.host')"
  INGRESS_HOST_OVERRIDE="$(getValueFromChartOrValuesFile '.stargate.ingress.cassandra.host')"
  if [[ "${INGRESS_HOST_OVERRIDE}" != "" && "${INGRESS_HOST_OVERRIDE}" != "null" ]]; then
    INGRESS_HOST="${INGRESS_HOST_OVERRIDE}"
  fi
  if [[ "${INGRESS_HOST}" == "*" || "${INGRESS_HOST}" == "" || "${INGRESS_HOST}" == "null" ]]; then
    INGRESS_HOST=localhost
  fi
  if nslookup "${INGRESS_HOST}" &> /dev/null; then
    openCqlsh "${INGRESS_HOST}"
    exit
  else
    echo -e "${BOLDRED}Unable to resolve ${INGRESS_HOST}; cannot use ingress. ${NOCOLOR}"
    echo -e "${RED}To resolve this, configure a different value for ${MAGENTA}stargate.ingress.host${RED} or add an entry in your hosts file or local DNS service. Falling back to port forward...${NOCOLOR}"
  fi
fi

kill -9 $(cat "cassandra-port-forward.pid" 2> /dev/null) &> /dev/null || true

echo -e "\n${BOLDBLUE}Forwarding local port 9042 to Cassandra...${NOCOLOR}"
kubectl port-forward -n ${NAMESPACE} service/${CLUSTERNAME}-dc1-service 9042 &> "cassandra-port-forward.log" &
PORT_FORWARD_PID=$!
echo "${PORT_FORWARD_PID}" > "cassandra-port-forward.pid"
sleep 0.5

if kill -0 ${PORT_FORWARD_PID} &> /dev/null; then

  echo -e "\n${BOLDBLUE}Waiting for Cassandra service to be ready on port 9042...${NOCOLOR}"
  until nc -zv localhost "9042" &> /dev/null; do sleep 1; echo -ne "${BOLDBLUE}.${NOCOLOR}"; done

  echo -e "\n${BOLDGREEN}Cassandra is ready.${NOCOLOR}"
  openCqlsh "localhost"

  echo -e "\n${blue}cqlsh has exited. Terminating port-forward.${NOCOLOR}"
  set -e
  kill "${PORT_FORWARD_PID}"
  rm -f "cassandra-port-forward.pid"
else
  echo -e "${BOLDRED}Failed to create proxy.${NOCOLOR}"
  cat "cassandra-port-forward.log" >&2
  exit 1
fi
