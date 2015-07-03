#!/bin/bash +x
set -e

NRSYSMOND_ARCH=x64

# Download and install the latest nrsysmond agent
TEMPDIR=$(mktemp -d)
pushd "${TEMPDIR}" > /dev/null
wget -r --no-parent --accept-regex 'newrelic\-sysmond\-[.0-9]+\-linux\.tar\.gz' https://download.newrelic.com/server_monitor/release/
tar xvzf ./download.newrelic.com/server_monitor/release/newrelic-sysmond-*-linux.tar.gz
cp ./newrelic-sysmond-*-linux/daemon/nrsysmond.${NRSYSMOND_ARCH} /usr/local/bin/nrsysmond
popd > /dev/null
rm -rf "${TEMPDIR}"

# Create the configuration file
mkdir -p `dirname "${NRSYSMOND_CONFIG_FILE}"`
cat << EOF > "${NRSYSMOND_CONFIG_FILE}"
logfile = /var/log/nrsysmond.log
loglevel = warning
pidfile = /var/run/nrsysmond.pid
license_key = ${NEWRELIC_LICENSE_KEY}
EOF
