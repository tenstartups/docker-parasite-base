#!/bin/bash
set -e

# Pull the latest version of all tagged images
docker images | grep -v -e "^<none>" -e "REPOSITORY" | while read -r image_desc ; do
  DOCKER_IMAGE_DESC="$image_desc" "/12factor/bin/docker-check-pull"
done
