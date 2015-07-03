#
# A collection of useful CoreOS scripts packaged into a Docker image
#
# http://github.com/tenstartups/coreos-scripts-docker
#

FROM gliderlabs/alpine:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Define environment.
ENV PATH=$PATH:/coreos-scripts

# Define working directory.
WORKDIR /coreos-scripts

# Add files to the container.
ADD script/ /coreos-scripts/
ADD entrypoint /usr/local/bin/entrypoint

# Define volumes.
VOLUME ["/coreos-scripts"]

# Set the entrypoint script.
ENTRYPOINT ["/usr/local/bin/entrypoint"]
