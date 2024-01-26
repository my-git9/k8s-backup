#!/bin/bash
calicoLockMode="lock"
calicoUnlockMode="unlock"
inputLockMode=$calicoLockMode
if [ $# -eq 0 ]; then
  echo "You will backup with calico ipam lock."
elif [ $# -eq 1 ]; then
  inputLockMode=$1
  if [ $inputLockMode == $calicoUnlockMode ]; then
    echo "[Warning] You will backup with no calico ipam lock!"
  else
    echo "[Error] Wrong input: $*"
    exit 1
  fi
else
  echo "[Error] Too many params!"
  exit 1
fi

echo $(hostname)

etcd_container=`nerdctl ps |grep etcd |grep $(hostname)  | grep -v pause | awk '{print $1}'`
cluster_health=`nerdctl exec -it -e ETCDCTL_API=3 $etcd_container -- etcdctl --cert=/etc/kubernetes/ssl/etcd/server.crt --key=/etc/kubernetes/ssl/etcd/server.key --cacert=/etc/kubernetes/ssl/etcd/ca.crt endpoint health --cluster |grep unhealthy`
echo "Etcd cluster health status： $cluster_health"
if [ "$cluster_health" != "" ]; then
    echo "[Error] Etcd cluster is unhealthy now，please repair to healthy before backup."
    exit
else
    mkdir -p /tmp/etcd_backup
    nerdctl cp `nerdctl ps |grep etcd |grep $(hostname) | grep -v pause | awk '{print $1}'`:/usr/local/bin/etcdutl /tmp/etcd_backup/etcdutl
    nerdctl cp `nerdctl ps |grep etcd |grep $(hostname)  | grep -v pause | awk '{print $1}'`:/usr/local/bin/etcdctl /tmp/etcd_backup/etcdctl
    echo "Please input the directory where you want to save the etcd backup data，default will be /tmp/etcd_backup"
    #read backup_dir
    echo "$backup_dir"
fi
if [ -z "$backup_dir" ];then
    backup_dir="/tmp/etcd_backup"
    echo "The default backup path $backup_dir will be used."
fi
if [ -d "$backup_dir" ]; then
    mkdir -p $backup_dir
fi

if [ "$inputLockMode" = "$calicoLockMode" ]; then
  calicoctl ipam show >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    calicoctl datastore migrate lock
  else
    echo "[Error] calicoctl connection failed, please manually check for problems."
    exit 1
  fi
fi

timestamp=`date +"%Y%m%d%H%M%S"`
export ETCDCTL_API=3
export param="--endpoints=https://localhost:2379 --cert=/etc/kubernetes/ssl/etcd/server.crt --key=/etc/kubernetes/ssl/etcd/server.key --cacert=/etc/kubernetes/ssl/etcd/ca.crt"
/tmp/etcd_backup/etcdctl $param snapshot save ${backup_dir}/backup_v3_${timestamp}.db && /tmp/etcd_backup/etcdutl --write-out=table snapshot status ${backup_dir}/backup_v3_${timestamp}.db

if [ $? -ne 0 ]; then
  echo "[Error] Etcd3 backup error, please manually check for problems."
  rm -rf ${backup_dir}/backup_v3_${timestamp}.db

  if [ $inputLockMode == $calicoLockMode ]; then
    calicoctl datastore migrate unlock
  fi

  exit 1
fi

if [ $inputLockMode == $calicoLockMode ]; then
  calicoctl datastore migrate unlock
fi
