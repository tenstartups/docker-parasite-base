#!/bin/bash +x
set -e

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:<%= getenv!(:data_directory) %> \
  -v /tmp:/tmp \
  ${DOCKER_IMAGE_SHELL} \
  bash -c "rm -rf '/tmp/backup.tar.gz' && cd <%= getenv!(:data_directory) %> && tar cvzf '/tmp/backup.tar.gz' ."
mv "/tmp/backup.tar.gz" "${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}"
