#!/bin/bash +x
set -e

# Exit with failure if there is no legacy parasite data docker volume
/usr/bin/docker volume inspect <%= getenv!(:parasite_data_docker_volume) %> >/dev/null 2>&1 || (
  echo >&2 "No legacy parasite data volume found" && exit 1
)

# Try to delete the legacy data volume and exit if we've already migrated
[ -f "/parasite-data.migrated" ] && \
  ((/usr/bin/docker volume rm <%= getenv!(:parasite_data_docker_volume) %> >/dev/null 2>&1 && rm -f "/parasite-data.migrated") || true) && \
  exit 0

/opt/bin/send-notification warn "Migrating legacy parasite data volume into individual volumes"

# Get the data directory names from the legacy parasite data volume
data_directory_names=$(
  /usr/bin/docker run --rm \
    -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>" \
    tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
    sh -c "ls -d '<%= getenv!(:parasite_data_directory) %>'/* | sed -E 's/^.+\/(\w+)$/\1/' | xargs"
)

# Create the individual parasite data volumes
for data_directory in ${data_directory_names}; do
  /usr/bin/docker volume create --name <%= getenv!(:parasite_data_docker_volume) %>-${data_directory}
done

# Build the docker command to move data from the legacy volume to the individual volumes
tempfile="$(mktemp)"
cat << EOF > "${tempfile}"
/usr/bin/docker run --rm \\
  -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>-legacy" \\
EOF
for data_directory in ${data_directory_names}; do
cat << EOF >> "${tempfile}"
  -v <%= getenv!(:parasite_data_docker_volume) %>-${data_directory}:"<%= getenv!(:parasite_data_directory) %>/${data_directory}" \\
EOF
done
cat << EOF >> "${tempfile}"
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \\
  sh -c "cp -pRv '<%= getenv!(:parasite_data_directory) %>-legacy/'* '<%= getenv!(:parasite_data_directory) %>/'"
EOF

# Execute then delete the command tempfile
echo "Migrating legacy parasite data to individual volumes"
. "${tempfile}"
rm -f "${tempfile}"

# Mark the legacy parasite data volume for deletion on the next run
touch "/parasite-data.migrated"

/opt/bin/send-notification success "Finished migrating legacy parasite data volume into individual volumes"
