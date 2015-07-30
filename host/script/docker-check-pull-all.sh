#!/bin/bash
set -e

# Set environment variables
DOCKER_IMAGE_ENV_REGEX="^\s*DOCKER_IMAGE_([_A-Z0-9]+)=(.+)\s*$"

# Pull the latest version of all required images
while read -r docker_image_name ; do
  /12factor/bin/docker-check-pull $docker_image_name
done < <(env | grep -E "${DOCKER_IMAGE_ENV_REGEX}" | sed -E "s/${DOCKER_IMAGE_ENV_REGEX}/\2/" | sort | uniq)
