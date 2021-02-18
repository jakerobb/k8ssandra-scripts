#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

STARGATE_ENABLED=$(getValueFromChartOrValuesFile '.stargate.enabled')

if [[ "${STARGATE_ENABLED}" != "true" ]]; then
  >&2 echo -e "${BOLDRED}Stargate is not enabled on this cluster.${NOCOLOR}"
  exit 1
fi

STARGATE_HOST="$(getValueFromChartOrValuesFile '.stargate.ingress.host')"
if [[ "${STARGATE_HOST}" == "*" || "${STARGATE_HOST}" == "null" || -z "${STARGATE_HOST}" ]]; then
  STARGATE_HOST=localhost
fi

typeset -i i i # i is an integer
typeset -i i NUM_PROCESSES # end is an integer
if [[ "$1" == "-n" ]]; then
  NUM_PROCESSES=$2
  NUM_REQUESTS=$3
  NAME=$4

  echo -e "${BOLDBLUE}Stargate host: ${BLUE}${STARGATE_HOST}${NOCOLOR}"
  echo -e "${BOLDBLUE}Determining credentials for ${CLUSTERNAME}...${NOCOLOR}"

  set -e
  SECRET=$(kubectl get secret "${CLUSTERNAME}-superuser" -n ${NAMESPACE} -o=jsonpath='{.data}')
  USERNAME="$(jq -r '.username' <<< "$SECRET" | base64 -d)"
  PASSWORD="$(jq -r '.password' <<< "$SECRET" | base64 -d)"

  set +e
  echo -e "${BOLDBLUE}Getting app token...${NOCOLOR}"
  AUTH_RESPONSE=$(curl -s --show-error --location --request POST "http://${STARGATE_HOST}:8081/v1/auth" \
       --header 'Content-Type: application/json' \
       --data-raw "{\"username\": \"${USERNAME}\",\"password\": \"${PASSWORD}\"}")
  EXITCODE=$?
  if [[ "$EXITCODE" -ne 0 ]]; then
    sayError "Unable to get an auth token, exit code ${EXITCODE}."
    exit 1
  elif [[ "$AUTH_RESPONSE" == "Service Unavailable" ]]; then
    sayError "Unable to get an auth token; Stargate service is not available."
    exit 2
  fi
  echo "${AUTH_RESPONSE}"
  TOKEN=$(jq -r '.authToken' <<< "${AUTH_RESPONSE}")
  EXITCODE=$?
  if [[ "$EXITCODE" -ne 0 ]]; then
    sayError "Unable to parse the auth response, exit code ${EXITCODE}."
    echo -e "Auth response:\n${AUTH_RESPONSE}"
    exit 1
  fi

  echo -e "${BOLDBLUE}Creating keyspace...${NOCOLOR}"
  curl -s \
       --location --request POST "${STARGATE_HOST}:8082/v2/schemas/keyspaces" \
       --header "X-Cassandra-Token: ${TOKEN}" \
       --header 'Content-Type: application/json' \
       --data-raw '{"name": "users_keyspace","replicas": 1}'

  echo -e "\n${BOLDBLUE}Creating table...${NOCOLOR}"
  curl -s \
       --location --request POST "${STARGATE_HOST}:8082/v2/schemas/keyspaces/users_keyspace/tables" \
       --header "X-Cassandra-Token: ${TOKEN}" \
       --header 'Content-Type: application/json' \
       --data-raw '{"name": "users","columnDefinitions":[{"name": "firstname","typeDefinition": "text"},{"name": "lastname","typeDefinition": "text"},{"name": "email","typeDefinition": "text"},{"name": "favorite color","typeDefinition": "text"}],"primaryKey":{"partitionKey": ["firstname"],"clusteringKey": ["lastname"]},"tableOptions":{"defaultTimeToLive": 0,"clusteringExpression":[{ "column": "lastname", "order": "ASC" }]}}'

  set -e
  echo -e "\n${BOLDBLUE}Creating data rows...${NOCOLOR}"
  for ((i=1;i<=NUM_PROCESSES;++i)); do
    curl -s \
         --location --request POST "http://${STARGATE_HOST}:8082/v2/keyspaces/users_keyspace/users" \
         --header "X-Cassandra-Token: ${TOKEN}" \
         --header 'Content-Type: application/json' \
         --data-raw "{\"firstname\": \"Mookie${i}\",\"lastname\": \"Betts\",\"email\": \"mookie.betts.${i}@email.com\",\"favorite color\": \"blue\"}" > /dev/null &
  done

  TOTAL_REQUESTS=$((($NUM_REQUESTS*$NUM_PROCESSES)))
  echo -e "\n${BOLDBLUE}Spawning ${NUM_PROCESSES} processes...${NOCOLOR}"
  for ((i=1;i<=NUM_PROCESSES;++i)); do
    run/stargate-load-test.sh "${TOKEN}" $i ${NUM_REQUESTS} &
  done
  echo -n "Starting requests in 3... "
  sleep 1
  echo -n "2... "
  sleep 1
  echo "1... "
  echo -e "${BOLDGREEN}Test started at $(date '+%r'). Sending ${TOTAL_REQUESTS} requests.${NOCOLOR}"
  START_TIME=$(date '+%s')
  wait
  END_TIME=$(date '+%s')
  TOTAL_SECONDS=$((($END_TIME-$START_TIME)))
  if [[ "${TOTAL_SECONDS}" == "0" ]]; then
    echo -e "\n${BOLDGREEN}Test finished at $(date '+%r'). Sent ${TOTAL_REQUESTS} requests in <1 second.${NOCOLOR}"
  else
    REQUEST_RATE=$((($TOTAL_REQUESTS/$TOTAL_SECONDS)))
    echo -e "\n${BOLDGREEN}Test finished at $(date '+%r'). Sent ${TOTAL_REQUESTS} requests in ~${TOTAL_SECONDS} seconds (~${REQUEST_RATE}/sec).${NOCOLOR}"
  fi

  RESULTS=""
  rm -f stargate-load-combined.out
  cat stargate-load-*.out > stargate-load-combined.out

  echo -e "\n${BOLDGREEN}Results Summary:${NOCOLOR}"
  sort stargate-load-combined.out | uniq -c
  rm -f stargate-load-*.out

  sayStatus "Test finished."
  exit
fi

TOKEN=$1
INDEX=$2
CALLS=$3

sleep 3
echo -n "" > stargate-load-${INDEX}.out
for ((i=1;i<=CALLS;++i)); do
  RESPONSE=$(curl -s \
       --location --request PUT "http://${STARGATE_HOST}:8082/v2/keyspaces/users_keyspace/users/Mookie${INDEX}/Betts" \
       --header "X-Cassandra-Token: ${TOKEN}" \
       --header 'Content-Type: application/json' \
       --data-raw "{\"email\": \"mookie.betts.${INDEX}.${i}@email.com\"}")
  EXIT_CODE=$?
  EXPECTED="{\"data\":{\"email\":\"mookie.betts.${INDEX}.${i}@email.com\"}}"
  if [[ "$EXIT_CODE" -ne 0 ]]; then
    >&2 echo -ne "${BOLDRED}X${NOCOLOR}"
    echo "exit ${EXIT_CODE}" >> stargate-load-${INDEX}.out
  elif [[ "$RESPONSE" != "$EXPECTED" ]]; then
    >&2 echo -ne "${BOLDRED}x${NOCOLOR}"
    echo "$RESPONSE" >> stargate-load-${INDEX}.out
  else
    >&2 echo -n "."
    echo "ok" >> stargate-load-${INDEX}.out
  fi
done

