#!/bin/bash +x
set -e

# Set environment with defaults
SWAPFILE="${SWAPFILE:-/swapfile}"

# Disable the swapfile
/usr/sbin/swapoff $(/usr/sbin/losetup -j "${SWAPFILE}" | /bin/cut -d : -f 1)
/usr/sbin/losetup -d $(/usr/sbin/losetup -j "${SWAPFILE}" | /bin/cut -d : -f 1)
