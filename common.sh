#!/usr/bin/env bash
# note: this file is intended to be sourced by other scripts

# todo: add check to see if terminal colors are supported: https://unix.stackexchange.com/questions/9957/how-to-check-if-bash-can-print-colors
if [ -t 1 ] ; then
  MODE="terminal"
  COLORMODE="--color"
else
  MODE="pipe"
  COLORMODE="--nocolor"
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

printContext() {
  echo -e "${BOLDCYAN}K8ssandra directory: ${CYAN}${K8SSANDRA_DIR}${NOCOLOR}"
  echo -e "${BOLDCYAN}Git branch: ${CYAN}$(cd ${K8SSANDRA_DIR}; git branch --show-current 2>&1)${NOCOLOR}"
  echo ""
  echo -e "${BOLDCYAN}NAMESPACE: ${CYAN}${NAMESPACE}${NOCOLOR}"
  echo -e "${BOLDCYAN}CLUSTERNAME: ${CYAN}${CLUSTERNAME}${NOCOLOR}"
  echo -e "${BOLDCYAN}RELEASE_NAME: ${CYAN}${RELEASE_NAME}${NOCOLOR}"
  echo -e "${BOLDCYAN}KUBE_ENV: ${CYAN}${KUBE_ENV}${NOCOLOR}"
  echo -e "${BOLDCYAN}Values:${NOCOLOR}"
  yq '.' ${VALUES_FILE}
}

getCredentials() {
  SECRET=$(kubectl get secret "${CLUSTERNAME}-superuser" -n ${NAMESPACE} -o=jsonpath='{.data}')
  CASS_USERNAME="$(jq -r '.username' <<< "$SECRET" | base64 -d)"
  CASS_PASSWORD="$(jq -r '.password' <<< "$SECRET" | base64 -d)"
}

getStargateHost() {
  INGRESS_ENABLED="$(getValueFromChartOrValuesFile '.stargate.ingress.enabled')"
  if [[ "${INGRESS_ENABLED}" == "true" ]]; then
    STARGATE_HOST="$(getValueFromChartOrValuesFile '.stargate.ingress.rest.host')"
    if [[ "${STARGATE_HOST}" == "*" || "${STARGATE_HOST}" == "null" || -z "${STARGATE_HOST}" ]]; then
      STARGATE_HOST="$(getValueFromChartOrValuesFile '.stargate.ingress.host')"
      if [[ "${STARGATE_HOST}" == "*" || "${STARGATE_HOST}" == "null" || -z "${STARGATE_HOST}" ]]; then
        STARGATE_HOST=localhost
      fi
    fi
    if nslookup "${STARGATE_HOST}" &> /dev/null; then
      echo -e "${BOLDBLUE}Using ingress via host ${STARGATE_HOST}...${NOCOLOR}"
      return
    else
      echo -e "${BOLDRED}Unable to resolve ${STARGATE_HOST}; cannot use ingress. ${NOCOLOR}"
      echo -e "${RED}To resolve this, configure a different value for ${MAGENTA}.stargate.ingress.host${RED} or add an entry in your hosts file or local DNS service. Falling back to port forward...${NOCOLOR}"
    fi
  fi

  kill -9 $(cat "stargate-port-forward.pid" 2> /dev/null) &> /dev/null || true

  echo -e "\n${BOLDBLUE}Forwarding local port ${FORWARD_PORT} to Stargate...${NOCOLOR}"
  kubectl port-forward -n ${NAMESPACE} service/${SERVICE} "${FORWARD_PORT}:${PORT}" &> "stargate-port-forward.log" &
  PORT_FORWARD_PID=$!
  echo "${PORT_FORWARD_PID}" > "stargate-port-forward.pid"
  sleep 0.5

  if kill -0 ${PORT_FORWARD_PID} &> /dev/null; then
    echo -e "\n${BOLDBLUE}Waiting for Stargate service to be ready on port ${FORWARD_PORT}...${NOCOLOR}"
    until nc -zv localhost "${FORWARD_PORT}" &> /dev/null; do sleep 1; echo -ne "${BOLDBLUE}.${NOCOLOR}"; done

    echo -e "\n${BOLDGREEN}Stargate is ready.${NOCOLOR}"
    STARGATE_HOST=localhost
    exit
  else
    echo -e "${BOLDRED}Failed to create proxy.${NOCOLOR}"
    cat "stargate-port-forward.log" >&2
    return 1
  fi
}

killStargatePortForward() {
  kill -9 $(cat "stargate-port-forward.pid" 2> /dev/null) &> /dev/null || true
}

getStargateAuthToken() {
  AUTH_RESPONSE=$(curl -s --show-error --location --request POST "http://${STARGATE_HOST}:8081/v1/auth" \
     --header 'Content-Type: application/json' \
     --data-raw "{\"username\": \"${CASS_USERNAME}\",\"password\": \"${CASS_PASSWORD}\"}")
  EXITCODE=$?
  if [[ "$EXITCODE" -ne 0 ]]; then
    sayError "Unable to get an auth token, exit code ${EXITCODE}."
    exit 1
  elif [[ "$AUTH_RESPONSE" == "Service Unavailable" ]]; then
    sayError "Unable to get an auth token; Stargate service is not available."
    exit 2
  fi
  echo "${AUTH_RESPONSE}"
  STARGATE_AUTH_TOKEN=$(jq -r '.authToken' <<< "${AUTH_RESPONSE}")

  EXITCODE=$?
  if [[ "$EXITCODE" -ne 0 ]]; then
    sayError "Unable to parse the auth response, exit code ${EXITCODE}."
    echo -e "Auth response:\n${AUTH_RESPONSE}"
    exit 1
  fi
}

callStargateRestApi() {
  VERB=$1
  REQUEST_PATH=$2
  REQUEST_BODY=$3
  if [[ -z "${REQUEST_BODY}" ]]; then
    curl -s \
       --location --request "${VERB}" "${STARGATE_HOST}:8082${REQUEST_PATH}" \
       --header "X-Cassandra-Token: ${STARGATE_AUTH_TOKEN}"
  else
    curl -s \
       --location --request "${VERB}" "${STARGATE_HOST}:8082${REQUEST_PATH}" \
       --header "X-Cassandra-Token: ${STARGATE_AUTH_TOKEN}" \
       --header 'Content-Type: application/json' \
       --data-raw "${REQUEST_BODY}"
  fi
  CURL_EXIT_CODE=$?
  return ${CURL_EXIT_CODE}
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

openCqlsh() {
  getCredentials
  if [[ -n "$1" ]]; then
    (
      set -x
      cqlsh -u "${CASS_USERNAME}" -p "${CASS_PASSWORD}" $1
    )
  else
    (
      set -x
      cqlsh -u "${CASS_USERNAME}" -p "${CASS_PASSWORD}" localhost
    )
  fi
}

accessClusterResource() {
  PROPER_NAME=$1
  PORT=$2
  URL_PATH=$3
  INGRESS_PROPERTY=$4
  FORWARD_PORT=$5
  SERVICE=$6

  INGRESS_ENABLED="$(getValueFromChartOrValuesFile '.'${INGRESS_PROPERTY}'.ingress.enabled')"

  if [[ "${INGRESS_ENABLED}" == "true" ]]; then
    INGRESS_HOST="$(getValueFromChartOrValuesFile '.'${INGRESS_PROPERTY}'.ingress.host')"
    if [[ "${INGRESS_HOST}" == "*" ]]; then
      INGRESS_HOST=localhost
    fi
    if nslookup "${INGRESS_HOST}" &> /dev/null; then
      openUrl "http://${INGRESS_HOST}:${PORT}${URL_PATH}"
      exit
    else
      echo -e "${BOLDRED}Unable to resolve ${INGRESS_HOST}; cannot use ingress. ${NOCOLOR}"
      echo -e "${RED}To resolve this, configure a different value for ${MAGENTA}.${INGRESS_PROPERTY}.ingress.host${RED} or add an entry in your hosts file or local DNS service. Falling back to port forward...${NOCOLOR}"
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

function abspath() {
    # generate absolute path from relative path
    # $1     : relative filename
    # return : absolute path
    if [ -d "$1" ]; then
        # dir
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        # file
        if [[ $1 = /* ]]; then
            echo "$1"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    fi
}

source config/env.sh

VALUES_FILE="$(abspath "${VALUES_FILE}")"

NAMESPACE="$(getValueFromChartOrValuesFile '.k8ssandra.namespace')"
if [[ -z "${NAMESPACE}" ||  "${NAMESPACE}" == null ]]; then
  NAMESPACE=default
fi
CLUSTERNAME="$(getValueFromChartOrValuesFile '.cassandra.clusterName')"
if [[ -z "${CLUSTERNAME}" || "${CLUSTERNAME}" == null ]]; then
  CLUSTERNAME=${RELEASE_NAME}
fi

if [[ "$1" == "--nocolor" ]]; then
  shift
  MODE="pipe"
  COLORMODE="--nocolor"
elif [[ "$1" == "--color" ]]; then
  shift
  MODE="terminal"
  COLORMODE="--color"
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
  NOCOLOR=$(printf '\033[0m')
  RED=$(printf '\033[0;31m')
  BOLDRED=$(printf '\033[1;31m')
  GREEN=$(printf '\033[0;32m')
  BOLDGREEN=$(printf '\033[1;32m')
  YELLOW=$(printf '\033[0;33m')
  BOLDYELLOW=$(printf '\033[1;33m')
  BLUE=$(printf '\033[0;34m')
  BOLDBLUE=$(printf '\033[1;34m')
  MAGENTA=$(printf '\033[0;35m')
  BOLDMAGENTA=$(printf '\033[1;35m')
  CYAN=$(printf '\033[0;36m')
  BOLDCYAN=$(printf '\033[1;36m')
  WHITE=$(printf '\033[0;37m')
  BOLDWHITE=$(printf '\033[1;37m')
fi

DATACENTER="$(getValueFromChartOrValuesFile '.cassandra.datacenters[0].name')"
while getopts :n:d: opt; do
  case ${opt} in
    n) NAMESPACE=${OPTARG}
      ;;
    d) DATACENTER=${OPTARG}
      ;;
    \:)
      echo -e "${BOLDRED}Missing required option after -${OPTARG}${NOCOLOR}" >&2
      exit 99
      ;;
    *)
      echo -e "${BOLDRED}Error encountered at line ${LINENO}.${NOCOLOR}"
      echo -e "${RED}${scriptname}: unknown error while parsing arguments${NOCOLOR}"
      exit 100
    ;;
  esac
  shift $((OPTIND -1))
done

