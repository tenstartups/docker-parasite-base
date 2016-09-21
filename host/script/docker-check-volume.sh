#!/bin/bash +x
set -e

# Set environment
volume_name=$1
permissions=$2
owner=$3

# Exit with error if required environment is not present
[ -z "${volume_name}" ] && echo >&2 "Environment variable volume_name must be provided" && exit 1

# Exit if the volume exists
/usr/bin/docker volume inspect <%= getenv!(:parasite_data_docker_volume) %>-${volume_name} >/dev/null 2>&1 && exit 0

# Create the docker volume
/usr/bin/docker volume create --name <%= getenv!(:parasite_data_docker_volume) %>-${volume_name}

# Set permissions
[ -z "${permissions}" ] || \
  /usr/bin/docker run --rm \
    -v <%= getenv!(:parasite_data_docker_volume) %>-${volume_name}:"<%= getenv!(:parasite_data_directory) %>/${volume_name}" \
    -w "<%= getenv!(:parasite_data_directory) %>/${volume_name}" \
    tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
    chmod ${permissions} .

# Set owner
[ -z "${owner}" ] || \
  /usr/bin/docker run --rm \
    -v <%= getenv!(:parasite_data_docker_volume) %>-${volume_name}:"<%= getenv!(:parasite_data_directory) %>/${volume_name}" \
    -w "<%= getenv!(:parasite_data_directory) %>/${volume_name}" \
    tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
    chown ${owner} .
