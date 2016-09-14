#
# Parasite server initialization and configuration docker image base for CoreOS
#
# http://github.com/tenstartups/parasite-docker
#

FROM tenstartups/alpine:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Set environment
ENV \
  PARASITE_OS=coreos \
  HOME=/home/parasite \
  RUBYLIB=/home/parasite/lib

# Install base packages.
RUN \
  apk --update add ruby ruby-irb ruby-json && \
  rm -rf /var/cache/apk/*

# Install gems.
RUN gem install net_http_unix --no-document

# Set the working directory.
WORKDIR "/home/parasite"

# Add files to the container.
COPY conf.d conf.d
COPY lib lib
COPY entrypoint.rb /docker-entrypoint
# The directory name under the parasite directory must match the name of the conf.d script
COPY host 10-base/host
COPY container 10-base/container

# Set the entrypoint script.
ENTRYPOINT ["/docker-entrypoint"]

# Set the default command
CMD ["/bin/bash"]

# Dump the revision argument to file if present
ONBUILD ARG BUILD_REVISION
ONBUILD RUN echo ${BUILD_REVISION} > ./REVISION
