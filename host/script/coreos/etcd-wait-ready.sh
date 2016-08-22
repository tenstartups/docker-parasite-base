#!/bin/bash
set -e

# Set environment
MAX_FAILURES=${1:-$MAX_FAILURES}
MAX_FAILURES=${MAX_FAILURES:-5}

# Wait for etcd service to respond before proceeding
until $(/opt/bin/etcdctl ls >/dev/null 2>&1) ; do
  echo "Waiting for etcd to start responding..."
  failures=$((failures+1))
  if [ ${failures} -gt ${MAX_FAILURES} ]; then
    echo >&2 "Timed-out waiting for etcd to start responding."
    /opt/bin/send-notification error "Timed-out waiting for \`etcd\` to start answering requests."
    exit 1
  fi
  sleep 5
done
echo "Finished waiting etcd is now answering requests."
/opt/bin/send-notification success "Finished waiting \`etcd\` is now answering requests."
