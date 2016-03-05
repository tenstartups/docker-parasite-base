#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run -it --rm \
  -v ${DOCKER_VOLUME_PARASITE_CONFIG}:<%= getenv!(:config_directory) %> \
  ${DOCKER_IMAGE_SHELL} \
  sh -c 'cd <%= getenv!(:config_directory) %> && ls -al && exec bash'
