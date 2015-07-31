#!/bin/bash +x

/12factor/bin/docker-check-pull "${DOCKER_IMAGE_12FACTOR_DATA}"
/12factor/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
if [ -z "$(docker ps --no-trunc -a -q -f label=${DOCKER_CONTAINER_12FACTOR_DATA})" ]; then
  docker run \
    --label ${DOCKER_VOLUME_CONTAINER_LABEL} \
    --label ${DOCKER_CONTAINER_12FACTOR_DATA} \
    --volume /data \
    --name ${DOCKER_CONTAINER_12FACTOR_DATA} \
    ${DOCKER_IMAGE_12FACTOR_DATA}
  docker run --rm \
    --volumes-from ${DOCKER_CONTAINER_12FACTOR_DATA} \
    ${DOCKER_IMAGE_SHELL} \
    bash -c 'cd /data; mkdir sockets; tar xvzf /backup/12factor-data.tar.gz'
fi
