#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Determining credentials...${NOCOLOR}"

getCredentials
echo -e "${CYAN}Username:${NOCOLOR} ${CASS_USERNAME}"
echo -e "${CYAN}Password:${NOCOLOR} ${CASS_PASSWORD}"
