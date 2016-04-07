#!/bin/bash +x
set -e

# Initialize parasite configuration into volume
/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_CONFIG}:<%= getenv!(:config_directory) %> \
  --env-file="<%= getenv!(:config_environment_file) %>" \
  --env-file="<%= getenv!(:config_environment_file) %>.local" \
  ${DOCKER_IMAGE_PARASITE_CONFIG} \
  container
