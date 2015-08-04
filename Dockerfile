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

# Set the working directory.
WORKDIR "/home/12factor"

# Add files to the container.
COPY conf.d conf.d
COPY lib lib
COPY docker-entrypoint.rb /entrypoint
# The directory name under 12factor must match the name of the conf.d script
COPY host 10-base/host

# Set the entrypoint script.
ENTRYPOINT ["/entrypoint"]

# Set the default command
CMD ["/bin/bash"]

# Dump out the git revision.
ONBUILD COPY .git/HEAD .git/HEAD
ONBUILD COPY .git/refs/heads .git/refs/heads
ONBUILD RUN \
  cat ".git/$(cat .git/HEAD 2>/dev/null | sed -E 's/ref: (.+)/\1/')" 2>/dev/null > ./REVISION && \
  rm -rf ./.git
