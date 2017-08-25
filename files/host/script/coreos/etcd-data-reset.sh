#!/bin/sh +x
set -e

# Clear the etcd data directory (destructive)
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>-etcd:/var/lib/etcd \
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
  sh -c "cd /var/lib/etcd && rm -rfv proxy && rm -rfv member"
