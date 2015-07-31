#!/bin/bash +x

/12factor/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
docker run --rm \
  --volumes-from ${DOCKER_CONTAINER_12FACTOR_DATA} \
  -v $(pwd):/backup \
  ${DOCKER_IMAGE_SHELL} \
  bash -c 'cd /data && tar cvzf /backup/12factor-data.tar.gz .'
