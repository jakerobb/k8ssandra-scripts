#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Tearing down kind...${NOCOLOR}"
set -x
kind delete cluster &> /dev/null || true
