#
# CoreOS twelve-factor application initialization and configuration docker image
#
# http://github.com/tenstartups/coreos-12factor-init-docker
#

FROM alpine:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Set environment variables.
ENV TERM=xterm-color

# Install packages.
RUN \
  apk --update add bash curl nano wget && \
  rm /var/cache/apk/*

# Set the working directory.
WORKDIR "/data"

# Add files to the container.
ADD . /data

# Define volumes.
VOLUME ["/12factor"]

# Set the entrypoint script.
ENTRYPOINT ["/data/entrypoint"]

# Set the default command
CMD ["/bin/bash"]
