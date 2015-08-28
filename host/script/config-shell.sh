#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
docker run -it --rm \
  --volumes-from ${DOCKER_CONTAINER_PARASITE_CONFIG} \
  ${DOCKER_IMAGE_SHELL} \
  sh -c 'cd <%= getenv!(:config_directory) %> && ls -al && exec bash'
