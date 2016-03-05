#!/bin/bash +x
set -e

# Set environment
DATA_SUBDIRECTORY=$1
PERMISSIONS=$2
OWNER=$3

# Exit with error if required environment is not present
if [ -z "${DATA_SUBDIRECTORY}" ]; then
  echo >&2 "Environment variable DATA_SUBDIRECTORY must be provided"
  exit 1
fi

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:<%= getenv!(:data_directory) %> \
  ${DOCKER_IMAGE_SHELL} \
  sh -c " \
    mkdir -p ${DATA_SUBDIRECTORY} && \
    if ! [ -z "${PERMISSIONS}" ]; then chmod ${PERMISSIONS} ${DATA_SUBDIRECTORY}; fi && \
    if ! [ -z "${OWNER}" ]; then chown ${OWNER} ${DATA_SUBDIRECTORY}; fi \
  "
