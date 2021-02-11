#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

watch -d kubectl get ${1:-pods} -n ${NAMESPACE}
