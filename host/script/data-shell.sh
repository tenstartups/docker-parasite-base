#!/bin/bash +x

/12factor/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
docker run -it --rm \
  --volumes-from ${DOCKER_CONTAINER_12FACTOR_DATA} \
  ${DOCKER_IMAGE_SHELL} \
  bash -c "cd /data && ls -al; exec bash"
