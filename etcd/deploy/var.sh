#!/bin/bash

# -------- 必选参数 -------
# 这里需要设置内部仓库的地址和租户,并且请设置租户为公开
REGISTRY=${REGISTRY-'10.29.121.21/daocloud'}
# 这里需要设置内部仓库的用户和密码, 推送镜像用,
REGISTRY_USER="admin"
REGISTRY_PASSWORD="changeme"

# 是否上传镜像，如果部署混合架构集群，或纳管集群有arm集群有amd集群，要填'n',默认'y'
PUSHIMAGE='y'

# 调度周期
SCHEDULE="*/10 * * * *"

# 存储模式(local 或 nfs)
STORAGE_MODE=${STORAGE_MODE-'local'}

# Pod运行的节点，需选择一个master节点的主机名(local模式指定)
NODENAME="dce-10-29-8-134"

# NFS地址(nfs模式指定)
NFSSERVER="10.29.0.149"

# 备份的目录，如果是local模式则为本地目录，如果是nfs模式则为nfs路径
BACKDIR="/nfs_ssd/dce_registry_10.29.8.20/etcd_backup"

# calico 是否加锁，
# 默认为空代表 v3 加锁
# 设置为 unlock 时 v3 不加锁
CALICO_LOCK=""

# 保留策略，默认保留 7 天内的文件
# 修改为 file ，保留最近几份文件
RETENTION_POLICY="day"
RETENTION=7

# 主机CPU架构
MANIFEST=amd64