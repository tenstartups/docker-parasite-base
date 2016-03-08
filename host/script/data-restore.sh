#!/bin/bash +x
set -e

# Exit if the tar file is not present
if [ -z "${PARASITE_DATA_BACKUP_ARCHIVE}" ]; then
  echo >&2 "Missing required environment variable PARASITE_DATA_BACKUP_ARCHIVE"
  exit 1
fi
if ! [ -f "/tmp/${PARASITE_DATA_BACKUP_ARCHIVE}" ]; then
  echo >&2 "No archive file found at /tmp/${PARASITE_DATA_BACKUP_ARCHIVE}"
  exit 1
fi

/opt/bin/docker-check-pull "${DOCKER_IMAGE_SHELL}"

# Move existing data directories into a backup directory
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:"<%= getenv!(:data_directory) %>" \
  -w "<%= getenv!(:data_directory) %>" \
  -e "backup_dir=.backup_$(date +%Y%m%d%H%M%S)" \
  ${DOCKER_IMAGE_SHELL} \
  sh -c "ls * >/dev/null 2>&1 && mkdir '${backup_dir}' && mv * '${backup_dir}'"

# Load data from a backup tar file if present
/opt/bin/send-notification warn "Restoring \`parasite\` data from backup archive"
/usr/bin/docker run --rm \
  -v ${DOCKER_VOLUME_PARASITE_DATA}:"<%= getenv!(:data_directory) %>" \
  -v /tmp:/tmp \
  -w "<%= getenv!(:data_directory) %>" \
  ${DOCKER_IMAGE_SHELL} \
  tar xvzf "/tmp/${PARASITE_DATA_BACKUP_ARCHIVE}"
/opt/bin/send-notification success "Finished restoring \`parasite\` data from backup archive"
