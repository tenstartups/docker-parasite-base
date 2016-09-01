#!/bin/bash +x
set -e

# Source systemd environment variables
. <%= getenv!(:parasite_config_directory) %>/env/parasite-host.env

# Initialize parasite configuration into volume
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_config_docker_volume) %>:<%= getenv!(:parasite_config_directory) %> \
<% ENV.select { |k, _v| k.start_with?('PARASITE_') }.each do |k, v| %>___ERB_REMOVE_LINE___
  -e <%= k %>=<%= v %> \
<% end %>___ERB_REMOVE_LINE___
  ${PARASITE_DOCKER_IMAGE_PARASITE_CONFIG} \
  container
