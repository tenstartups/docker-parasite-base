#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run -it --rm \
  -v ${DOCKER_VOLUME_PARASITE_CONFIG}:<%= getenv!(:config_directory) %> \
  -w "<%= getenv!(:config_directory) %>" \
  ${DOCKER_IMAGE_SHELL} \
  sh -c 'ls -al && exec bash'
