#!/bin/bash +x
set -e

# Create the profile directory
mkdir -p "/etc/profile.d"

# Download and install docker bash completion
toolbox yum -y install bash-completion wget
toolbox wget "https://raw.githubusercontent.com/docker/docker/master/contrib/completion/bash/docker" -O "/usr/share/bash-completion/completions/docker"
toolbox wget "http://lists.alioth.debian.org/pipermail/bash-completion-devel/attachments/20130628/a7ebb47e/attachment.obj" -O "/usr/share/bash-completion/completions/btrfs"
toolbox cp "/usr/share/bash-completion" "/media/root/var/" -R

# Source the bash_completion script in the profile
echo "source /var/bash-completion/bash_completion" | sudo tee "/etc/profile.d/bash_completion.sh"
