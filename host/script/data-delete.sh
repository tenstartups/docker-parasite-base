#!/bin/bash +x
set -e

# Clear out the existing data volume
/opt/bin/send-notification warn "Deleting existing \`parasite\` data files"
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>" \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  sh -c 'rm -rf *'
