#!/bin/bash +x

# Set environment variables from arguments
TASK_DESC="$1"

# Exit with error if arguments not set
if [ -z "${TASK_DESC}" ]; then
  echo "You must supply a task description as the first argument"
  exit 1
fi

# Shift the task description off the argument stack
shift

# Execute the command and notify based on the return code
"$@"
ret_code=$?
if [ $ret_code -eq 0 ]; then
  /var/run/bin/send-notification success "${TASK_DESC} -> SUCCESS"
else
  /var/run/bin/send-notification error "${TASK_DESC} -> FAIL ($ret_code)"
fi
