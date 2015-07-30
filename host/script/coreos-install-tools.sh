#!/bin/bash +x
set -e

# Execute each of the tools installation scripts in order
find "/12factor/tools.d" -type f | sort | while read f; do "$f"; done
