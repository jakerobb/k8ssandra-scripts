#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

set -x
kubectl patch -n ${NAMESPACE} cassdc "${DATACENTER}}" --type merge -p '{"spec":{"stopped":false}}'
