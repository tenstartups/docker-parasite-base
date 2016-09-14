#!/bin/bash +x
set -e

/usr/bin/docker run -it --rm \
  -v "<%= getenv!(:parasite_data_docker_volume) %>":"<%= getenv!(:parasite_data_directory) %>" \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
  sh -c "figlet 'Parasite Data' && ls -al && exec bash"
