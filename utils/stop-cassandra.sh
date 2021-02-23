#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

DC=dc1
if [[ -n "$1" ]]; then
  DC=$1
fi

set -x
kubectl patch -n ${NAMESPACE} cassdc "${DC}" --type merge -p '{"spec":{"stopped":true}}'
