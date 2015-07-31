#!/bin/bash +x

/12factor/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
docker run -it --rm \
  --volumes-from ${DOCKER_CONTAINER_12FACTOR_CONFIG} \
  ${DOCKER_IMAGE_SHELL} \
  sh -c 'cd /12factor && ls -al && exec bash'
