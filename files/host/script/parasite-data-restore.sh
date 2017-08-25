#!/bin/bash +x
set -e

# Exit if the tar file is not present
[ -f "/<%= getenv!(:parasite_data_backup_archive) %>" ] || (
  echo >&2 "No archive file found at /<%= getenv!(:parasite_data_backup_archive) %>" && exit 1
)

/opt/bin/send-notification warn "Restoring parasite data volumes from backup archive"

# Get the data directory names from the legacy parasite data volume
data_volume_names=$(/usr/bin/docker volume ls --quiet | grep "^<%= getenv!(:parasite_data_docker_volume) %>-" | xargs)

# Move existing data into a backup directory
echo "Moving existing parasite data into a backup directory"
for data_volume in ${data_volume_names}; do
  data_directory=${data_volume#<%= getenv!(:parasite_data_docker_volume) %>-}
  /usr/bin/docker run --rm \
    -v ${data_volume}:/tmp/data/${data_directory} \
    -w /tmp/data/${data_directory} \
    -e "backup_dir=.backup_$(date +%Y%m%d%H%M%S)" \
    tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
    sh -c "ls * >/dev/null 2>&1 && mkdir '${backup_dir}' && mv * '${backup_dir}'"
done

# Build the docker command to backup all individual parasite data volumes into a single tar file
tempfile="$(mktemp)"
cat << EOF > "${tempfile}"
/usr/bin/docker run --rm \\
  -v "/<%= getenv!(:parasite_data_backup_archive) %>":/tmp/<%= getenv!(:parasite_data_backup_archive) %> \\
EOF
for data_volume in ${data_volume_names}; do
  data_directory=${data_volume#<%= getenv!(:parasite_data_docker_volume) %>-}
cat << EOF >> "${tempfile}"
  -v <%= getenv!(:parasite_data_docker_volume) %>-${data_directory}:/tmp/data/${data_directory} \\
EOF
done
cat << EOF >> "${tempfile}"
  -w /tmp/data \\
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \\
  tar xvzf "/tmp/<%= getenv!(:parasite_data_backup_archive) %>"
EOF

# Execute then delete the command tempfile
echo "Restoring parasite data from backup archive"
. "${tempfile}"
rm -f "${tempfile}"

/opt/bin/send-notification success "Finished restoring parasite data volumes from backup archive"
