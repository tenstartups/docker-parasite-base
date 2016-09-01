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

# Source systemd environment variables
. <%= getenv!(:parasite_config_directory) %>/env/parasite-host.env

/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:<%= getenv!(:parasite_data_directory) %> \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  sh -c " \
    mkdir -p ${DATA_SUBDIRECTORY} && \
    if ! [ -z "${PERMISSIONS}" ]; then chmod ${PERMISSIONS} ${DATA_SUBDIRECTORY}; fi && \
    if ! [ -z "${OWNER}" ]; then chown ${OWNER} ${DATA_SUBDIRECTORY}; fi \
  "
