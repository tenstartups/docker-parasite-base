#!/bin/bash +x
set -e

# Set environment
parasite_service_name=$1

# Exit with error if required environment is not present
[ -z "${parasite_service_name}" ] && echo >&2 "Service name must be specified as the first argument" && exit 1

# Create the configuration volume if it doesn't exist
/usr/bin/docker volume inspect <%= getenv!(:parasite_config_docker_volume) %>-${parasite_service_name/_/-} >/dev/null 2>&1 || \
  /usr/bin/docker volume create --name <%= getenv!(:parasite_config_docker_volume) %>-${parasite_service_name/_/-}

# Initialize the service configuration into the configuration volume
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_config_docker_volume) %>-${parasite_service_name/_/-}:/tmp/config \
<% ENV.select { |k, _v| k.start_with?('PARASITE_') }.each do |k, v| %>___ERB_REMOVE_LINE___
  -e <%= k %>=<%= v %> \
<% end %>___ERB_REMOVE_LINE___
  <%= getenv!(:parasite_docker_image_name) %> \
  ${parasite_service_name} /tmp/config
