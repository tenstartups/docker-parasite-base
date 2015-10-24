#!/bin/bash
set -e

# Set environment variables
DOCKER_IMAGE_ENV_REGEX="^\s*DOCKER_IMAGE_([_A-Z0-9]+)=(.+)\s*$"

# Cleanup stale containers (excluding containers labeled as volume containers)
volume_container_ids=($(docker ps --no-trunc -a -q -f "label=${DOCKER_VOLUME_CONTAINER_LABEL}"))
for container_id in $(docker ps --no-trunc -a -q -f 'status=created' -f 'status=dead' -f 'status=exited'); do
  if [[ " ${volume_container_ids[*]} " = *" ${container_id} "* ]]; then continue; fi
  old_umask=`umask` && umask 000 && exec 200>/tmp/.docker.lockfile && umask ${old_umask}
  if flock --exclusive --wait 300 200; then
    echo "Removing docker container ${container_id}"
    docker rm -v ${container_id} || true
    flock --unlock 200
    /opt/bin/send-notification success "Removed docker container \`${container_id:0:12}\`"
  fi
done

# Cleanup stale (untagged) images
for image_id in $(docker images --no-trunc -q -f 'dangling=true'); do
  old_umask=`umask` && umask 000 && exec 200>/tmp/.docker.lockfile && umask ${old_umask}
  if flock --exclusive --wait 300 200; then
    echo "Removing docker image ${image_id}"
    docker rmi ${image_id} || true
    flock --unlock 200
    /opt/bin/send-notification success "Removed docker image \`${image_id:0:12}\`"
  fi
done

# Cleanup tagged images that are not itemized in the environment list
active_image_names=($(env | grep -E "${DOCKER_IMAGE_ENV_REGEX}" | sed -E "s/${DOCKER_IMAGE_ENV_REGEX}/\2/" | sort | uniq))
while read -r image_name ; do
  if [[ " ${active_image_names[*]} " = *" ${image_name} "* ]]; then continue; fi
  old_umask=`umask` && umask 000 && exec 200>/tmp/.docker.lockfile && umask ${old_umask}
  if flock --exclusive --wait 300 200; then
    echo "Removing docker image ${image_name}"
    docker rmi ${image_name} || true
    flock --unlock 200
    /opt/bin/send-notification success "Removed docker image \`${image_name}\`"
  fi
done < <(docker images | grep -v "REPOSITORY" | grep -v "<none>" | awk '{print $1 ":" $2}')
