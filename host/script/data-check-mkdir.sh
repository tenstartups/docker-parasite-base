#!/bin/bash +x

# Set environment
DATA_SUBDIRECTORY=$1
PERMISSIONS=${2:-766}
OWNER=${3:-root:root}

# Exit with error if required environment is not present
if [ -z "${DATA_SUBDIRECTORY}" ]; then
  echo >&2 "Environment variable DATA_SUBDIRECTORY must be provided"
  exit 1
fi

/12factor/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  --volumes-from ${DOCKER_CONTAINER_12FACTOR_DATA} \
  ${DOCKER_IMAGE_SHELL} \
  sh -c "mkdir -p ${DATA_SUBDIRECTORY} && chmod ${PERMISSIONS} ${DATA_SUBDIRECTORY} && chown ${OWNER} ${DATA_SUBDIRECTORY}"
