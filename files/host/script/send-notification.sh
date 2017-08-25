#!/bin/sh +x
set -e

# Exit if we don't have a configuration file
if ! [ -f "<%= getenv!(:parasite_config_directory) %>/env/notifier.env" ]; then
  echo "Cannot send notifications without environment file (<%= getenv!(:parasite_config_directory) %>/env/notifier.env)"
  exit 0
fi

# Set environment
NOTIFIER_SENDER=$(hostname) # This assumes that /etc/hostname has the FQDN
NOTIFIER_SENDER=$(IFS=. read host domain <<<"${NOTIFIER_SENDER}" && echo ${host})

# Call the notifier with our without an attachment
{
  if [ -z "${FILE_ATTACHMENT}" ]; then
    /usr/bin/docker run --rm \
      --env-file "<%= getenv!(:parasite_config_directory) %>/env/notifier.env" \
      -e NOTIFIER_SENDER=${NOTIFIER_SENDER} \
      -e MESSAGE="${MESSAGE}" \
      tenstartups/notifier:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
      "$@"
  else
    /usr/bin/docker run --rm \
      --env-file "<%= getenv!(:parasite_config_directory) %>/env/notifier.env" \
      -v "${FILE_ATTACHMENT}:/tmp/$(basename ${FILE_ATTACHMENT}):ro" \
      -e NOTIFIER_SENDER=${NOTIFIER_SENDER} \
      -e MESSAGE="${MESSAGE}" \
      -e FILE_ATTACHMENT="$(basename ${FILE_ATTACHMENT})" \
      tenstartups/notifier:<%= choose!(:parasite_os, coreos: 'latest', hypriotos: 'armhf') %> \
      "$@"
  fi

} || true
