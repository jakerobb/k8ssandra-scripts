#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

DC=dc1
WAIT=false
while getopts :d:w opt; do
  case ${opt} in
    d) DC=${OPTARG}
      shift
      ;;
    w) WAIT=true
      ;;
    \?)
      echo -e "Invalid option: -${OPTARG}" >&2
      printUsageAndExit 6
      ;;
    \:)
      echo -e "Missing required option after -${OPTARG}" >&2
      ;;
    *)
      echo -e "Error encountered at line ${LINENO}."
      echo -e "${scriptname}: unknown error while parsing arguments"
      exit 8
    ;;
  esac
  shift
done

printPods() {
  (
    set -x
    kubectl -n ${NAMESPACE} get pods -l "cassandra.datastax.com/cluster=${CLUSTERNAME}" -l "cassandra.datastax.com/datacenter=${DC}"
  )
}

CURRENT_SIZE=$(set -x; kubectl -n ${NAMESPACE} get cassdc ${DC} -o jsonpath='{.spec.size}')
if [[ -n "$1" ]]; then
  SIZE=$1
  if [[ "${SIZE}" == "${CURRENT_SIZE}" ]]; then
    echo -e "${BOLDRED}Datacenter ${DC} already has size ${SIZE}.${NOCOLOR}"
    printPods
  else
    echo -e "${BOLDBLUE}Changing size of datacenter ${DC} from ${CURRENT_SIZE} to ${SIZE}.${NOCOLOR}"
    sleep 2
    (
      set -x
      kubectl patch -n ${NAMESPACE} cassdc "${DC}" --type merge -p '{"spec":{"size":'${SIZE}'}}'
    )
    if [[ "${WAIT}" == "true" ]]; then
      utils/wait-for-ready.sh
    else
      printPods
    fi
  fi
else
  echo -e "${BOLDBLUE}Datacenter ${DC} has size ${CURRENT_SIZE}.${NOCOLOR}"
  printPods
fi

