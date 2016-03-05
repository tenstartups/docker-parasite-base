#!/bin/bash
set -e

/opt/bin/docker-check-pull ${DOCKER_IMAGE_ETCDCTL}
/usr/bin/docker run -i --rm \
  -v ${DOCKER_VOLUME_PARASITE_CONFIG}:<%= getenv!(:config_directory) %> \
  --env-file=<%= getenv!(:config_directory) %>/env/etcdctl.env \
  --net ${DOCKER_BRIDGE_NETWORK_NAME} \
  --link etcdd.service:etcd \
  ${DOCKER_IMAGE_ETCDCTL} \
  "$@"
