#!/bin/bash
set -e

old_umask=`umask`
umask 0000
(
  flock --exclusive --wait 300 200 || exit 1

  # Cleanup old containers
  for container_id in `docker ps -f 'status=exited' | grep -v 'CONTAINER ID' | awk '{ print $1 }'`; do
    docker rm -v ${container_id} || true
  done

) 200>/tmp/.docker.lockfile
umask $old_umask

old_umask=`umask`
umask 0000
(
  flock --exclusive --wait 300 200 || exit 1

  # Cleanup unused untagged images
  for image_id in `docker images --no-trunc -q -f 'dangling=true' | awk '{ print $1 }'`; do
    docker rmi ${image_id} || true
  done

) 200>/tmp/.docker.lockfile
umask $old_umask
