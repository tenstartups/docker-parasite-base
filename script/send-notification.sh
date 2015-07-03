#!/bin/bash +x

# Set environment
DOCKER_IMAGE_NAME=tenstartups/notifier:latest

# Pull the image
"/12factor/bin/docker-check-pull" "${DOCKER_IMAGE_NAME}"

# Call the notifier with our without an attachment
if [ -z "${FILE_ATTACHMENT}" ]; then
  docker run --rm \
    --env-file="/12factor/env/docker.env" \
    -e LOGSPOUT=ignore \
    -e MESSAGE="${MESSAGE}" \
    --hostname=notifier.$(hostname) \
    ${DOCKER_IMAGE_NAME} \
    "$@"
else
  docker run --rm \
    --env-file="/12factor/env/docker.env" \
    -v "${FILE_ATTACHMENT}:/tmp/$(basename ${FILE_ATTACHMENT}):ro" \
    -e LOGSPOUT=ignore \
    -e MESSAGE="${MESSAGE}" \
    -e FILE_ATTACHMENT="$(basename ${FILE_ATTACHMENT})" \
    --hostname=notifier.$(hostname) \
    ${DOCKER_IMAGE_NAME} \
    "$@"
fi
