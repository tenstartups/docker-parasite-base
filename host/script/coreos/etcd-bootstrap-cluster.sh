#!/bin/bash +x
set -e

echo "Stopping etcd container service..."
sudo systemctl stop etcdd

/opt/bin/etcd-clear-data

echo "Bootstrapping a new etcd container cluster..."
/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_config_docker_volume) %>:"<%= getenv!(:parasite_config_directory) %>" \
  -v <%= getenv!(:parasite_data_docker_volume) %>:"<%= getenv!(:parasite_data_directory) %>" \
  -v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
  --env-file "<%= getenv!(:parasite_config_directory) %>/env/etcd.env" \
  --env ETCD_DISCOVERY=$(curl --silent https://discovery.etcd.io/new?size=1) \
  --net <%= getenv!(:parasite_docker_bridge_network) %> \
  ${PARASITE_DOCKER_IMAGE_ETCD} \
  "<%= getenv!(:parasite_config_directory) %>/script/etcd/start-wait-exit.sh"

echo "Starting etcd container service..."
sudo systemctl start etcdd
