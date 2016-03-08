#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run -it --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:<%= getenv!(:data_directory) %> \
  -w "<%= getenv!(:data_directory) %>" \
  ${DOCKER_IMAGE_SHELL} \
  sh -c 'ls -al && exec bash'
