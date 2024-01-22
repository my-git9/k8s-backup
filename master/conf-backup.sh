#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

backup_path=(
    "/etc/kubernetes"
    "/var/lib/kubelet"
    "/etc/sysconfig"
)

store_server=(
    "10.20.123.19"
    "10.20.123.20"
)

for server in ${store_server[@]}; do
    for path in ${backup_path[@]}; do
        rsync -av $path root@$server:/root/master-backup/$1
    done
done
