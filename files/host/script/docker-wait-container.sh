#!/bin/sh
set -e

# Set environment
DOCKER_CONTAINER_NAME=${1:-$DOCKER_CONTAINER_NAME}
MAX_CHECKS=${2:-$MAX_CHECKS}
MAX_CHECKS=${MAX_CHECKS:-10}

# Exit with error if required environment is not present
if [ -z "${DOCKER_CONTAINER_NAME}" ]; then
  echo >&2 "Environment variable DOCKER_CONTAINER_NAME must be provided"
  exit 1
fi

exit_success() {
  # Notify success and exit
  echo "Container ${DOCKER_CONTAINER_NAME} is running."
  /opt/bin/send-notification success "Container \`${DOCKER_CONTAINER_NAME}\` is running."
  exit 0
}

exit_failure() {
  # Notify failure and exit
  echo >&2 "Timed-out waiting for container ${DOCKER_CONTAINER_NAME} to start."
  /opt/bin/send-notification error "Timed-out waiting for container  \`${DOCKER_CONTAINER_NAME}\` to start."
  exit 1
}

test_number=0
next_test_wait=1
while [ "${test_number}" -lt "${MAX_CHECKS}" ]; do
  test_number=$(( test_number + 1 ))
  [ "$(docker inspect --type container --format "{{.State.Running}}" ${DOCKER_CONTAINER_NAME} 2>/dev/null || true)" = "true" ] && exit_success
  echo "Waiting for ${DOCKER_CONTAINER_NAME} container to start..."
  sleep ${next_test_wait}
  next_test_wait=$(( next_test_wait * 2 ))
done
exit_failure
