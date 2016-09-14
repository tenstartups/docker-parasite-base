#!/bin/bash +x
set -e

# Initialize parasite configuration into volume
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_config_docker_volume) %>:<%= getenv!(:parasite_config_directory) %> \
<% ENV.select { |k, _v| k.start_with?('PARASITE_') }.each do |k, v| %>___ERB_REMOVE_LINE___
  -e <%= k %>=<%= v %> \
<% end %>___ERB_REMOVE_LINE___
  <%= getenv!(:parasite_docker_image_name) %> \
  container
