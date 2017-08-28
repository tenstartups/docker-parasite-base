#!/bin/bash
set -e

MEMBER_NAME=$1

[ -z ${MEMBER_NAME} ] && echo >&2 "Member name must be specified as first argument" && exit 1
echo "Attempting to add member ${MEMBER_NAME} to etcd cluster..."
etcdctl member add ${MEMBER_NAME} https://${MEMBER_NAME}.<%= getenv!(:hostname).split('.')[1..-1].join('.') %>:2380
