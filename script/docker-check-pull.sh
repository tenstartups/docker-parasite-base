#!/bin/bash
set -e

# Set environment variables with defaults
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_IMAGE_NAME="${1:-$DOCKER_IMAGE_NAME}"
DOCKER_CONFIG_FILE="${DOCKER_CONFIG_FILE:-$HOME/.dockercfg}"

# Get the full image description if not provided
if [ -z "${DOCKER_IMAGE_DESC}" ]; then
  IFS=: read repository tag <<<"${DOCKER_IMAGE_NAME}"
  tag=${tag:-latest}
  image_desc=$(docker images | head | grep -E -e \"^${image_name}\\s+${image_tag}\\s+\" | awk '{ print $3 }')
else
  image_desc=${DOCKER_IMAGE_DESC}
fi

# Extract the individual components of the image name
repository=$(echo "${image_desc}" | awk '{ print $1 }')
private_registry_host=`echo ${repository} | \
  sed -En 's/^\s*((https?:\/\/)?(([-_A-Za-z0-9]+\.)+([-_A-Za-z0-9]+))\/)?(.+)$/\3/p'`
image_name=`echo ${repository} | \
  sed -En 's/^\s*((https?:\/\/)?(([-_A-Za-z0-9]+\.)+([-_A-Za-z0-9]+))\/)?(.+)$/\6/p'`
image_tag=$(echo "${image_desc}" | awk '{ print $2 }')
image_id=$(echo "${image_desc}" | awk '{ print $3 }')

echo "Checking ${repository}:${image_tag} ($image_id) for newer version..."

# Set the registry auth key and url based on whether it's private or Docker Hub
if [ -z "${private_registry_host}" ]; then
  registry_auth_key="https://index.docker.io/v1/"
  registry_url="${registry_auth_key}repositories"
else
  registry_auth_key="${private_registry_host}"
  registry_url="https://${private_registry_host}/v1/repositories"
fi

# Extract the basic auth token from the docker login config file
auth_token=$(cat "${DOCKER_CONFIG_FILE}" | "${SCRIPT_DIR}/json-parse" | grep \\[\"${registry_auth_key}\",\"auth\"\\] | awk '{print $2}' | awk 'gsub(/["]/, "")')

# Get the remote image id for the given tag
if [ -z "${private_registry_host}" ]; then
  remote_image_id=`wget -qO- --header="Authorization: Basic ${auth_token}" "${registry_url}/${image_name}/tags/${image_tag}" | \
    "${SCRIPT_DIR}/json-parse" | grep '\[0,"id"\]' | awk '{ gsub(/"/, ""); print $2 }'`
else
  remote_image_id=`wget -qO- --header="Authorization: Basic ${auth_token}" "${registry_url}/${image_name}/tags/${image_tag}" | \
    sed -En 's/["]([0-9a-fA-F]+)["]/\1/p' | cut -c 1-12`
fi

# Check if the remote image id is different that what we have locally
if ! [ -z "${remote_image_id}" ] && ! [ -z "${image_id}" ] && ! [[ ${image_id} = ${remote_image_id}* ]]; then
  "${SCRIPT_DIR}/send-notification" info "Downloading newer docker image for ${repository}:${image_tag}"
  "${SCRIPT_DIR}/run-and-notify" "Updating docker image \`${repository}:${image_tag}\` \`(${image_id} => ${remote_image_id})\`" \
    docker pull "${repository}:${image_tag}"
fi
