#!/bin/bash
set -e

/opt/bin/docker-check-pull ${DOCKER_IMAGE_ETCDCTL}
/usr/bin/docker run -i --rm \
  --volumes-from ${DOCKER_CONTAINER_12FACTOR_CONFIG} \
  --env-file=<%= getenv!(:config_directory) %>/env/etcdctl.env \
  --link etcdd.service:etcd \
  ${DOCKER_IMAGE_ETCDCTL} \
  "$@"
