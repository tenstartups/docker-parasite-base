#!/bin/bash +x
set -e

# Get the config directory names from the legacy parasite config volume
config_volume_names=$(/usr/bin/docker volume ls --quiet | grep "^<%= getenv!(:parasite_config_docker_volume) %>-" | xargs)

# Build the docker command to open a shell with all individual parasite config volumes mapped
tempfile="$(mktemp)"
cat << EOF > "${tempfile}"
/usr/bin/docker run -it --rm \\
EOF
for config_volume in ${config_volume_names}; do
  config_directory=${config_volume#<%= getenv!(:parasite_config_docker_volume) %>-}
cat << EOF >> "${tempfile}"
  -v <%= getenv!(:parasite_config_docker_volume) %>-${config_directory}:/tmp/config/${config_directory} \\
EOF
done
cat << EOF >> "${tempfile}"
  -w /tmp/config \\
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \\
  sh -c "figlet 'Parasite Config' && ls -al && exec bash"
EOF

# Execute then delete the command tempfile
. "${tempfile}"
rm -f "${tempfile}"
