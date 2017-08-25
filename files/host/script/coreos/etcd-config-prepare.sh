#!/bin/sh +x
set -e

cp -n \
  "<%= getenv!(:parasite_config_directory) %>/env/etcd-common.env" \
  "<%= getenv!(:parasite_config_directory) %>/env/etcd.env"
