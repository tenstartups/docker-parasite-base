#!/bin/bash
set -e

# Cleanup old containers
for container_id in `docker ps -f 'status=exited' | grep -v 'CONTAINER ID' | awk '{ print $1 }'`; do
  docker rm -v ${container_id} || true
done

# Cleanup unused untagged images
for image_id in `docker images -q -f 'dangling=true' | awk '{ print $1 }'`; do
  docker rmi ${image_id} || true
done

# Cleanup Nivaha SHA tagged images
image_names=( nivaha/account-service nivaha/restore-webapp nivaha/restore-website )
for image_name in "${image_names[@]}"; do
  current_id=`docker images | grep "$image_name " | grep " ${STAGE} " | awk '{ print $3 }'`
  for image_id in `docker images | grep "$image_name " | grep -v " $current_id " | awk '{ print $3 }'`; do
    docker rmi ${image_id} || true
  done
done
