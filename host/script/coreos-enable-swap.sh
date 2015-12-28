#!/bin/bash +x
set -e

# Check for required environment variables
if [ -z "${SWAP_FILE}" ]; then
  echo >&2 "Missing required environment variable SWAP_FILE"
  exit 1
fi
if [ -z "${SWAP_SIZE_MB}" ]; then
  echo >&2 "Missing required environment variable SWAP_SIZE_MB"
  exit 1
fi

# Create and enable the swap file
mkdir -p "`dirname ${SWAP_FILE}`"
[ -f "${SWAP_FILE}" ] && \
  [ $((`stat -c%s "${SWAP_FILE}"` / 1024 / 1024)) != ${SWAP_SIZE_MB} ] && \
  echo "Removing old swap file" && \
  rm -rf "${SWAP_FILE}"
fallocate -l ${SWAP_SIZE_MB}m "${SWAP_FILE}"
chmod 600 "${SWAP_FILE}"
mkswap "${SWAP_FILE}"
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
swapon "${SWAP_FILE}"
