#!/bin/bash
set -e

# Prevent re-entry into this script
if [ "${DOCKER_CHECK_PULL_ENTRY_COUNT:-0}" -gt 0 ]; then
  exit 0
else
  export DOCKER_CHECK_PULL_ENTRY_COUNT=$((DOCKER_CHECK_PULL_ENTRY_COUNT+1))
fi

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

# Pull the docker image from the registry
old_umask=`umask` && umask 000 && exec 200>/tmp/.docker.lockfile && umask ${old_umask}
if flock --exclusive --wait 300 200; then
  docker pull "${DOCKER_IMAGE_NAME}" | {
    while IFS= read -r line; do
      if [[ ${line} =~ .*Pulling\sfs|layer.* ]] && [ "${notified_new_image}" != "true" ]; then
        echo "Pulling new docker image ${DOCKER_IMAGE_NAME}"
        /opt/bin/send-notification warn "Pulling new docker image \`${DOCKER_IMAGE_NAME}\`"
        notified_new_image=true
      fi
    done
  }
  flock --unlock 200
fi

# Output a message if we have a new image
new_image_id=$(docker images | grep -E "^${repository}\s+${image_tag}\s+" | head | awk '{ print $3 }')
if [ "${new_image_id}" != "${image_id}" ]; then
  echo "Finished pulling new docker image ${DOCKER_IMAGE_NAME} (${new_image_id})"
  /opt/bin/send-notification success "Finished pulling new docker image \`${DOCKER_IMAGE_NAME} (${new_image_id})\`"
fi

# Update the id file if we have a new image
if [ "${new_image_id}" != "`cat ${image_id_file}`" ]; then
  old_umask=`umask` && umask 000
  mkdir -p "$(dirname ${image_id_file})"
  printf ${new_image_id} > "${image_id_file}"
  umask ${old_umask}
fi
