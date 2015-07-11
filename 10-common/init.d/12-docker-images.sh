#!/bin/bash
set -e

# Pull all docker images at the start to ensure a smoother initialization
echo "Pre-pulling all required docker images"
systemctl start docker-check-image-update.timer &
echo "Finished pre-pulling all required docker images"
