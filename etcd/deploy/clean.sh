#!/usr/bin/env bash

read -p "Do you want to delete the namespace(kube-backup)[y/n]? " delns

echo "删除cronjob dce-backup ..."
kubectl -n kube-backup delete cronjob dce-backup

echo "删除configmap backup-etcd-code ..."
kubectl -n kube-backup delete cm backup-etcd-code

echo "删除存储卷 ..."
kubectl -n kube-backup delete pvc dce-etcd-backup
kubectl delete pv dce-etcd-backup

if [[ "$delns" == "y" ]]; then
  echo "删除namespace kube-backup ..."
  kubectl delete namespace kube-backup
fi