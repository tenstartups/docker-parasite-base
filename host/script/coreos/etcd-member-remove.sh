#!/bin/bash +x
set -e

MEMBER_NAME=$1

[ -z ${MEMBER_NAME} ] && echo >&2 "Member name must be specified as first argument" && exit 1
echo "Attempting to remove member ${MEMBER_NAME} from etcd cluster..."
member_id=$(etcdctl member list | grep -e ": name=${MEMBER_NAME} " -e "\[unstarted\]: peerURLs=https://${MEMBER_NAME}.<%= getenv!(:hostname).split('.')[1..-1].join('.') %>:2380" | sed -E 's/([0-9a-f]+)(\[unstarted\])?:.*/\1/')
[ -z ${member_id} ] && echo >&2 "Unable to get member id for ${MEMBER_NAME}" && exit 1
etcdctl member remove ${member_id}
