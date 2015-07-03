#!/bin/bash +x
set -e

# Set environment
PROFILE_DIR="/etc/profile.d"

# Create the profile directory
mkdir -p "${PROFILE_DIR}"

# Download and install docker bash completion
/usr/bin/toolbox yum -y install bash-completion wget && \
  toolbox wget https://raw.githubusercontent.com/docker/docker/master/contrib/completion/bash/docker -O /usr/share/bash-completion/completions/docker && \
  toolbox wget http://lists.alioth.debian.org/pipermail/bash-completion-devel/attachments/20130628/a7ebb47e/attachment.obj -O /usr/share/bash-completion/completions/btrfs && \
  toolbox cp /usr/share/bash-completion /media/root/var/ -R

# Source the bash_completion script in an environment config
echo "source /var/bash-completion/bash_completion" > "${PROFILE_DIR}/bash_completion"
chmod a+x "${PROFILE_DIR}/bash_completion"
