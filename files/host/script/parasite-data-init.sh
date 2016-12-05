#!/bin/bash +x
set -e

# Set environment
parasite_service_name=$1
permissions=$2
owner=$3

# Exit with error if required environment is not present
[ -z "${parasite_service_name}" ] && echo >&2 "Service name must be specified as the first argument" && exit 1

# Exit if the data volume exists
/usr/bin/docker volume inspect <%= getenv!(:parasite_data_docker_volume) %>-${parasite_service_name/_/-} >/dev/null 2>&1 && exit 0

# Create the data docker volume
/usr/bin/docker volume create --name <%= getenv!(:parasite_data_docker_volume) %>-${parasite_service_name/_/-}

# Set permissions on the data volume root
[ -z "${permissions}" ] || \
  /usr/bin/docker run --rm \
    -v <%= getenv!(:parasite_data_docker_volume) %>-${parasite_service_name/_/-}:/tmp/data \
    -w /tmp/data \
    tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
    chmod ${permissions} .

# Set owner
[ -z "${owner}" ] || \
  /usr/bin/docker run --rm \
    -v <%= getenv!(:parasite_data_docker_volume) %>-${parasite_service_name/_/-}:/tmp/data \
    -w /tmp/data \
    tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
    chown ${owner} .
