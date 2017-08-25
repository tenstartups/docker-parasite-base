#!/bin/sh +x
set -e

# Get the data directory names from the legacy parasite data volume
data_volume_names=$(/usr/bin/docker volume ls --quiet | grep "^<%= getenv!(:parasite_data_docker_volume) %>-" | xargs)

# Build the docker command to open a shell with all individual parasite data volumes mapped
tempfile="$(mktemp)"
cat << EOF > "${tempfile}"
/usr/bin/docker run -it --rm \\
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
  sh -c "figlet 'Parasite Data' && ls -al && exec bash"
EOF

# Execute then delete the command tempfile
. "${tempfile}"
rm -f "${tempfile}"
