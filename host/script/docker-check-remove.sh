#!/bin/bash
set -e

# Set environment
DOCKER_CONTAINER_NAME="${1:-$DOCKER_CONTAINER_NAME}"

# Stop the container if running
running=$(/usr/bin/docker inspect -f {{.State.Running}} ${DOCKER_CONTAINER_NAME} 2>/dev/null || true)
if [ "$running" = "true" ]; then
  docker stop "${DOCKER_CONTAINER_NAME}" > /dev/null 2>&1
  docker kill "${DOCKER_CONTAINER_NAME}" > /dev/null 2>&1
fi

# Remove the container if present
container_image_id=$(/usr/bin/docker inspect -f {{.Image}} ${DOCKER_CONTAINER_NAME} 2>/dev/null || true)
container_id=$(/usr/bin/docker inspect -f {{.Id}} ${container_image_id} 2>/dev/null || true)
if ! [ -z "$container_id" ]; then
  old_umask=`umask` && umask 000 && exec 200>/tmp/.docker.lockfile && umask ${old_umask}
  if flock --exclusive --wait 30 200; then
    docker rm -f -v "${DOCKER_CONTAINER_NAME}"
    flock --unlock 200
  fi
fi
