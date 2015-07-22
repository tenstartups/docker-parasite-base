#!/bin/bash
set -e

find "/var/lib/docker/containers" -type f -name "*-json.log" | while read logfile; do
  echo "Truncating docker log `basename ${logfile}`"
  truncate -s 0 "${logfile}"
done
