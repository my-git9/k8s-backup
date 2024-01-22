# k8s 应用备份

## velero 简介

[velero](https://github.com/heptio/velero) 是kubernetes备份和迁移的一个工具，其官方推荐的使用场景为灾难恢复，数据迁移，数据保护等

其基本原理为在k8s中部署一个velero服务并对接外部s3存储，velero就可以对k8s集群中各种应用进行备份，备份的数据存储于外部的s3中，在出现极端情况下可以对数据进行相应的恢复。

velero支持label select进行备份或者按照namespace进行备份，并且对支持的存储进行快照（云服务厂商）

这里我们只用到velero的备份恢复功能，存储的快照功能不进行讨论

## 部署

### 部署s3兼容的存储服务minio

[minio](https://github.com/minio/minio)是一个轻量的兼容s3的对象存储服务，在数据安全性不高的情况下可以使用作为对象存储使用

这里使用docker-compose运行一个轻量的minio服务，docker-compose内容如下:

```yaml
version: '3.7'
services:
  minio:
    image: harbor.geniusafc.com/docker.io/minio:latest
    volumes:
      - ./data:/data
    ports:
      - "9900:9000"
    environment:
      MINIO_ACCESS_KEY: minio
      MINIO_SECRET_KEY: minio123
    command: --compat server /data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
```

minio提供一个[轻量的web界面](http://10.20.123.19:9900)，使用accesskey和secretkey可以进行访问

服务启动后，需要手动创建一个bucket，名字为velero，提供给后续部署的velero使用

### 安装velero

[从velero的release界面](https://github.com/heptio/velero/releases)下载最新的发布包，解压之后velero可运行的二进制文件就位于其中

velero提供了一个 install命令，用于在k8s集群中快速安装velero

```bash
./velero install \
--kubeconfig /home/matrix/.kube/lab-config \
--image harbor.geniusafc.com/docker.io/velero:v1.1.0 \
--provider aws \
--bucket velero \
--secret-file ./credentials-velero \
--use-volume-snapshots=false \
--backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://10.20.123.19:9900
```

velero默认安装在velero的命名空间中

## 使用

velero可以对命令空间进行整体备份恢复，参考命令如下

```bash
# 备份namespace nginx-example，备份名称为 nginx-backup
./velero backup create nginx-backup --include-namespaces nginx-example --kubeconfig /home/matrix/.kube/lab-config

# 查看备份日志
./velero backup logs nginx-backup --kubeconfig /home/matrix/.kube/lab-config

# 查看备份状态
./velero backup get nginx-backup --kubeconfig /home/matrix/.kube/lab-config

# 恢复
./velero restore create --from-backup nginx-backup --kubeconfig /home/matrix/.kube/lab-config

# 查看恢复状态
./velero restore get --kubeconfig /home/matrix/.kube/lab-config
```

### 定时备份

可对用户关心的namespace进行定时备份，备份命令如下：

```bash
# 对kube-system进行每天备份
./velero schedule create kube-system-daily --schedule="@daily" --include-namespaces kube-system --kubeconfig /home/matrix/.kube/lab-config

# 查看定时备份状态
./velero schedule get --kubeconfig /home/matrix/.kube/lab-config
```

更详细内容请参考[官方文档](https://velero.io/docs/v1.1.0/)
