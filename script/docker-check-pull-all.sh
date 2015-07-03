#!/bin/bash
set -e

# Set environment variables with defaults
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Pull the latest version of all tagged images
docker images | grep -v -e "^<none>" -e "REPOSITORY" | while read -r image_desc ; do
  DOCKER_IMAG_DESC=image_desc "${SCRIPT_DIR}/docker-check-pull"
done
