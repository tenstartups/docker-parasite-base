#
# CoreOS twelve-factor application initialization and configuration base docker image
#
# http://github.com/tenstartups/coreos-12factor-base-docker
#

FROM tenstartups/alpine-ruby:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Set environment
ENV \
  HOME=/home/12factor \
  RUBYLIB=/home/12factor/lib

# Install packages.
RUN \
  apk --update add git && \
  rm /var/cache/apk/*

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

# Add files to the container.
ONBUILD ADD . /home/12factor

# Dump out the git revision.
ONBUILD RUN \
  mkdir -p ./.git/objects && \
  echo "$(git rev-parse HEAD)" > ./REVISION && \
  rm -rf ./.git
