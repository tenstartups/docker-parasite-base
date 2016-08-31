#!/bin/bash +x
set -e

echo "Stopping etcd container service..."
sudo systemctl stop etcdd

/opt/bin/etcd-clear-data

echo "Preparing etcd container configuration to bootstrap a new cluster..."
cp "<%= getenv!(:parasite_config_directory) %>/env/etcd-common.env" "<%= getenv!(:parasite_config_directory) %>/env/etcd.env"
cat "<%= getenv!(:parasite_config_directory) %>/env/etcd-new-cluster.env" >> "<%= getenv!(:parasite_config_directory) %>/env/etcd.env"

echo "Starting etcd container service..."
sudo systemctl start etcdd
