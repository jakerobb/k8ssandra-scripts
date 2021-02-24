#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

WAIT=false
while getopts :w opt; do
  case ${opt} in
    w) WAIT=true
      ;;
    *)
      echo -e "Error encountered at line ${LINENO}."
      echo -e "${scriptname}: unknown error while parsing arguments"
      exit 8
    ;;
  esac
  shift $((OPTIND -1))
done

printPods() {
  (
    set -x
    kubectl -n ${NAMESPACE} get pods -l "cassandra.datastax.com/cluster=${CLUSTERNAME}" -l "cassandra.datastax.com/datacenter=${DATACENTER}"
  )
}

CURRENT_SIZE=$(set -x; kubectl -n ${NAMESPACE} get cassdc ${DATACENTER} -o jsonpath='{.spec.size}')
if [[ -n "$1" ]]; then
  SIZE=$1
  if [[ "${SIZE}" == "${CURRENT_SIZE}" ]]; then
    echo -e "${BOLDRED}Datacenter ${DATACENTER} already has size ${SIZE}.${NOCOLOR}"
    printPods
  else
    echo -e "${BOLDBLUE}Changing size of datacenter ${DATACENTER} from ${CURRENT_SIZE} to ${SIZE}.${NOCOLOR}"
    sleep 2
    (
      set -x
      kubectl patch -n ${NAMESPACE} cassdc "${DATACENTER}" --type merge -p '{"spec":{"size":'${SIZE}'}}'
    )
    if [[ "${WAIT}" == "true" ]]; then
      utils/wait-for-ready.sh
    else
      printPods
    fi
  fi
else
  echo -e "${BOLDBLUE}Datacenter ${DATACENTER} has size ${CURRENT_SIZE}.${NOCOLOR}"
  printPods
fi

