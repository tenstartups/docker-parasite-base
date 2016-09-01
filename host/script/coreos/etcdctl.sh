#!/bin/bash
set -e

# Source systemd environment variables
. <%= getenv!(:parasite_config_directory) %>/env/parasite-host.env

/usr/bin/docker run -i --rm \
  -v <%= getenv!(:parasite_config_docker_volume) %>:<%= getenv!(:parasite_config_directory) %> \
  --env-file "<%= getenv!(:parasite_config_directory) %>/env/etcdctl.env" \
  --net <%= getenv!(:parasite_docker_bridge_network) %> \
  ${PARASITE_DOCKER_IMAGE_ETCDCTL} \
  "$@"
