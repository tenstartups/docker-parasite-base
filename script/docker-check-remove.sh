#!/bin/bash
set -e

# Set environment
DOCKER_IMAGE_NAME="${1:-$DOCKER_CONTAINER_NAME}"
LOG_DIRECTORY="/tmp/docker-killed-logs"

# Stop the container if running
running=$(/usr/bin/docker inspect -f {{.State.Running}} ${DOCKER_CONTAINER_NAME} 2>/dev/null || true)
if [ "$running" = "true" ]; then
  docker stop "${DOCKER_CONTAINER_NAME}" 2&>1 >/dev/null
  docker kill "${DOCKER_CONTAINER_NAME}" 2&>1 >/dev/null
fi

# Remove the container if present
present=$(/usr/bin/docker inspect -f {{.Id}} ${DOCKER_CONTAINER_NAME} 2>/dev/null || true)
if ! [ -z "$present" ]; then
  mkdir -p "${LOG_DIRECTORY}"
  docker logs > "${LOG_DIRECTORY}/${DOCKER_CONTAINER_NAME}.log"
  docker rm -f -v "${DOCKER_CONTAINER_NAME}"
fi
