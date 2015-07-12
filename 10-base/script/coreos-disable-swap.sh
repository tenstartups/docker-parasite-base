#!/bin/bash +x
set -e

# Check for required environment variables
if [ -z "${SWAP_FILE_SIZE}" ]; then
  echo >&2 "Missing required environment variable SWAP_FILE_SIZE"
  exit 1
fi

# Set environment with defaults
SWAP_FILE="/${SWAP_FILE_SIZE}.swp"

# Disable the swap file
/usr/sbin/swapoff $(/usr/sbin/losetup -j "${SWAP_FILE}" | /bin/cut -d : -f 1)
/usr/sbin/losetup -d $(/usr/sbin/losetup -j "${SWAP_FILE}" | /bin/cut -d : -f 1)
