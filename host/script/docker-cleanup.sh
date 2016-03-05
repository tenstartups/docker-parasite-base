#!/bin/bash
set -e

# Set environment variables
DOCKER_IMAGE_ENV_REGEX="^\s*DOCKER_IMAGE_([_A-Z0-9]+)=(.+)\s*$"

# Cleanup non-running containers (excluding those labeled as volume containers)
volume_container_ids=($(docker ps --no-trunc -a -q -f "label=${DOCKER_VOLUME_CONTAINER_LABEL}"))
for container_id in $(docker ps --no-trunc -a -q -f 'status=created' -f 'status=exited'); do
  if [[ " ${volume_container_ids[*]} " = *" ${container_id} "* ]]; then continue; fi
  echo "Removing non-running docker container ${container_id}"
  docker rm -v ${container_id} >/dev/null 2>&1 || true
  if [ -z $(docker inspect --type container --format "{{.Id}}" ${container_id}) 2>/dev/null ]; then
    /opt/bin/send-notification success "Removed non-running docker container \`${container_id:0:12}\`"
  else
    /opt/bin/send-notification error "Failed to remove non-running docker container \`${container_id:0:12}\`"
  fi
done

# Cleanup dead containers
for container_id in $(docker ps --no-trunc -a -q -f 'status=dead'); do
  echo "Removing dead docker container ${container_id}"
  rm -rf "/var/lib/docker/containers/${container_id}"
  rm -rf "/var/lib/docker/overlay/${container_id}-init"
  docker rm -v ${container_id} >/dev/null 2>&1 || true
  if ! [ -d "/var/lib/docker/containers/${container_id}" ] && ! [ -d "/var/lib/docker/overlay/${container_id}-init" ]; then
    /opt/bin/send-notification success "Removed dead docker container \`${container_id:0:12}\`"
  else
    /opt/bin/send-notification error "Failed to remove dead docker container \`${container_id:0:12}\`"
  fi
done

# Cleanup nameless volumes
for volume_id in $(docker volume ls | grep -Ev "^\s*DRIVER\s+VOLUME NAME\s*$" | awk '{print $2}' | grep -E "^\s*[a-fA-F0-9]+\s*$"); do
  echo "Removing docker volume ${volume_id}"
  docker volume rm ${volume_id} >/dev/null 2>&1 || true
  if [ -z $(docker volume inspect --format "{{.Name}}" ${volume_id} 2>/dev/null) ]; then
    /opt/bin/send-notification success "Removed nameless docker volume \`${volume_id:0:12}\`"
  else
    /opt/bin/send-notification error "Failed to remove nameless docker volume \`${volume_id:0:12}\`"
  fi
done

# Cleanup dangling images
for image_id in $(docker images --no-trunc -q -f 'dangling=true' | sed -E "s/^\s*(sha256:)?([a-fA-F0-9]+)\s*$/\2/"); do
  echo "Removing dangling docker image ${image_id}"
  docker rmi ${image_id} >/dev/null 2>&1 || true
  if [ -z $(docker inspect --type image --format "{{.Id}}" ${image_id} | sed -E "s/^\s*(sha256:)?([a-fA-F0-9]+)\s*$/\2/" 2>/dev/null) ]; then
    /opt/bin/send-notification success "Removed dangling docker image \`sha256:${image_id:0:12}\`"
  else
    /opt/bin/send-notification error "Failed to remove dangling docker image \`sha256:${image_id:0:12}\`"
  fi
done

# Remove extraneous tagged images
active_image_names=($(env | grep -E "${DOCKER_IMAGE_ENV_REGEX}" | sed -E "s/${DOCKER_IMAGE_ENV_REGEX}/\2/" | sort | uniq))
while read -r image_name ; do
  if [[ " ${active_image_names[*]} " = *" ${image_name} "* ]]; then continue; fi
  echo "Removing extraneous tagged docker image ${image_name}"
  docker rmi ${image_name} >/dev/null 2>&1 || true
  if [ -z $(docker inspect --type image --format "{{.Id}}" ${image_name}) ]; then
    /opt/bin/send-notification success "Removed extraneous tagged docker image \`${image_name}\`"
  else
    /opt/bin/send-notification error "Failed to remove extraneous tagged docker image \`${image_name}\`"
  fi
done < <(docker images | grep -v "REPOSITORY" | grep -v "<none>" | awk '{print $1 ":" $2}')
