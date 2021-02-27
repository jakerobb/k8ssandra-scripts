#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

STARGATE_ENABLED=$(getValueFromChartOrValuesFile '.stargate.enabled')

if [[ "${STARGATE_ENABLED}" != "true" ]]; then
  >&2 echo -e "${BOLDRED}Stargate is not enabled on this cluster.${NOCOLOR}"
  exit 1
fi


typeset -i i i # i is an integer
typeset -i i NUM_PROCESSES # end is an integer
if [[ "$1" == "-p" ]]; then
  NUM_PROCESSES=$2
  NUM_REQUESTS=$3
  NAME=$4

  getStargateHost

  echo -e "${BOLDBLUE}Determining credentials for ${CLUSTERNAME}...${NOCOLOR}"

  getCredentials

  set +e
  echo -e "${BOLDBLUE}Getting app token...${NOCOLOR}"
  getStargateAuthToken

  RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z' < /dev/urandom | head -c 6)
  KEYSPACE_NAME="stargate_load_test_${RANDOM_SUFFIX}"

  echo -e "${BOLDBLUE}Creating keyspace ${KEYSPACE_NAME}...${NOCOLOR}"
  callStargateRestApi 'POST' "/v2/schemas/keyspaces"  '{"name": "'${KEYSPACE_NAME}'","replicas": 1}'

  echo -e "\n${BOLDBLUE}Creating table...${NOCOLOR}"
  callStargateRestApi 'POST' "/v2/schemas/keyspaces/${KEYSPACE_NAME}/tables" \
                      '{"name": "testdata","columnDefinitions":[{"name": "firstname","typeDefinition": "text"},{"name": "lastname","typeDefinition": "text"},{"name": "email","typeDefinition": "text"},{"name": "favorite color","typeDefinition": "text"}],"primaryKey":{"partitionKey": ["firstname"],"clusteringKey": ["lastname"]},"tableOptions":{"defaultTimeToLive": 0,"clusteringExpression":[{ "column": "lastname", "order": "ASC" }]}}'

  set -e
  echo -e "\n${BOLDBLUE}Creating data rows...${NOCOLOR}"
  for ((i=1;i<=NUM_PROCESSES;++i)); do
    callStargateRestApi 'POST' "/v2/keyspaces/${KEYSPACE_NAME}/testdata" \
         "{\"firstname\": \"Mookie${i}\",\"lastname\": \"Betts\",\"email\": \"mookie.betts.${i}@email.com\",\"favorite color\": \"blue\"}" > /dev/null &
  done

  TOTAL_REQUESTS=$((($NUM_REQUESTS*$NUM_PROCESSES)))
  echo -e "\n${BOLDBLUE}Spawning ${NUM_PROCESSES} processes...${NOCOLOR}"
  for ((i=1;i<=NUM_PROCESSES;++i)); do
    run/stargate-load-test.sh "${STARGATE_HOST}" "${STARGATE_AUTH_TOKEN}" "${KEYSPACE_NAME}" $i ${NUM_REQUESTS} &
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

  echo -e "${BOLDBLUE}Deleting keyspace ${KEYSPACE_NAME}...${NOCOLOR}"
  callStargateRestApi 'DELETE' "/v2/schemas/keyspaces/${KEYSPACE_NAME}"

  if [[ -f "stargate-port-forward.pid" ]]; then
    echo -e "${BOLDBLUE}Terminating port forward...${NOCOLOR}"
    killStargatePortForward
  fi

  sayStatus "Test finished."
  exit
fi

STARGATE_HOST=$1
STARGATE_AUTH_TOKEN=$2
KEYSPACE_NAME=$3
INDEX=$4
CALLS=$5

set +e
sleep 3
:> stargate-load-${INDEX}.out
for ((i=1;i<=CALLS;++i)); do
  RESPONSE=$(callStargateRestApi 'PUT' "/v2/keyspaces/${KEYSPACE_NAME}/testdata/Mookie${INDEX}/Betts" \
       "{\"email\": \"mookie.betts.${INDEX}.${i}@email.com\",\"favorite color\": \"blue\"}")
  EXIT_CODE=$?
  EXPECTED="{\"data\":{\"email\":\"mookie.betts.${INDEX}.${i}@email.com\",\"favorite color\":\"blue\"}}"
  if [[ "$EXIT_CODE" -ne 0 ]]; then
    >&2 echo -ne "${BOLDRED}X${NOCOLOR}"
    echo "exit ${EXIT_CODE}" >> stargate-load-${INDEX}.out
  elif [[ "$RESPONSE" != "$EXPECTED" ]]; then
    echo "$RESPONSE" >> stargate-load-${INDEX}.out
    RESPONSE_CODE=$(jq -r '.code' <<< "${RESPONSE}" 2> /dev/null)
    if [[ "${RESPONSE_CODE}" == "401" ]]; then
      >&2 echo -ne "${BOLDMAGENTA}?${NOCOLOR}"
      getCredentials
      AUDIBLE_ANNOUNCEMENTS=false getStargateAuthToken &> /dev/null
    else
      >&2 echo -ne "${BOLDRED}x${NOCOLOR}"
    fi
  else
    >&2 echo -n "."
    echo "ok" >> stargate-load-${INDEX}.out
  fi
done

