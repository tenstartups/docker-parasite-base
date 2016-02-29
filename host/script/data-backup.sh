#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  --volumes-from ${DOCKER_CONTAINER_PARASITE_DATA} \
  -v $(pwd):/backup \
  --net ${DOCKER_BRIDGE_NETWORK} \
  ${DOCKER_IMAGE_SHELL} \
  bash -c 'cd <%= getenv!(:data_directory) %> && tar cvzf /backup/parasite-data.tar.gz .'
