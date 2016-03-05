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
image_sha=$(docker inspect --type image --format "{{.Config.Image}}" ${repository}:${image_tag} | sed -E "s/^\s*(sha256:)?([a-fA-F0-9]+)\s*$/\2/" 2>/dev/null || true)

# Update the docker image name to include tag if it didn't have it
DOCKER_IMAGE_NAME="${repository}:${image_tag}"

# Generate an id file for downstream actions to trigger off of when changed
image_sha_file="<%= getenv!(:config_directory) %>/docker/${DOCKER_IMAGE_NAME//\//-DOCKERSLASH-}.id"
if ! [ -z "${image_sha}" ] && ! [ -f "${image_sha_file}" ]; then
  old_umask=`umask` && umask 000
  mkdir -p "$(dirname ${image_sha_file})"
  printf "${image_sha}" > "${image_sha_file}"
  umask ${old_umask}
fi

# Pull the docker image from the registry
docker pull "${DOCKER_IMAGE_NAME}" | {
  while IFS= read -r line; do
    if [[ ${line} =~ :\ .*Pulling\ fs\ layer.* ]] && [ "${notified_new_image}" != "true" ]; then
      echo "Pulling new docker image ${DOCKER_IMAGE_NAME}"
      /opt/bin/send-notification warn "Pulling new docker image \`${DOCKER_IMAGE_NAME}\`"
      notified_new_image=true
    fi
  done
}

# Output a message if we have a new image
new_image_sha=$(docker inspect --type image --format "{{.Config.Image}}" ${repository}:${image_tag} | sed -E "s/^\s*(sha256:)?([a-fA-F0-9]+)\s*$/\2/" 2>/dev/null || true)
if [ "${new_image_sha}" != "${image_sha}" ]; then
  echo "Finished pulling new docker image ${DOCKER_IMAGE_NAME} (${new_image_sha})"
  /opt/bin/send-notification success "Finished pulling new docker image \`${DOCKER_IMAGE_NAME} (sha256:${new_image_sha:0:12})\`"
fi

# Update the id file if we have a new image
if ! [ -f "${image_sha_file}" ] || [ "${new_image_sha}" != "`cat ${image_sha_file}`" ]; then
  old_umask=`umask` && umask 000
  mkdir -p "$(dirname ${image_sha_file})"
  printf "${new_image_sha}" > "${image_sha_file}"
  umask ${old_umask}
fi
