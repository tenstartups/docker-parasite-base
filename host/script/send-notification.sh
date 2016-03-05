#!/bin/bash +x

# Prevent re-entry into this script
if [ "${SEND_NOTIFICATION_ENTRY_COUNT:-0}" -gt 0 ]; then
  exit 0
else
  export SEND_NOTIFICATION_ENTRY_COUNT=$((SEND_NOTIFICATION_ENTRY_COUNT+1))
fi

# Set environment
NOTIFIER_SENDER=$(hostname) # This assumes that /etc/hostname has the FQDN
NOTIFIER_SENDER=$(IFS=. read host domain <<<"${NOTIFIER_SENDER}" && echo ${host})

# Call the notifier with our without an attachment
/opt/bin/docker-check-pull "${DOCKER_IMAGE_NOTIFIER}"
if [ -z "${FILE_ATTACHMENT}" ]; then
  /usr/bin/docker run --rm \
    --env-file="<%= getenv!(:config_directory) %>/env/docker.env" \
    -e NOTIFIER_SENDER=${NOTIFIER_SENDER} \
    -e MESSAGE="${MESSAGE}" \
    --net ${DOCKER_BRIDGE_NETWORK_NAME} \
    --hostname=notifier.${DOCKER_HOSTNAME_FULL} \
    ${DOCKER_IMAGE_NOTIFIER} \
    "$@"
else
  /usr/bin/docker run --rm \
    --env-file="<%= getenv!(:config_directory) %>/env/docker.env" \
    -v "${FILE_ATTACHMENT}:/tmp/$(basename ${FILE_ATTACHMENT}):ro" \
    -e NOTIFIER_SENDER=${NOTIFIER_SENDER} \
    -e MESSAGE="${MESSAGE}" \
    -e FILE_ATTACHMENT="$(basename ${FILE_ATTACHMENT})" \
    --net ${DOCKER_BRIDGE_NETWORK_NAME} \
    --hostname=notifier.${DOCKER_HOSTNAME_FULL} \
    ${DOCKER_IMAGE_NOTIFIER} \
    "$@"
fi
