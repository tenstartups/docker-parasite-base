#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:<%= getenv!(:parasite_data_directory) %> \
  -v $(pwd):/tmp \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  ${DOCKER_IMAGE_SHELL} \
  tar cvzf "/tmp/${PARASITE_DATA_BACKUP_ARCHIVE}" --exclude=./.* .
