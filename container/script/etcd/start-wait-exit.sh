#!/bin/sh
set -e

etcd &
pid=$!
sleep 15
kill ${pid}
wait
