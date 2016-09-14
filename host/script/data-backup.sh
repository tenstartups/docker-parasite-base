#!/bin/bash +x
set -e

/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:<%= getenv!(:parasite_data_directory) %> \
  -v $(pwd):/tmp \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  tenstartups/alpine:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
  tar cvzf "/tmp/<%= getenv!(:parasite_data_backup_archive) %>" --exclude=./.* .
