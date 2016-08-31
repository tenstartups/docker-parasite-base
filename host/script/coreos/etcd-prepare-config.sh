#!/bin/bash +x
set -e

echo "Preparing etcd container configuration to use existing data directory..."
cp "<%= getenv!(:parasite_config_directory) %>/env/etcd-common.env" "<%= getenv!(:parasite_config_directory) %>/env/etcd.env"
