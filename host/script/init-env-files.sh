#!/bin/bash +x
set -e

# Set environment
ENV_DIR="${ENV_DIR:-<%= config_directory %>/env.d}"
ENV_TARGET_DIR="${ENV_TARGET_DIR:-<%= config_directory %>/env}"
PROFILE_DIR="/etc/profile.d"
ENVIRONMENT_REGEX="^\s*([^#][^=]+)[=](.+)$"

# Wait until docker0 is up and get its ip address
IP_COMMAND="ip addr show docker0 | sed -En 's/^\s*inet\s+(([0-9]{1,3}\.){3}[0-9]{1,3})\/[0-9]+\s+scope\s+global\s+docker0\s*$/\1/p'"
DOCKER0_IP_ADDRESS=$(eval $IP_COMMAND) || true
until [[ ${DOCKER0_IP_ADDRESS} =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; do
  failures=$((failures+1))
  if [ ${failures} -gt 10 ]; then
    echo >&2 "Unable to get docker0 ip address."
    exit 1
  fi
  sleep 5
  DOCKER0_IP_ADDRESS=$(eval $IP_COMMAND) || true
done
DOCKER_HOSTNAME_FULL=$(hostname) # This assumes that /etc/hostname has the FQDN
DOCKER_HOSTNAME=$(IFS=. read host domain <<<"${DOCKER_HOSTNAME_FULL}" && echo ${host})

# Create directories
mkdir -p "${ENV_DIR}"
mkdir -p "${ENV_TARGET_DIR}"
mkdir -p "${PROFILE_DIR}"

# Build a combined environment file for use in docker containers
cat << EOF > "${ENV_TARGET_DIR}/docker.env"
# Do not edit this file.  It is automatically generated by the twelve factor
# initialization process from individual entries in the env.d directory
EOF
temp_file="$(mktemp)"
cat << EOF > "$temp_file"
DOCKER0_IP_ADDRESS=${DOCKER0_IP_ADDRESS}
DOCKER_HOSTNAME=${DOCKER_HOSTNAME}
DOCKER_HOSTNAME_FULL=${DOCKER_HOSTNAME_FULL}
HOST_PUBLIC_IP_ADDRESS=${COREOS_PUBLIC_IPV4}
HOST_PRIVATE_IP_ADDRESS=${COREOS_PRIVATE_IPV4}
EOF
env_files=`find "${ENV_DIR}" -type f -and \( \( -name '*.docker.*' -and -name '*.env' \) -or \( -name '*.env' -and ! -name '*.*.env' \) \) -exec echo {} \;`
cat $temp_file $env_files | grep -E "${ENVIRONMENT_REGEX}" | sort >> "${ENV_TARGET_DIR}/docker.env"
rm -f $temp_file

# Build a combined environment file for use in systemd services
cat << EOF > "${ENV_TARGET_DIR}/systemd.env"
# Do not edit this file.  It is automatically generated by the twelve factor
# initialization process from individual entries in the env.d directory
EOF
temp_file="$(mktemp)"
cat << EOF > "$temp_file"
DOCKER0_IP_ADDRESS=${DOCKER0_IP_ADDRESS}
DOCKER_HOSTNAME=${DOCKER_HOSTNAME}
DOCKER_HOSTNAME_FULL=${DOCKER_HOSTNAME_FULL}
HOST_PUBLIC_IP_ADDRESS=${COREOS_PUBLIC_IPV4}
HOST_PRIVATE_IP_ADDRESS=${COREOS_PRIVATE_IPV4}
EOF
env_files=`find "${ENV_DIR}" -type f -and \( \( -name '*.systemd.*' -and -name '*.env' \) -or \( -name '*.env' -and ! -name '*.*.env' \) \) -exec echo {} \;`
cat $temp_file $env_files | grep -E "${ENVIRONMENT_REGEX}" | sort >> "${ENV_TARGET_DIR}/systemd.env"
rm -f $temp_file

# Build a profile script to export environment variables for bash shells
cat << EOF > "${ENV_TARGET_DIR}/profile.sh"
#!/bin/bash +x
# Do not edit this file.  It is automatically generated by the twelve factor
# initialization process from individual entries in the env.d directory
EOF
temp_file="$(mktemp)"
cat << EOF > "$temp_file"
PATH=\$PATH:/opt/bin
DOCKER0_IP_ADDRESS=${DOCKER0_IP_ADDRESS}
DOCKER_HOSTNAME=${DOCKER_HOSTNAME}
DOCKER_HOSTNAME_FULL=${DOCKER_HOSTNAME_FULL}
HOST_PUBLIC_IP_ADDRESS=${COREOS_PUBLIC_IPV4}
HOST_PRIVATE_IP_ADDRESS=${COREOS_PRIVATE_IPV4}
EOF
env_files=`find "${ENV_DIR}" -type f -and \( \( -name '*.profile.*' -and -name '*.env' \) -or \( -name '*.env' -and ! -name '*.*.env' \) \) -exec echo {} \;`
cat $temp_file $env_files | grep -E "${ENVIRONMENT_REGEX}" | sort | sed -En "s/${ENVIRONMENT_REGEX}/export \1=\"\2\"/p" >> "${ENV_TARGET_DIR}/profile.sh"
rm -f $temp_file
ln -fs "${ENV_TARGET_DIR}/profile.sh" "${PROFILE_DIR}/12factor-env.sh"
