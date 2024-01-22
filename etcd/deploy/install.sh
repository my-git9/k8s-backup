#!/usr/bin/env bash
set -x
#set -o errexit
set -o pipefail

source var.sh
export FREQ=$1

## 上传镜像
load_and_push_image(){
    docker login --password ${REGISTRY_PASSWORD} --username ${REGISTRY_USER} ${REGISTRY}
    docker load -i images-$MANIFEST.tar

    for i in `cat images.txt |grep -v ^# |grep -v ^$`
    do
      imagename=`echo $i |awk -F '/' '{$1="";print $0}'`
      docker tag $i ${REGISTRY}${imagename// //}
      docker push ${REGISTRY}${imagename// //}
      IMAGE=${REGISTRY}${imagename// //}
    done
}

# 发布
deploy(){
  # create dir
  if [[ "${STORAGE_MODE}" == "local" ]]; then
  echo "Please execute the command to create a directory on the corresponding node" $NODENAME ": mkdir -p $BACKDIR"
  read answer
  fi
  # create namespace
  ns="`kubectl get namespace |grep -w  kube-backup`"
  if [[ "$ns" == "" ]]; then
    kubectl create namespace kube-backup
  fi

  sed -i.bak "s#SCHEDULE#${SCHEDULE}#g" etcd_backup_cj.yaml
  sed -i "s#IMAGE#${IMAGE}#g" etcd_backup_cj.yaml
  sed -i "s#ETCD_RETENTION_POLICY#${RETENTION_POLICY}#g" etcd_backup_cj.yaml
  sed -i "s#ETCD_RETENTION#\"${RETENTION}\"#g" etcd_backup_cj.yaml
  sed -i "s#CALICO_LOCK#\"${CALICO_LOCK}\"#g" etcd_backup_cj.yaml


  # 准备PV
  if [[ "${STORAGE_MODE}" == "local" ]]; then
    sed -i.bak "s#BACKDIR#${BACKDIR}#g" local_storage.yaml
    sed -i "s#NODENAME#${NODENAME}#g" local_storage.yaml
    kubectl apply -f local_storage.yaml
  elif [[ "${STORAGE_MODE}" == "nfs" ]]; then
    sed -i.bak "s#BACKDIR#${BACKDIR}#g" nfs_storage.yaml
    sed -i "s#NFSSERVER#${NFSSERVER}#g" nfs_storage.yaml
    kubectl apply -f nfs_storage.yaml
  fi

  # 安装cronjob
  kubectl apply -f etcd_backup_cj.yaml

  # check cronjob
  kubectl -n kube-backup get cronjob
}

# 替换yaml文件
[ -f etcd_backup_cj.yaml.bak ] && mv etcd_backup_cj.yaml.bak etcd_backup_cj.yaml
[ -f local_storage.yaml.bak ] && mv local_storage.yaml.bak local_storage.yaml
[ -f nfs_storage.yaml.bak ] && mv nfs_storage.yaml.bak nfs_storage.yaml

if [[ "$PUSHIMAGE" == 'y' ]]; then
  load_and_push_image
else
    for i in `cat images.txt |grep -v ^# |grep -v ^$`
      do
        imagename=`echo $i |awk -F '/' '{$1="";print $0}'`
        IMAGE=${REGISTRY}${imagename// //}
      done
fi

deploy
