#!/bin/bash
set -e

# Cleanup dangling volumes
for volume_id in $(docker volume ls --quiet --filter 'dangling=true' | grep -E "^\s*[a-fA-F0-9]+\s*$"); do
  echo "Removing dangling docker volume ${volume_id:0:12}"
  docker volume rm ${volume_id} >/dev/null 2>&1 || true
  if [ -z $(docker volume inspect --format "{{.Name}}" ${volume_id} >/dev/null 2>&1) ]; then
    /opt/bin/send-notification success "Removed nameless docker volume \`${volume_id:0:12}\`"
  else
    /opt/bin/send-notification error "Failed to remove nameless docker volume \`${volume_id:0:12}\`"
  fi
done

# Cleanup non-running containers
for container_id in $(docker ps --no-trunc --quiet --all --filter 'status=created' --filter 'status=exited' --filter 'status=dead'); do
  echo "Removing non-running docker container ${container_id:0:12}"
  docker rm --force --volumes ${container_id} >/dev/null 2>&1 || true
  if [ -z $(docker inspect --type container --format "{{.Id}}" ${container_id} >/dev/null 2>&1) ]; then
    /opt/bin/send-notification success "Removed non-running docker container \`${container_id:0:12}\`"
  else
    /opt/bin/send-notification error "Failed to remove non-running docker container \`${container_id:0:12}\`"
  fi
done

# Cleanup dangling images
for image_id in $(docker images --no-trunc --quiet --filter 'dangling=true' --format "{{.ID}}"); do
  echo "Removing dangling docker image ${image_id:0:19}"
  docker rmi --force ${image_id} >/dev/null 2>&1 || true
  if [ -z $(docker inspect --type image --format "{{.Id}}" ${image_id} >/dev/null 2>&1) ]; then
    /opt/bin/send-notification success "Removed dangling docker image \`${image_id:0:19}\`"
  else
    /opt/bin/send-notification error "Failed to remove dangling docker image \`${image_id:0:19}\`"
  fi
done
