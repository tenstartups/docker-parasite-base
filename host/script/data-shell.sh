#!/bin/bash +x
set -e

# Source systemd environment variables
. <%= getenv!(:parasite_config_directory) %>/env/docker-images.env

/usr/bin/docker run -it --rm \
  -v "<%= getenv!(:parasite_data_docker_volume) %>":"<%= getenv!(:parasite_data_directory) %>" \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  sh -c "figlet 'Parasite Data' && ls -al && exec bash"
