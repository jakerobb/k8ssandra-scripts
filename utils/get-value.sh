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
getValueFromChartOrValuesFile $1
