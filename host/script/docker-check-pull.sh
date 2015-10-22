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
  old_umask=`umask` && umask 000
  mkdir -p "$(dirname ${image_id_file})"
  printf ${image_id} > "${image_id_file}"
  cp -pf "${image_id_file}" "${image_id_file}.prev"
  umask ${old_umask}
fi

# Pull the image if necessary
new_image_pulled=false

# Obtain a lock for this section
old_umask=`umask` && umask 000 && exec 200>/tmp/.docker.lockfile && umask ${old_umask}
if flock --exclusive --wait 300 200; then

  # Pull the newer image
  docker pull "${DOCKER_IMAGE_NAME}" > /dev/null
  new_image_id=$(docker images | grep -E "^${repository}\s+${image_tag}\s+" | head | awk '{ print $3 }')

  # Check if we got a new image
  if [ "${new_image_id}" != "${image_id}" ]; then
    new_image_pulled=true
    echo "Pulled new docker image ${DOCKER_IMAGE_NAME} (${image_id} => ${new_image_id})"

    # Dump the new image id to the id file
    old_umask=`umask` && umask 000
    mkdir -p "$(dirname ${image_id_file})"
    [ -f "${image_id_file}" ] && cp -f "${image_id_file}" "${image_id_file}.prev"
    printf ${new_image_id} > "${image_id_file}"
    umask ${old_umask}
  fi
fi

# Send a message
[ "${new_image_pulled}" = "true" ] && /opt/bin/send-notification warn "Pulled new docker image \`${DOCKER_IMAGE_NAME} (${image_id} => ${new_image_id})\`"
