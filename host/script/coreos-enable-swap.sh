#!/bin/bash +x
set -e

# Check for required environment variables
if [ -z "${SWAP_FILE_SIZE}" ]; then
  echo >&2 "Missing required environment variable SWAP_FILE_SIZE"
  exit 1
fi

# Set environment with defaults
SWAP_FILE="/${SWAP_FILE_SIZE}.swp"

# Create and enable the swap file
/usr/bin/fallocate -l ${SWAP_FILE_SIZE} "${SWAP_FILE}"
/usr/bin/chmod 600 "${SWAP_FILE}"
/usr/bin/chattr +C "${SWAP_FILE}"
/usr/sbin/mkswap "${SWAP_FILE}"
/usr/sbin/losetup -f "${SWAP_FILE}"
/usr/sbin/sysctl vm.swappiness=10
/usr/sbin/sysctl vm.vfs_cache_pressure=50
/usr/sbin/swapon $(/usr/sbin/losetup -j ${SWAP_FILE} | /bin/cut -d : -f 1)
