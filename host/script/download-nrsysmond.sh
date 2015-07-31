#!/bin/bash +x
set -e

# Set environment with defaults
NRSYSMOND_ARCH=${NRSYSMOND_ARCH:-x64}

# Download and install the latest nrsysmond agent
tempdir="$(mktemp -d)"
pushd "${tempdir}" > /dev/null
/usr/bin/wget -r --no-parent --accept-regex 'newrelic\-sysmond\-[.0-9]+\-linux\.tar\.gz' https://download.newrelic.com/server_monitor/release/
/usr/bin/tar xvzf ./download.newrelic.com/server_monitor/release/newrelic-sysmond-*-linux.tar.gz
cp ./newrelic-sysmond-*-linux/daemon/nrsysmond.${NRSYSMOND_ARCH} /opt/bin/nrsysmond
popd > /dev/null
rm -rf "${tempdir}"
