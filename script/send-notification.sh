#!/bin/bash +x
set -e

DOCKER_IMAGE_NAME=tenstartups/notifier:latest

if [ -z "${FILE_ATTACHMENT}" ]; then
  docker run -i --rm \
    --env-file="/var/run/config/environment/docker.env" \
    -e LOGSPOUT=ignore \
    -e NOTIFIER_SERVICES="${NOTIFIER_SERVICES}" \
    -e MESSAGE="${MESSAGE}" \
    --hostname=notifier.${DOCKER_HOSTNAME} \
    ${DOCKER_IMAGE_NAME} \
    "$@"
else
  docker run -i --rm \
    --env-file="/var/run/config/environment/docker.env" \
    -v "${FILE_ATTACHMENT}:/tmp/$(basename ${FILE_ATTACHMENT}):ro" \
    -e LOGSPOUT=ignore \
    -e NOTIFIER_SERVICES="${NOTIFIER_SERVICES}" \
    -e MESSAGE="${MESSAGE}" \
    -e FILE_ATTACHMENT="$(basename ${FILE_ATTACHMENT})" \
    --hostname=notifier.${DOCKER_HOSTNAME} \
    ${DOCKER_IMAGE_NAME} \
    "$@"
fi
