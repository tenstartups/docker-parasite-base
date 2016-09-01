#!/bin/bash +x
set -e

# Exit if the tar file is not present
if [ -z "<%= getenv!(:parasite_data_backup_archive) %>" ]; then
  echo >&2 "Missing required environment variable PARASITE_DATA_BACKUP_ARCHIVE"
  exit 1
fi
if ! [ -f "/tmp/<%= getenv!(:parasite_data_backup_archive) %>" ]; then
  echo >&2 "No archive file found at /tmp/<%= getenv!(:parasite_data_backup_archive) %>"
  exit 1
fi

# Source systemd environment variables
. <%= getenv!(:parasite_config_directory) %>/env/docker-images.env

# Move existing data directories into a backup directory
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>" \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  -e "backup_dir=.backup_$(date +%Y%m%d%H%M%S)" \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  sh -c "ls * >/dev/null 2>&1 && mkdir '${backup_dir}' && mv * '${backup_dir}'"

# Load data from a backup tar file if present
/opt/bin/send-notification warn "Restoring \`parasite\` data from backup archive"
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>" \
  -v /tmp:/tmp \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  tar xvzf "/tmp/<%= getenv!(:parasite_data_backup_archive) %>"
/opt/bin/send-notification success "Finished restoring \`parasite\` data from backup archive"
