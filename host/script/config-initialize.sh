#!/bin/bash +x
set -e

# Initialize parasite configuration into volume
/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_CONFIG}:<%= getenv!(:parasite_config_directory) %> \
<% ENV.select { |k, _v| k.start_with?('PARASITE_') }.each do |k, v| %>___ERB_REMOVE_LINE___
  -e <%= k %>=<%= v %> \
<% end %>___ERB_REMOVE_LINE___
  ${DOCKER_IMAGE_PARASITE_CONFIG} \
  container
