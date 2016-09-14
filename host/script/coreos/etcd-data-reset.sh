#!/bin/bash +x
set -e

# Clear the etcd data directory (destructive)
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>" \
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
  sh -c "cd '<%= getenv!(:parasite_data_directory) %>/etcd' && rm -rfv proxy && rm -rfv member"
