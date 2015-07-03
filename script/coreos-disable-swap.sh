#!/bin/bash +x
set -e

/usr/sbin/swapoff $(/usr/sbin/losetup -j ${SWAPFILE} | /bin/cut -d : -f 1)
/usr/sbin/losetup -d $(/usr/sbin/losetup -j ${SWAPFILE} | /bin/cut -d : -f 1)
