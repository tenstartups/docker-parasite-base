#!/bin/bash +x
set -e

# Clear out the existing data volume
/opt/bin/send-notification warn "Deleting existing \`parasite\` data files"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:<%= getenv!(:data_directory) %> \
  -v "${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}":"${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}":ro \
  ${DOCKER_IMAGE_SHELL} \
  sh -c "cd <%= getenv!(:data_directory) %> && rm -rf *"
