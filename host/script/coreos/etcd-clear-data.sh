#!/bin/bash +x
set -e

# Clear the etcd data directory (destructive)
echo "Clearing existing etcd container state data..."
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>" \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  sh -c "cd '<%= getenv!(:parasite_data_directory) %>/etcd' && rm -rfv proxy && rm -rfv member"
