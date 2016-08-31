#!/bin/bash +x
set -e

MEMBER_NAME=$1

[ -z ${MEMBER_NAME} ] && echo "Member name must be specified as first argument" && exit 1
echo "Attempting to remove member ${MEMBER_NAME} from etcd container cluster..."
member_id=$(etcdctl member list | grep ": name=${MEMBER_NAME} " | sed -E 's/([0-9a-f]+):.*/\1/')
[ -z ${member_id} ] && echo "Unable to get member id for ${MEMBER_NAME}" && exit 1
etcdctl member remove ${member_id}
