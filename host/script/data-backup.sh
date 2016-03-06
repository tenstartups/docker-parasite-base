#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:<%= getenv!(:data_directory) %> \
  -v $(pwd):/tmp \
  ${DOCKER_IMAGE_SHELL} \
  bash -c "cd '<%= getenv!(:data_directory) %>' && tar cvzf '/tmp/${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}' ."
