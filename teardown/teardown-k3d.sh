#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Tearing down k3d...${NOCOLOR}"
set -x
k3d cluster delete &> /dev/null || true
