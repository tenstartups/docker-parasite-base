#!/bin/bash +x
set -e

/usr/bin/docker run -it --rm \
  -v "<%= getenv!(:parasite_config_docker_volume) %>":"<%= getenv!(:parasite_config_directory) %>" \
  -w "<%= getenv!(:parasite_config_directory) %>" \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  sh -c "figlet 'Parasite Config' && ls -al && exec bash"
