#!/bin/bash
set -e

# Set environment variables with defaults
DOCKER_IMAGE_NAME="${1:-$DOCKER_IMAGE_NAME}"

# Extract the individual values based on whether we have an image name of description
if ! [ -z "${DOCKER_IMAGE_NAME}" ]; then
  # ex. "tenstartups/coreos-12factor-init:latest"
  IFS=: read repository image_tag <<<"${DOCKER_IMAGE_NAME}"
  image_tag=${image_tag:-latest}
  image_id=$(docker images | grep -E "^${repository}\s+${image_tag}\s+" | head | awk '{ print $3 }')
elif ! [ -z "${DOCKER_IMAGE_DESC}" ]; then
  # ex. "tenstartups/coreos-12factor-init  latest  fa6ac343e5c1  About an hour ago  10.17 MB"
  repository=$(echo "${DOCKER_IMAGE_DESC}" | awk '{ print $1 }')
  image_tag=$(echo "${DOCKER_IMAGE_DESC}" | awk '{ print $2 }')
  image_id=$(echo "${DOCKER_IMAGE_DESC}" | awk '{ print $3 }')
else
  echo "You must provide either DOCKER_IMAGE_NAME or DOCKER_IMAGE_DESC envrionment variable."
  exit 1
fi

# Update the docker image name
DOCKER_IMAGE_NAME="${repository}:${image_tag}"

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
auth_token=$(cat "${HOME}/.dockercfg" | "/12factor/bin/json-parse" | grep \\[\"${registry_auth_key}\",\"auth\"\\] | awk '{print $2}' | awk 'gsub(/["]/, "")')

# Get the remote image id for the given tag
if [ -z "${private_registry_host}" ]; then
  remote_image_id=`wget -qO- --header="Authorization: Basic ${auth_token}" "${registry_url}/${repository}/tags/${image_tag}" | \
    "/12factor/bin/json-parse" | grep '\[0,"id"\]' | awk '{ gsub(/"/, ""); print $2 }'`
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
    echo "Pulling docker image ${DOCKER_IMAGE_NAME}"
    # /12factor/bin/send-notification info "Pulling docker image \`${DOCKER_IMAGE_NAME}\`"
    flock --exclusive --wait 300 200 || exit 1

    # Pull the newer image
    docker pull "${DOCKER_IMAGE_NAME}"

    # Generate a filename to dump the image id to on update, which can be used to
    # trigger actions on image changes
    image_id_file="/data/docker/ids/${DOCKER_IMAGE_NAME//\//-DOCKERSLASH-}"

    # Dump the image id atomically to file
    printf $remote_image_id > "$image_id_file.tmp"
    rsync --remove-source-files --checksum --chmod=a+rw "$image_id_file.tmp" "$image_id_file"

    echo "Pullied docker image ${DOCKER_IMAGE_NAME} (${remote_image_id})"
    # /12factor/bin/send-notification success "Pulled docker image \`${DOCKER_IMAGE_NAME} (${remote_image_id})\`"
  ) 200>/tmp/.docker.lockfile
  umask $old_umask
fi
