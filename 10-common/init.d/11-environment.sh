#!/bin/bash
set -e

# Run the environment configuration script to generate consolidated environment
# files for use in systemd services and docker containers
/12factor/bin/environment-config
