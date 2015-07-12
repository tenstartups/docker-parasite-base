#!/bin/bash +x
set -e

# Set environment with defaults
NRSYSMOND_ARCH=${NRSYSMOND_ARCH:-x64}
NRSYSMOND_CONFIG_FILE="${NRSYSMOND_CONFIG_FILE:-/12factor/conf/newrelic/newrelic-sysmond.conf}"
NRSYSMOND_PID_FILE="${NRSYSMOND_PID_FILE:-/var/run/nrsysmond.pid}"
NRSYSMOND_LOG_FILE="${NRSYSMOND_LOG_FILE:-/var/log/nrsysmond.log}"
NRSYSMOND_LOG_LEVEL=${NRSYSMOND_LOG_LEVEL:-warning}

# Check for required environment variables
if [ -z "${NEWRELIC_LICENSE_KEY}" ]; then
  echo >&2 "Missing required environment variable NEWRELIC_LICENSE_KEY"
  exit 1
fi

# Download and install the latest nrsysmond agent
tempdir="$(mktemp -d)"
pushd "${tempdir}" > /dev/null
/usr/bin/wget -r --no-parent --accept-regex 'newrelic\-sysmond\-[.0-9]+\-linux\.tar\.gz' https://download.newrelic.com/server_monitor/release/
/usr/bin/tar xvzf ./download.newrelic.com/server_monitor/release/newrelic-sysmond-*-linux.tar.gz
cp ./newrelic-sysmond-*-linux/daemon/nrsysmond.${NRSYSMOND_ARCH} /12factor/bin/nrsysmond
popd > /dev/null
rm -rf "${tempdir}"

# Create the configuration file
mkdir -p `dirname "${NRSYSMOND_CONFIG_FILE}"`
cat << EOF > "${NRSYSMOND_CONFIG_FILE}"
logfile = ${NRSYSMOND_LOG_FILE}
loglevel = ${NRSYSMOND_LOG_LEVEL}
pidfile = ${NRSYSMOND_PID_FILE}
license_key = ${NEWRELIC_LICENSE_KEY}
EOF
