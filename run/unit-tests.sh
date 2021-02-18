#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

cd "${K8SSANDRA_DIR}"
if [[ -n "$1" ]]; then
  (
    set -x
    go test ./tests/unit -v -args -ginkgo.focus "(?i)$1"
  )
else
  (
    set -x
    go test ./tests/unit -v
  )
fi
