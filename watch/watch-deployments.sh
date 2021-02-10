#!/usr/bin/env bash

set -e
cd "$(dirname "$0")/.."
source common.sh

watch -d kubectl get deployments -n ${NAMESPACE}
