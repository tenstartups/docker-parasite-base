#!/bin/bash
set -e

old_umask=`umask`
umask 0000
(
  flock --exclusive --wait 300 200 || exit 1

  # Cleanup old non-data containers
  data_container_ids=($(docker ps --no-trunc -a -q -f 'label=data'))
  for container_id in $(docker ps --no-trunc -a -q -f 'status=exited'); do
    if [[ " ${data_container_ids[*]} " = *" ${container_id} "* ]]; then continue; fi
    docker rm -v ${container_id} || true
  done

) 200>/tmp/.docker.lockfile
umask $old_umask

old_umask=`umask`
umask 0000
(
  flock --exclusive --wait 300 200 || exit 1

  # Cleanup unused untagged images
  for image_id in $(docker images --no-trunc -q -f 'dangling=true'); do
    docker rmi ${image_id} || true
  done

) 200>/tmp/.docker.lockfile
umask $old_umask
