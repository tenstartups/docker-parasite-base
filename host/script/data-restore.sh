#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_PARASITE_DATA}"
/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
if [ -z "$(docker ps --no-trunc -a -q -f label=${DOCKER_CONTAINER_PARASITE_DATA})" ]; then
  docker create \
    --label ${DOCKER_VOLUME_CONTAINER_LABEL} \
    --label ${DOCKER_CONTAINER_PARASITE_DATA/-/_} \
    --volume <%= getenv!(:data_directory) %> \
    --name ${DOCKER_CONTAINER_PARASITE_DATA} \
    ${DOCKER_IMAGE_PARASITE_DATA}
  docker run --rm \
    --volumes-from ${DOCKER_CONTAINER_PARASITE_DATA} \
    -v $(pwd):/backup \
    ${DOCKER_IMAGE_SHELL} \
    sh -c 'cd <%= getenv!(:data_directory) %> && tar xvzf /backup/parasite-data.tar.gz'
fi
