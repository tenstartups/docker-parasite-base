#!/bin/bash
set -e

# Create a data directory and link it into the 12factor directory
mkdir -p "/data"
mkdir -p "/data/docker/ids" && chmod 777 "/data/docker/ids"
mkdir -p "/data/docker/logs" && chmod 777 "/data/docker/logs"
ln -nfs "/data" "/12factor/data"

# Create required subdirectories
mkdir -p "/12factor/auth"
mkdir -p "/12factor/bin"
mkdir -p "/12factor/conf"
mkdir -p "/12factor/env"
mkdir -p "/12factor/env.d"
mkdir -p "/12factor/script"
mkdir -p "/12factor/unit"

# Copy the root docker auth file and create links from all user home directories
# so that we never have docker auth problems running in systemd services
cp -v "/root/.dockercfg" "/12factor/auth/docker.yml"
chmod 644 "/12factor/auth/docker.yml"
ln -fsv "/12factor/auth/docker.yml" "/.dockercfg"
ln -fsv "/12factor/auth/docker.yml" "/home/core/.dockercfg"

# Create symlinks for all scipts in the bin directory without the .sh extension
# for convenience
find "/12factor/script" -type f -iname "*.sh" | while read f; do
  ln -fsv "$f" "/12factor/bin/`basename ${f%.sh}`"
done

# Create symlinks for all systemd units in the systemd directory
find "/12factor/unit" -type f | while read f; do
  ln -fsv "$f" "/var/run/systemd/system/`basename $f`"
done
