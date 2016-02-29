#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run -it --rm \
  --volumes-from ${DOCKER_CONTAINER_PARASITE_DATA} \
  ${DOCKER_IMAGE_SHELL} \
  sh -c 'cd <%= getenv!(:data_directory) %> && ls -al && exec bash'
