#!/bin/bash +x

# Make sure we don't get into an endless reentry loop
if [ "${SEND_NOTIFICATION_ENTRY_COUNT:-0}" -gt 0 ]; then
  echo "Send notification entry recursion detected"
  exit 0
else
  export SEND_NOTIFICATION_ENTRY_COUNT=$((SEND_NOTIFICATION_ENTRY_COUNT+1))
fi

# Pull the image
/12factor/bin/docker-check-pull "${DOCKER_IMAGE_NOTIFIER}"

# Call the notifier with our without an attachment
if [ -z "${FILE_ATTACHMENT}" ]; then
  docker run --rm \
    --env-file="/12factor/env/docker.env" \
    -e LOGSPOUT=ignore \
    -e MESSAGE="${MESSAGE}" \
    --hostname=notifier.${DOCKER_HOSTNAME_FULL} \
    ${DOCKER_IMAGE_NOTIFIER} \
    "$@"
else
  docker run --rm \
    --env-file="/12factor/env/docker.env" \
    -v "${FILE_ATTACHMENT}:/tmp/$(basename ${FILE_ATTACHMENT}):ro" \
    -e LOGSPOUT=ignore \
    -e MESSAGE="${MESSAGE}" \
    -e FILE_ATTACHMENT="$(basename ${FILE_ATTACHMENT})" \
    --hostname=notifier.${DOCKER_HOSTNAME_FULL} \
    ${DOCKER_IMAGE_NOTIFIER} \
    "$@"
fi
