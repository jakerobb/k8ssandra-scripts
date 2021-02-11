#!/usr/bin/env bash
# note: this file is intended to be sourced by other scripts

# todo: add check to see if terminal colors are supported: https://unix.stackexchange.com/questions/9957/how-to-check-if-bash-can-print-colors
MODE="terminal"
if [ -t 1 ] ; then
  if [[ "$1" == "-nc" ]]; then
    shift
    MODE="pipe"
  fi
else
  MODE="pipe"
fi

if [[ "$MODE" == "pipe" ]]; then
  NOCOLOR=''
  RED=''
  BOLDRED=''
  GREEN=''
  BOLDGREEN=''
  YELLOW=''
  BOLDYELLOW=''
  BLUE=''
  BOLDBLUE=''
  MAGENTA=''
  BOLDMAGENTA=''
  CYAN=''
  BOLDCYAN=''
  WHITE=''
  BOLDWHITE=''
else
  NOCOLOR='\033[0m'
  RED='\033[0;31m'
  BOLDRED='\033[1;31m'
  GREEN='\033[0;32m'
  BOLDGREEN='\033[1;32m'
  YELLOW='\033[0;33m'
  BOLDYELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLDBLUE='\033[1;34m'
  MAGENTA='\033[0;35m'
  BOLDMAGENTA='\033[1;35m'
  CYAN='\033[0;36m'
  BOLDCYAN='\033[1;36m'
  WHITE='\033[0;37m'
  BOLDWHITE='\033[1;37m'
fi

getValueFromChartOrValuesFile() {
  PROP=$1
  VALUE=$(yq -r "${PROP}" "${VALUES_FILE}")
#  >&2 echo -e "${BOLDRED}PROP: ${RED}${PROP}${NOCOLOR}"
#  >&2 echo -e "${BOLDRED}Values File:${RED} ${VALUE}${NOCOLOR}"
  if [[ -z "$VALUE" || "${VALUE}" == "null" ]]; then
    VALUE=$(helm show values ${K8SSANDRA_DIR}/charts/k8ssandra | yq -r "$PROP")
#    >&2 echo -e "${BOLDRED}Chart Value:${RED} ${VALUE}${NOCOLOR}"
  fi
  echo "${VALUE}"
}

sayError() {
  if [[ "${AUDIBLE_ANNOUNCEMENTS}" == "true" ]]; then
    if command -v say > /dev/null; then
      say -v Allison -r 200 "[[volm 0.04]] $1" &
    fi
  fi
  echo -e "${BOLDRED}$1${NOCOLOR}"
  wait
}

saySuccess() {
  if [[ "${AUDIBLE_ANNOUNCEMENTS}" == "true" ]]; then
    if command -v say > /dev/null; then
      say -v Allison -r 200 "[[volm 0.04]] $1" &
    fi
  fi
  echo -e "${BOLDGREEN}$1${NOCOLOR}"
  wait
}

sayStatus() {
  if [[ "${AUDIBLE_ANNOUNCEMENTS}" == "true" ]]; then
    if command -v say > /dev/null; then
      say -v Allison -r 200 "[[volm 0.04]] $1" &
    fi
  fi
  wait
}

openUrl() {
  URL="$1"
  if command -v open > /dev/null ; then
    echo -e "\n${BOLDBLUE}Launching in browser: ${URL}${NOCOLOR}"
    open "${URL}"
  else
    echo -e "\n${BOLDBLUE}Navigate your browser to: ${BOLDWHITE}${URL}${NOCOLOR}"
  fi
}

accessClusterResource() {
  PROPER_NAME=$1
  PORT=$2
  URL_PATH=$3
  INGRESS_PROPERTY=$4
  FORWARD_PORT=$5
  SERVICE=$6

  INGRESS_ENABLED="$(getValueFromChartOrValuesFile '.ingress.traefik.enabled')"
  SPECIFIC_INGRESS_ENABLED="$(getValueFromChartOrValuesFile '.ingress.traefik.'${INGRESS_PROPERTY}'.enabled')"

  if [[ "${INGRESS_ENABLED}" == "true" && "${SPECIFIC_INGRESS_ENABLED}" == "true" ]]; then
    INGRESS_HOST="$(getValueFromChartOrValuesFile '.ingress.traefik.'${INGRESS_PROPERTY}'.host')"
    if [[ "${INGRESS_HOST}" == "*" ]]; then
      INGRESS_HOST=localhost
    fi
    if nslookup "${INGRESS_HOST}" &> /dev/null; then
      openUrl "http://${INGRESS_HOST}:${PORT}${URL_PATH}"
      exit
    else
      echo -e "${BOLDRED}Unable to resolve ${INGRESS_HOST}; cannot use ingress. ${NOCOLOR}"
      echo -e "${RED}To resolve this, configure a different value for ${MAGENTA}.ingress.traefik.${INGRESS_PROPERTY}.host${RED} or add an entry in your hosts file or local DNS service. Falling back to port forward...${NOCOLOR}"
    fi
  fi

  TARGET_URL="http://localhost:${FORWARD_PORT}${URL_PATH}"
  kill -9 $(cat "${INGRESS_PROPERTY}-port-forward.pid" 2> /dev/null) &> /dev/null || true

  echo -e "\n${BOLDBLUE}Forwarding local port ${FORWARD_PORT} to ${PROPER_NAME}...${NOCOLOR}"
  kubectl port-forward -n ${NAMESPACE} service/${SERVICE} "${FORWARD_PORT}:${PORT}" &> "${INGRESS_PROPERTY}-port-forward.log" &
  PORT_FORWARD_PID=$!
  echo "${PORT_FORWARD_PID}" > "${INGRESS_PROPERTY}-port-forward.pid"
  sleep 0.5

  if kill -0 ${PORT_FORWARD_PID} &> /dev/null; then

    echo -e "\n${BOLDBLUE}Waiting for ${PROPER_NAME} service to be ready on port ${FORWARD_PORT}...${NOCOLOR}"
    until nc -zv localhost "${FORWARD_PORT}" &> /dev/null; do sleep 1; echo -ne "${BOLDBLUE}.${NOCOLOR}"; done

    echo -e "\n${BOLDGREEN}${PROPER_NAME} is ready.${NOCOLOR}"
    openUrl "${TARGET_URL}"

    echo "When you're done, release the port using: kill ${PORT_FORWARD_PID}"
  else
    echo -e "${BOLDRED}Failed to create proxy.${NOCOLOR}"
    cat "${INGRESS_PROPERTY}-port-forward.log" >&2
    exit 1
  fi
}

source config/env.sh

NAMESPACE="$(getValueFromChartOrValuesFile '.k8ssandra.namespace')"
if [[ "${NAMESPACE}" == null ]]; then
  NAMESPACE=default
fi
CLUSTERNAME="$(getValueFromChartOrValuesFile '.cassandra.clusterName')"
if [[ "${CLUSTERNAME}" == null ]]; then
  CLUSTERNAME=${RELEASENAME}
fi
