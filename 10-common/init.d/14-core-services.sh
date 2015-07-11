#!/bin/bash
set -e

# Set environment
ENABLE_SWAPFILE=${ENABLE_SWAPFILE:-true}
ENABLE_NEWRELIC_SYSMOND=${ENABLE_NEWRELIC_SYSMOND:-true}
ENABLE_TOOLS_INSTALL=${ENABLE_TOOLS_INSTALL:-true}
ENABLE_DOCKER_UPDATE=${ENABLE_DOCKER_UPDATE:-true}
ENABLE_DOCKER_CLEANUP=${ENABLE_DOCKER_CLEANUP:-true}

# Reload the systemctl daemon to load any new systemd units
systemctl daemon-reload

# Start systemd units
if [ "${ENABLE_SWAPFILE}" = 'true' ]; then
  systemctl start swapfile.service &
fi
if [ "${ENABLE_NEWRELIC_SYSMOND}" = 'true' ]; then
  systemctl start newrelic-sysmond.service &
fi
if [ "${ENABLE_TOOLS_INSTALL}" = 'true' ]; then
  systemctl start tools-install.service &
fi
if [ "${ENABLE_DOCKER_UPDATE}" = 'true' ]; then
  systemctl start docker-check-image-update.timer &
fi
if [ "${ENABLE_DOCKER_CLEANUP}" = 'true' ]; then
  systemctl start docker-cleanup.timer &
fi

# Wait for all services to start
wait
