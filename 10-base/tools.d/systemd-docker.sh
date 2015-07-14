#!/bin/bash +x
set -e

docker run --rm -v /12factor/bin:/opt/bin ${DOCKER_IMAGE_SYSTEMD_DOCKER}
