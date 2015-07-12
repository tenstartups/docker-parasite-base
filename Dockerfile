#
# CoreOS twelve-factor application initialization and configuration docker image
#
# http://github.com/tenstartups/coreos-12factor-init-docker
#

FROM tenstartups/alpine-ruby:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Set environment
ENV \
  HOME=/home/12factor \
  RUBYLIB=/home/12factor/lib

# Set the working directory.
WORKDIR "/home/12factor"

# Add files to the container.
ADD . /home/12factor

# Define volumes.
VOLUME ["/12factor"]

# Set the entrypoint script.
ENTRYPOINT ["/home/12factor/entrypoint"]

# Set the default command
CMD ["/bin/bash"]
