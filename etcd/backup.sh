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

etcd_container=`docker ps |grep etcd | grep -v pause | awk '{print $1}'`
cluster_health=`docker exec -it -e ETCDCTL_API=2 $etcd_container etcdctl cluster-health`
echo "Etcd cluster health status： $cluster_health"
health=${cluster_health: 0-8 :7}
if [ $health != "healthy" ]; then
    echo "[Error] Etcd cluster is unhealthy now，please repair to healthy before backup."
    exit
else
    mkdir -p /tmp/etcd_backup
    docker cp `docker ps |grep etcd | grep -v pause | awk '{print $1}'`:/usr/local/bin/etcdctl /tmp/etcd_backup/etcdctl
    echo "Please input the directory where you want to save the etcd backup data，default will be /tmp/etcd_backup"
    read backup_dir
    echo "$backup_dir"
fi
if [ -z "$backup_dir" ];then
    backup_dir="/tmp/etcd_backup"
    echo "The default backup path $backup_dir will be used."
fi
if [ -d "$backup_dir" ]; then
    mkdir -p $backup_dir
fi

export ETCDCTL_API=2
export param="--endpoints=https://localhost:12379 --cert-file=/etc/daocloud/dce/certs/etcd/server.crt --key-file=/etc/daocloud/dce/certs/etcd/server.key --ca-file=/etc/daocloud/dce/certs/ca.crt"
echo "Starting to backup..."
num=0
timestamp=`date +"%Y%m%d%H%M%S"`
for k in $(/tmp/etcd_backup/etcdctl $param ls --recursive -p | grep -v "/$")
do
  v=$(/tmp/etcd_backup/etcdctl $param get $k)
  if [ $? -eq 0 ]; then
    value=${v//\'/\'\\\'\'}
    num=$((num+1))
    echo "ETCDCTL_API=2 /tmp/etcd_backup/etcdctl $param set $k '$value'" >> ${backup_dir}/backup_v2_${timestamp}.sh
  else
    echo "[Error] Etcd2 backup error, please manually check for problems, if the error contains Key not found, please try backup again."
    rm -rf ${backup_dir}/backup_v2_${timestamp}.sh
    exit 1
  fi
done
echo "ETCDCTL_API=2 /tmp/etcd_backup/etcdctl $param rm /DCE/v1/primary" >> ${backup_dir}/backup_v2_${timestamp}.sh
echo "${num} V2 keys has been successfully backed up."
chmod +x ${backup_dir}/backup_v2_${timestamp}.sh

if [ $inputLockMode == $calicoLockMode ]; then
  calicoctl ipam show >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    calicoctl datastore migrate lock
  else
    echo "[Error] calicoctl connection failed, please manually check for problems."
    exit 1
  fi
fi

export ETCDCTL_API=3
export param="--endpoints=https://localhost:12379 --cert=/etc/daocloud/dce/certs/etcd/server.crt --key=/etc/daocloud/dce/certs/etcd/server.key --cacert=/etc/daocloud/dce/certs/ca.crt"
/tmp/etcd_backup/etcdctl $param snapshot save ${backup_dir}/backup_v3_${timestamp}.db && /tmp/etcd_backup/etcdctl $param --write-out=table snapshot status ${backup_dir}/backup_v3_${timestamp}.db

if [ $? -eq 0 ]; then
  echo "The etcd data has been backed up as ${backup_dir}/backup_v2_${timestamp}.sh and ${backup_dir}/backup_v3_${timestamp}.db"
else
  echo "[Error] Etcd3 backup error, please manually check for problems."
  rm -rf ${backup_dir}/backup_v2_${timestamp}.sh
  rm -rf ${backup_dir}/backup_v3_${timestamp}.db

  if [ $inputLockMode == $calicoLockMode ]; then
    calicoctl datastore migrate unlock
  fi

  exit 1
fi

if [ $inputLockMode == $calicoLockMode ]; then
  calicoctl datastore migrate unlock
fi
