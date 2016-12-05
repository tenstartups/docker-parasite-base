#!/bin/bash
set -e

# Set environment
DOCKER_CONTAINER_NAME="${1:-$DOCKER_CONTAINER_NAME}"

# Stop the container if running
running=$(docker inspect --type container --format "{{.State.Running}}" ${DOCKER_CONTAINER_NAME} 2>/dev/null || true)
if [ "${running}" = "true" ]; then
  docker stop "${DOCKER_CONTAINER_NAME}" >/dev/null 2>&1
  docker kill "${DOCKER_CONTAINER_NAME}" >/dev/null 2>&1
fi

# Remove the container if present
container_id=$(docker inspect --type container --format "{{.Id}}" ${DOCKER_CONTAINER_NAME} 2>/dev/null || true)
[ -z "${container_id}" ] || docker rm --force --volumes "${DOCKER_CONTAINER_NAME}"
