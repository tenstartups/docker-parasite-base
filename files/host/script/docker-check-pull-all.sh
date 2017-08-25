#!/bin/sh
set -e

# Pull the latest version of all non-dangling images
for docker_image_name in $(docker images --quiet --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>"); do
  /opt/bin/docker-check-pull ${docker_image_name}
done
