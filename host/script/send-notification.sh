#!/bin/bash +x

# Make sure we don't get into an endless reentry loop
if [ "${SEND_NOTIFICATION_ENTRY_COUNT:-0}" -gt 0 ]; then
  echo "Send notification entry recursion detected"
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
  docker run --rm \
    --env-file="<%= get(:config_directory) %>/env/docker.env" \
    -e LOGSPOUT=ignore \
    -e NOTIFIER_SENDER=${NOTIFIER_SENDER} \
    -e MESSAGE="${MESSAGE}" \
    --hostname=notifier.${DOCKER_HOSTNAME_FULL} \
    ${DOCKER_IMAGE_NOTIFIER} \
    "$@"
else
  docker run --rm \
    --env-file="<%= get(:config_directory) %>/env/docker.env" \
    -v "${FILE_ATTACHMENT}:/tmp/$(basename ${FILE_ATTACHMENT}):ro" \
    -e LOGSPOUT=ignore \
    -e NOTIFIER_SENDER=${SENDER} \
    -e MESSAGE="${MESSAGE}" \
    -e FILE_ATTACHMENT="$(basename ${FILE_ATTACHMENT})" \
    --hostname=notifier.${DOCKER_HOSTNAME_FULL} \
    ${DOCKER_IMAGE_NOTIFIER} \
    "$@"
fi
