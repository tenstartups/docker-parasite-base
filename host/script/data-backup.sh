#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
docker run --rm \
  --volumes-from ${DOCKER_CONTAINER_12FACTOR_DATA} \
  -v $(pwd):/backup \
  ${DOCKER_IMAGE_SHELL} \
  bash -c 'cd <%= data_directory %> && tar cvzf /backup/12factor-data.tar.gz .'
