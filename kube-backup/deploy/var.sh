#!/bin/bash

# -------- 必选参数 -------
# 这里需要设置内部仓库的地址和租户,并且请设置租户为公开
REGISTRY='10.23.100.187/daocloud'
# 这里需要设置内部仓库的用户和密码, 推送镜像用,
REGISTRY_USER="admin"
REGISTRY_PASSWORD="changeme"

# 镜像架构
ARCH=`arch`
if [[ "$ARCH" == "aarch64" ]]; then
   MANIFEST="arm64"
elif [[ "$ARCH" == "x86_64" ||  "$ARCH" == "i386" ]]; then
    MANIFEST="amd64"
fi

## 如果部署混合集群，需要配置以下参数
# 指定amd镜像包
amdpackage=images-amd64.tar
# 指定arm镜像包
armpackage=images-arm64.tar

# 部署所需变量
export REGISTRY='10.23.100.187/daocloud'
export KUBEBACKUP_CLEAN_IMAGENAME=hyperkube:v1.5.4
export KUBEBACKUP_IMAGENAME=kube-backup:v1.17.1
export KUBEBACKUP_GIT_REPO="git@gitlab.daocloud.cn:etc-common/dce-cluster-backup.git"
# 需要备份的资源类型；默认备份全部api-resource；如果需要指定类型，请在此处配置。
export KUBEBACKUP_RESOURCETYPES=""
export KUBEBACKUP_GIT_PREFIX_PATH=/
export KUBEBACKUP_GIT_BRANCH=main