#!/bin/bash
set -e

# Set environment variables with defaults
DOCKER_IMAGE_NAME="${1:-$DOCKER_IMAGE_NAME}"

# Extract the individual values based on whether we have an image name of description
if [ -z "${DOCKER_IMAGE_NAME}" ]; then
  echo >&2 "You must provide DOCKER_IMAGE_NAME as an envrionment variable or the first argument to this script."
  exit 1
fi

# Parse the image name into its parts
# ex. "tenstartups/coreos-parasite-init:latest"
IFS=: read repository image_tag <<<"${DOCKER_IMAGE_NAME}"
image_tag=${image_tag:-latest}
image_id=$(docker images | grep -E "^${repository}\s+${image_tag}\s+" | head | awk '{ print $3 }')

# Update the docker image name to include tag if it didn't have it
DOCKER_IMAGE_NAME="${repository}:${image_tag}"

# Generate an id file for downstream actions to trigger off of when changed
image_id_file="<%= getenv!(:config_directory) %>/docker/${DOCKER_IMAGE_NAME//\//-DOCKERSLASH-}.id"
if ! [ -z "${image_id}" ] && ! [ -f "${image_id_file}" ]; then
  mkdir -p "$(dirname ${image_id_file})"
  printf ${image_id} > "${image_id_file}"
  cp -f "${image_id_file}" "${image_id_file}.prev"
fi

# Extract the private registry host and normalize the repository name
private_registry_host=`echo ${repository} | \
  sed -En 's/^\s*((https?:\/\/)?(([-_A-Za-z0-9]+\.)+([-_A-Za-z0-9]+))\/)?(.+)$/\3/p'`
repository=`echo ${repository} | \
  sed -En 's/^\s*((https?:\/\/)?(([-_A-Za-z0-9]+\.)+([-_A-Za-z0-9]+))\/)?(.+)$/\6/p'`

# Set the registry auth key and url based on whether it's private or Docker Hub
if [ -z "${private_registry_host}" ]; then
  registry_auth_key="https://index.docker.io/v1/"
  registry_url="${registry_auth_key}repositories"
else
  registry_auth_key="${private_registry_host}"
  registry_url="https://${private_registry_host}/v1/repositories"
fi

# Extract the basic auth token from the docker login config file
[ -f "/root/.docker/config.json" ] && \
  auth_token=$(cat "/root/.docker/config.json" | "/opt/bin/json-parse" 2>/dev/null | grep \\[\"${registry_auth_key}\",\"auth\"\\] | awk '{ print $2 }' | awk 'gsub(/["]/, "")')
# Legacy configuration file (pre Docker 1.7)
[ -f "/root/.dockercfg" ] && \
  auth_token=$(cat "/home/core/.dockercfg" | "/opt/bin/json-parse" 2>/dev/null | grep \\[\"${registry_auth_key}\",\"auth\"\\] | awk '{ print $2 }' | awk 'gsub(/["]/, "")')

# Get the remote image id for the given tag
if [ -z "${private_registry_host}" ]; then
  remote_image_id=`wget -qO- --header="Authorization: Basic ${auth_token}" "${registry_url}/${repository}/tags/${image_tag}" | \
    "/opt/bin/json-parse" 2>/dev/null | grep '\[0,"id"\]' | awk '{ gsub(/"/, ""); print $2 }'`
else
  remote_image_id=`wget -qO- --header="Authorization: Basic ${auth_token}" "${registry_url}/${repository}/tags/${image_tag}" | \
    sed -En 's/["]([0-9a-fA-F]+)["]/\1/p' | cut -c 1-12`
fi

# Check if the image id has changed
if ! [ -z ${remote_image_id} ]; then
  if [ -z ${image_id} ]; then
    echo "Missing docker image ${DOCKER_IMAGE_NAME} (${remote_image_id})"
    pull_image=true
  elif ! [[ ${image_id} = ${remote_image_id}* ]]; then
    echo "Outdated docker image ${DOCKER_IMAGE_NAME} (${image_id} => ${remote_image_id})"
    pull_image=true
  fi
fi

# Pull the image if necessary
if [ "$pull_image" = "true" ]; then
  old_umask=`umask`
  umask 0000
  (
    echo "Pulling docker image ${DOCKER_IMAGE_NAME} (${remote_image_id})"
    /opt/bin/send-notification warn "Pulling docker image \`${DOCKER_IMAGE_NAME} (${remote_image_id})\`"
    flock --exclusive --wait 300 200 || exit 1

    # Pull the newer image
    docker pull "${DOCKER_IMAGE_NAME}"

    # Dump the new image id to the id file
    mkdir -p "$(dirname ${image_id_file})"
    if [ -f "${image_id_file}" ]; then
      cp -f "${image_id_file}" "${image_id_file}.prev"
    fi
    printf ${remote_image_id} > "${image_id_file}"

    echo "Finished pulling docker image ${DOCKER_IMAGE_NAME} (${remote_image_id})"
    /opt/bin/send-notification success "Finished pulling docker image \`${DOCKER_IMAGE_NAME} (${remote_image_id})\`"
  ) 200>/tmp/.docker.lockfile
  umask $old_umask
fi
