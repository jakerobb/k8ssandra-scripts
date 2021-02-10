#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

cd "${K8SSANDRA_DIR}"
if [[ -n "$1" ]]; then
  go test ./tests/integration -v -args -ginkgo.focus "(i?)$1"
else
  go test ./tests/integration -v
fi
