#!/bin/bash +x
set -e

# Exit if the tar file is not present
if [ -z "${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}" ]; then
  echo >&2 "Missing required environment variable DOCKER_PARASITE_DATA_BACKUP_ARCHIVE"
  exit 1
fi
if ! [ -f "${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}" ]; then
  echo >&2 "No archive file found at ${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}"
  exit 1
fi

# Delete the existing volume data
/opt/bin/data-delete

# Load data from a backup tar file if present
/opt/bin/send-notification warn "Restoring \`parasite\` data from backup archive"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:<%= getenv!(:data_directory) %> \
  -v "${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}":"${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}":ro \
  ${DOCKER_IMAGE_SHELL} \
  sh -c "cd <%= getenv!(:data_directory) %> && tar xvzf '${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}'"
/opt/bin/send-notification success "Finished restoring \`parasite\` data from backup archive"

# Rename the tar file to indicate we have loaded the data
mv "${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}" "${DOCKER_PARASITE_DATA_BACKUP_ARCHIVE}.restored"
