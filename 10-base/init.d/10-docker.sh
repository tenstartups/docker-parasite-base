#!/bin/bash
set -e

# Copy the root docker auth file and create links from all user home directories
# so that we never have docker auth problems running in systemd services
cp -v "/root/.dockercfg" "/12factor/auth/docker.yml"
chmod 644 "/12factor/auth/docker.yml"
ln -fsv "/12factor/auth/docker.yml" "/.dockercfg"
ln -fsv "/12factor/auth/docker.yml" "/home/core/.dockercfg"

# Pre-pull all docker images at the start to ensure a smoother initialization
echo "Pre-pulling all required docker images"
systemctl start docker-check-image-update.service
echo "Finished pre-pulling all required docker images"
