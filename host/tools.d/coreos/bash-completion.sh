#!/bin/bash +x
set -e

# Download and install docker bash completion
toolbox dnf -y install bash-completion wget
toolbox wget "https://raw.githubusercontent.com/docker/docker/master/contrib/completion/bash/docker" -O "/usr/share/bash-completion/completions/docker"
toolbox cp -R "/usr/share/bash-completion" "/media/root/var/"

# Source the bash completion script in the profile
mkdir -p "/etc/profile.d"
echo "source /var/bash-completion/bash_completion" | sudo tee "/etc/profile.d/bash_completion.sh"
