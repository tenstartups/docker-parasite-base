#!/bin/sh
set -e

/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_config_docker_volume) %>-etcd:/etc/etcd:ro \
  --env-file "<%= getenv!(:parasite_config_directory) %>/env/etcdctl.env" \
  --net <%= getenv!(:parasite_docker_bridge_network) %> \
  tenstartups/etcdctl:latest \
  "$@"
