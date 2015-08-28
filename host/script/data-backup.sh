#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
docker run --rm \
  --volumes-from ${DOCKER_CONTAINER_PARASITE_DATA} \
  -v $(pwd):/backup \
  ${DOCKER_IMAGE_SHELL} \
  bash -c 'cd <%= getenv!(:data_directory) %> && tar cvzf /backup/parasite-data.tar.gz .'
