#!/bin/bash
set -e

# Set environment
DOCKER_CONTAINER_NAME=${1:-$DOCKER_CONTAINER_NAME}
MAX_CHECKS=${2:-$MAX_CHECKS}
MAX_CHECKS=${MAX_CHECKS:-5}

# Exit with error if required environment is not present
if [ -z "${DOCKER_CONTAINER_NAME}" ]; then
  echo "Environment variable DOCKER_CONTAINER_NAME must be provided"
  exit 1
fi

T="$(date +%s)"

test_number=0
next_test_wait=1
while [[ ${test_number} < ${MAX_CHECKS} ]]; do
  test_number=$(( test_number + 1 ))
  CONTAINER_RUNNING=`/usr/bin/docker inspect -f {{.State.Running}} ${DOCKER_CONTAINER_NAME} || true`
  if [ ${test_number} = ${MAX_CHECKS} ] || [ "${CONTAINER_RUNNING}" = "true" ]; then break; fi
  echo "Waiting ${next_test_wait} seconds for ${DOCKER_CONTAINER_NAME} container to start..."
  sleep ${next_test_wait}
  next_test_wait=$(( next_test_wait * 2 ))
done

T="$(($(date +%s)-T))"

# Exit based on whether the container is running or not
if [ "${CONTAINER_RUNNING}" = "true" ]; then
  echo "Container ${DOCKER_CONTAINER_NAME} is running after $T seconds."
  /12factor/bin/send-notification success "Container \`${DOCKER_CONTAINER_NAME}\` is running after $T seconds."
  exit 0
else
  echo "Container ${DOCKER_CONTAINER_NAME} is NOT running after $T seconds."
  /12factor/bin/send-notification error "Container \`${DOCKER_CONTAINER_NAME}\` is NOT running after $T seconds."
  exit 1
fi
