#!/bin/bash +x
set -e

# Set environment
ENV_TARGET_DIR="${ENV_TARGET_DIR:-/12factor/env}"
ENV_SOURCE_DIR="${ENV_SOURCE_DIR:-/12factor/env.d}"
ENVIRONMENT_REGEX="^\s*([^#][^=]+)[=](.+)$"

# Wait until docker0 is up and get its ip address
IP_COMMAND="ip addr show docker0 | sed -En 's/^\s*inet\s+(([0-9]{1,3}\.){3}[0-9]{1,3})\/[0-9]+\s+scope\s+global\s+docker0\s*$/\1/p'"
DOCKER_HOST_IP=$(eval $IP_COMMAND) || true
until [[ ${DOCKER_HOST_IP} =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; do
  sleep 1
  DOCKER_HOST_IP=$(eval $IP_COMMAND) || true
done

# Create directories
mkdir -p "${ENV_SOURCE_DIR}"
mkdir -p "${ENV_TARGET_DIR}"
mkdir -p "/etc/profile.d"

# Build a combined environment file for use in docker containers
cat << EOF > "${ENV_TARGET_DIR}/docker.env.tmp"
DOCKER_HOST_IP=${DOCKER_HOST_IP}
DOCKER_HOSTNAME=$(hostname)
EOF
find "${ENV_SOURCE_DIR}" -type f -name '*.env' -exec sh -c "cat '{}' >> '${ENV_TARGET_DIR}/docker.env.tmp'" \;
mv "${ENV_TARGET_DIR}/docker.env.tmp" "${ENV_TARGET_DIR}/docker.env"

# Build a combined environment file for use in systemd services
cat << EOF > "${ENV_TARGET_DIR}/systemd.env.tmp"
PATH=${PATH}:/12factor/bin
DOCKER_HOST_IP=${DOCKER_HOST_IP}
DOCKER_HOSTNAME=$(hostname)
EOF
find "${ENV_SOURCE_DIR}" -type f -name '*.env' -exec sh -c "cat '{}' >> '${ENV_TARGET_DIR}/systemd.env.tmp'" \;
mv "${ENV_TARGET_DIR}/systemd.env.tmp" "${ENV_TARGET_DIR}/systemd.env"

# Build a profile script to export environment variables for bash shells
cat << EOF > "/etc/profile.d/12factor-env.sh"
#!/bin/bash +x
EOF
grep -E "${ENVIRONMENT_REGEX}" "${ENV_TARGET_DIR}/systemd.env" | while read -r line ; do
  env_name=`echo ${line} | sed -En "s/${ENVIRONMENT_REGEX}/\1/p"`
  env_value=`echo ${line} | sed -En "s/${ENVIRONMENT_REGEX}/\2/p"`
  echo "export ${env_name}='${env_value}'" >> "/etc/profile.d/12factor-env.sh"
done
