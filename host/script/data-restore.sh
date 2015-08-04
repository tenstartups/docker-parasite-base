#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_12FACTOR_DATA}"
/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
if [ -z "$(docker ps --no-trunc -a -q -f label=${DOCKER_CONTAINER_12FACTOR_DATA})" ]; then
  docker run \
    --label ${DOCKER_VOLUME_CONTAINER_LABEL} \
    --label ${DOCKER_CONTAINER_12FACTOR_DATA} \
    --volume <%= getenv!(:data_directory) %> \
    --name ${DOCKER_CONTAINER_12FACTOR_DATA} \
    ${DOCKER_IMAGE_12FACTOR_DATA}
  docker run --rm \
    --volumes-from ${DOCKER_CONTAINER_12FACTOR_DATA} \
    -v $(pwd):/backup \
    ${DOCKER_IMAGE_SHELL} \
    sh -c 'cd <%= getenv!(:data_directory) %> && tar xvzf /backup/12factor-data.tar.gz'
fi
