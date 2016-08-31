#!/bin/bash +x
set -e

echo "Stopping etcd service..."
systemctl stop etcd

echo "Clearing existing etcd state data..."
/opt/bin/etcd-data-reset

echo "Preparing etcd configuration to join existing cluster as member..."
rm -f "<%= getenv!(:parasite_config_directory) %>/env/etcd.env"
/opt/bin/etcd-config-reset
cat \
  "<%= getenv!(:parasite_config_directory) %>/env/etcd-member.env" >> \
  "<%= getenv!(:parasite_config_directory) %>/env/etcd.env"

echo "Starting etcd service..."
systemctl start etcd
