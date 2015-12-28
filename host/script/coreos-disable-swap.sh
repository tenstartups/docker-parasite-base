#!/bin/bash +x
set -e

# Check for required environment variables
if [ -z "${SWAP_FILE}" ]; then
  echo >&2 "Missing required environment variable SWAP_FILE"
  exit 1
fi
if ! [ -f "${SWAP_FILE}" ]; then
  echo >&2 "Missing swap file ${SWAP_FILE}"
  exit 1
fi

# Disable the swap file
swapoff "${SWAP_FILE}"
