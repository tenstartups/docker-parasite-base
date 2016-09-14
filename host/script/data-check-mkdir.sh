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

/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:<%= getenv!(:parasite_data_directory) %> \
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
  sh -c " \
    mkdir -p ${DATA_SUBDIRECTORY} && \
    if ! [ -z "${PERMISSIONS}" ]; then chmod ${PERMISSIONS} ${DATA_SUBDIRECTORY}; fi && \
    if ! [ -z "${OWNER}" ]; then chown ${OWNER} ${DATA_SUBDIRECTORY}; fi \
  "
