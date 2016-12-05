#!/bin/bash +x
set -e

# Create the profile directory
mkdir -p "/etc/profile.d"

# Install core packages
# command -v apt-get >/dev/null && apt-get update && apt-get -y upgrade && apt-get -y install cloud-init
