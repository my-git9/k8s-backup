# etcd 备份
基于dce4 cronjob 的 etcdv2 etcdv3 备份

## 创建备份任务
1、按照提示修改 `var.sh` 脚本中的变量
2、执行 `./manifest_images_build.sh` 制作混合镜像(如果主节点不存在arm64架构主机，此步骤跳过)
3、执行 `/install.sh` 创建备份任务

## 开源 Kubernetes 恢复

***以下恢复 etcd 数据的每一步都需要在每一台 Master 上同步执行。***
- 在所有 Master 上运行恢复脚本**每行输入 MasterHostname MasterIP（输入 3 个master节点信息）**，以空格隔开，回车：

```shell
$./recover.sh
Please input the master hostname ips  to be recovered, and seperated them with a blank space(must 3 nodes in 3 lines).

Example:
   master-10-29-22-5 10.29.22.5
   master-10-29-22-6 10.29.22.6
   master-10-29-22-7 10.29.22.7

master-10-29-22-5 10.29.22.5
master-10-29-22-6 10.29.22.6
master-10-29-22-7 10.29.22.7
```

- 输入数据的 db 文件的全路径，回车：

```shell
Please input the etcd V3 db file you want to recover with full path, and make sure it exists on all the masters.

Example:
  /tmp/etcd_backup/backup_v3_20240126161041.db

# 输入 db 文件路径
/tmp/etcd_backup/backup_v3_20240126161041.db
```

- 输入本地的IP，回车
```shell
# 以下 IP 修改为自己的 IP 路径
Please input local ip address for etcd endpoint.

Example:
  10.29.22.5
  
10.29.22.6
```

- 在所有 Master 上回车确认，等所有 Master 节点上都有以下输出时，再同时回车确认：

```shell
Please make sure you press enter at the same time on all the masters, ready to stop all the API server instances?

All the API server yaml files have been moved from /etc/kubernetes/manifests to /tmp/yaml_bak
Etcd data directory has been moved from /var/local/dce/etcd/etcd to /var/local/dce/etcd/etcd_backup_20240126182258 as backup.
Starting to recover etcd cluster...
2024-01-26T18:23:28+08:00	info	snapshot/v3_snapshot.go:248	restoring snapshot	{"path": "/tmp/etcd_backup/backup_v3_20240126161041.db", "wal-dir": "/var/lib/etcd/member/wal", "data-dir": "/var/lib/etcd", "snap-dir": "/var/lib/etcd/member/snap", "stack": "go.etcd.io/etcd/etcdutl/v3/snapshot.(*v3Manager).Restore\n\tgo.etcd.io/etcd/etcdutl/v3/snapshot/v3_snapshot.go:254\ngo.etcd.io/etcd/etcdutl/v3/etcdutl.SnapshotRestoreCommandFunc\n\tgo.etcd.io/etcd/etcdutl/v3/etcdutl/snapshot_command.go:147\ngo.etcd.io/etcd/etcdutl/v3/etcdutl.snapshotRestoreCommandFunc\n\tgo.etcd.io/etcd/etcdutl/v3/etcdutl/snapshot_command.go:117\ngithub.com/spf13/cobra.(*Command).execute\n\tgithub.com/spf13/cobra@v1.1.3/command.go:856\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\tgithub.com/spf13/cobra@v1.1.3/command.go:960\ngithub.com/spf13/cobra.(*Command).Execute\n\tgithub.com/spf13/cobra@v1.1.3/command.go:897\nmain.Start\n\tgo.etcd.io/etcd/etcdutl/v3/ctl.go:50\nmain.main\n\tgo.etcd.io/etcd/etcdutl/v3/main.go:23\nruntime.main\n\truntime/proc.go:225"}
2024-01-26T18:23:28+08:00	info	membership/store.go:141	Trimming membership information from the backend...
2024-01-26T18:23:28+08:00	info	membership/cluster.go:421	added member	{"cluster-id": "bae2b55414f4662c", "local-member-id": "0", "added-peer-id": "65ed2c9102a64d", "added-peer-peer-urls": ["https://10.29.22.5:2380"]}
2024-01-26T18:23:28+08:00	info	membership/cluster.go:421	added member	{"cluster-id": "bae2b55414f4662c", "local-member-id": "0", "added-peer-id": "1e9a798d6e3ede5a", "added-peer-peer-urls": ["https://10.29.22.7:2380"]}
2024-01-26T18:23:28+08:00	info	membership/cluster.go:421	added member	{"cluster-id": "bae2b55414f4662c", "local-member-id": "0", "added-peer-id": "6a93390c1325f78e", "added-peer-peer-urls": ["https://10.29.22.6:2380"]}
2024-01-26T18:23:28+08:00	info	snapshot/v3_snapshot.go:269	restored snapshot	{"path": "/tmp/etcd_backup/backup_v3_20240126161041.db", "wal-dir": "/var/lib/etcd/member/wal", "data-dir": "/var/lib/etcd", "snap-dir": "/var/lib/etcd/member/snap"}
```

- 当所有 Master 都有如下返回时，说明此时 etcd 集群是健康状态，同时回车进行下一步，等待 etcd 启动：
```shell
Please make sure you press enter at the same time on all the masters, ready to start etcd instances?

Etcd yaml file has been moved from /tmp/yaml_bak/etcd.yaml to /etc/kubernetes/manifests/etcd.yaml, waiting for etcd instances ready...
Please make sure you press enter at the same time on all the masters, ready to check etcd cluster health?
```

- 当所有 Master 都有如下返回时，说明此时 etcd 集群是健康状态，同时回车进行下一步，等待 etcd 启动：
```shell
Etcd cluster health status：
65ed2c9102a64d, started, master-10-29-22-5, https://10.29.22.5:2380, https://10.29.22.5:2379, false
1e9a798d6e3ede5a, started, master-10-29-22-7, https://10.29.22.7:2380, https://10.29.22.7:2379, false
6a93390c1325f78e, started, master-10-29-22-6, https://10.29.22.6:2380, https://10.29.22.6:2379, false
Etcd cluster has been successfully recovered. Please make sure you press enter at the same time on all the masters, ready to recover all the API server instances?
```

- 等待 1 分支后，尝试执行 kubectl 命令查看集群信息是否正常

## DCE4 恢复

### 恢复 V3 数据

***以下恢复 V3 数据的每一步都需要在每一台 Master 上同步执行。***
- 在所有 Master 上运行恢复脚本并输入所有 Master的IP，以空格隔开，回车：

```shell
# 以下所有 IP 记得修改为自己的
./recover-dce4.sh
Please input the master ips to be recovered, and seperated them with a blank space.
10.6.120.5 10.6.120.6 10.6.120.9
```

- 输入本地的IP，回车
```shell
# 以下 IP 修改为自己的
Please input local ip address for etcd endpoint.
10.6.120.5
```

- 指定要恢复的 V3 数据的 db 文件的全路径，回车：

```shell
Please input the etcd V3 db file you want to recover with full path, and make sure it exists on all the masters.
/tmp/etcd_backup/backup_v3_20211103112341.db 
```

- 在所有 Master 上回车确认，等所有 Master 节点上都有以下输出时，再同时回车确认：

```shell
Please make sure you press enter at the same time on all the masters, ready to stop all the API server instances?
 
All the API server yaml files have been moved from /etc/daocloud/dce/kubelet/manifests to /tmp/yaml_bak
Etcd data directory has been moved from /var/local/dce/etcd/etcd to /var/local/dce/etcd/etcd_backup_20211102164313 as backup.
Starting to recover etcd cluster...
Deprecated: Use `etcdutl snapshot restore` instead.
 
2021-11-03T10:44:05+08:00   info    snapshot/v3_snapshot.go:251 restoring snapshot  {"path": "/tmp/etcd_backup/backup_v3_20211102162733.db", "wal-dir": "/var/local/dce/etcd/etcd/member/wal", "data-dir": "/var/local/dce/etcd/etcd", "snap-dir": "/var/local/dce/etcd/etcd/member/snap", "stack": "go.etcd.io/etcd/etcdutl/v3/snapshot.(*v3Manager).Restore\n\t/tmp/etcd-release-3.5.0/etcd/release/etcd/etcdutl/snapshot/v3_snapshot.go:257\ngo.etcd.io/etcd/etcdutl/v3/etcdutl.SnapshotRestoreCommandFunc\n\t/tmp/etcd-release-3.5.0/etcd/release/etcd/etcdutl/etcdutl/snapshot_command.go:147\ngo.etcd.io/etcd/etcdctl/v3/ctlv3/command.snapshotRestoreCommandFunc\n\t/tmp/etcd-release-3.5.0/etcd/release/etcd/etcdctl/ctlv3/command/snapshot_command.go:128\ngithub.com/spf13/cobra.(*Command).execute\n\t/home/remote/sbatsche/.gvm/pkgsets/go1.16.3/global/pkg/mod/github.com/spf13/cobra@v1.1.3/command.go:856\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\t/home/remote/sbatsche/.gvm/pkgsets/go1.16.3/global/pkg/mod/github.com/spf13/cobra@v1.1.3/command.go:960\ngithub.com/spf13/cobra.(*Command).Execute\n\t/home/remote/sbatsche/.gvm/pkgsets/go1.16.3/global/pkg/mod/github.com/spf13/cobra@v1.1.3/command.go:897\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.Start\n\t/tmp/etcd-release-3.5.0/etcd/release/etcd/etcdctl/ctlv3/ctl.go:107\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.MustStart\n\t/tmp/etcd-release-3.5.0/etcd/release/etcd/etcdctl/ctlv3/ctl.go:111\nmain.main\n\t/tmp/etcd-release-3.5.0/etcd/release/etcd/etcdctl/main.go:59\nruntime.main\n\t/home/remote/sbatsche/.gvm/gos/go1.16.3/src/runtime/proc.go:225"}
2021-11-03T10:44:05+08:00   info    membership/store.go:119 Trimming membership information from the backend...
2021-11-03T10:44:05+08:00   info    membership/cluster.go:393   added member    {"cluster-id": "3047f5ea244f8d8c", "local-member-id": "0", "added-peer-id": "1001be6e7dd6c007", "added-peer-peer-urls": ["http://10.6.120.6:12380"]}
2021-11-03T10:44:05+08:00   info    membership/cluster.go:393   added member    {"cluster-id": "3047f5ea244f8d8c", "local-member-id": "0", "added-peer-id": "275f0245b12d8e2d", "added-peer-peer-urls": ["http://10.6.120.9:12380"]}
2021-11-03T10:44:05+08:00   info    membership/cluster.go:393   added member    {"cluster-id": "3047f5ea244f8d8c", "local-member-id": "0", "added-peer-id": "fe652dd3389c9c68", "added-peer-peer-urls": ["http://10.6.120.5:12380"]}
2021-11-03T10:44:05+08:00   info    snapshot/v3_snapshot.go:272 restored snapshot   {"path": "/tmp/etcd_backup/backup_v3_20211103112341.db", "wal-dir": "/var/local/dce/etcd/etcd/member/wal", "data-dir": "/var/local/dce/etcd/etcd", "snap-dir": "/var/local/dce/etcd/etcd/member/snap"}
Please make sure you press enter at the same time on all the masters, ready to start etcd instances?
```

- 当所有 Master 都有如下返回时，说明此时 etcd 集群是健康状态，同时回车进行下一步，等待 etcd 启动：

```shell
Please make sure you press enter at the same time on all the masters, ready to start etcd instances?
 
Etcd yaml file has been moved from /tmp/yaml_bak/dce_etcd.yaml to /etc/daocloud/dce/kubelet/manifests/dce_etcd.yaml, waiting for etcd instances ready...
 
Please make sure you press enter at the same time on all the masters, ready to check etcd cluster health? 
```

- 当所有 Master 都有如下返回时，说明此时所有 Master 上的 etcd 都已经启动成功，同时回车进行下一步：

```shell
Please make sure you press enter at the same time on all the masters, ready to check etcd cluster health?
 
Etcd cluster health status： member 1001be6e7dd6c007 is healthy: got healthy result from https://10.6.120.6:12379
member 275f0245b12d8e2d is healthy: got healthy result from https://10.6.120.9:12379
member fe652dd3389c9c68 is healthy: got healthy result from https://10.6.120.5:12379
cluster is healthy
Member：10.6.120.6
Member：10.6.120.9
Member：10.6.120.5
3 etcd members recoverd.
Etcd cluster has been successfully recovered. Please make sure you press enter at the same time on all the masters, ready to recover all the API server instances? 
```

- 到这里稍等片刻，V3 数据就恢复完成，Kubernetes 集群就绪。

```shell
Etcd cluster has been successfully recovered. Please make sure you press enter at the same time on all the masters, ready to recover all the API server instances?
 
Etcd V3 data has been successfully recovered，now you can recover V2 data on any one master.
[root@dce-10-6-120-5 ~]# kubectl get no
The connection to the server 127.0.0.1:11081 was refused - did you specify the right host or port?
[root@dce-10-6-120-5 ~]# kubectl get no
NAME             STATUS   ROLES             AGE   VERSION
dce-10-6-120-5   Ready    master,registry   8d    v1.18.20
dce-10-6-120-6   Ready    master,registry   18h   v1.18.20
dce-10-6-120-9   Ready    master,registry   18h   v1.18.20
```

### 恢复 V2 数据
V3 数据恢复成功之后，即可开始恢复 V2 数据，***只需要在一台 Master 上进行***，执行备份时得到的 /tmp/etcd_backup/backup_v2_20211103112328.sh 脚本，输出设置的所有 V2 数据值。

```shell
[root@dce-10-6-120-5 ~]# /tmp/etcd_backup/backup_v2_20211103112328.sh
{"namespace": "daocloud", "name": "dao-2048", "short_description": null, "long_description": null, "labels": {}, "updated_at": 1635152089.9857988, "latest_tag": "latest", "auto_clean": {"rules": [], "enable": false, "reserved_time": 1296000}}
{"namespace": "daocloud", "name": "spring-boot-sample", "short_description": null, "long_description": null, "labels": {}, "updated_at": 1635152089.9882207, "latest_tag": "latest", "auto_clean": {"rules": [], "enable": false, "reserved_time": 1296000}}
...
```

此时 V2 V3 数据都已恢复完成

## 注意事项
### 关于备份
- 备份 etcdv3 的过程中会做对 calico ipam 进行 lock 操作，在此期间 calico 无法为 Pod 分配、修改、删除 IP

### 关于恢复
- 目前针对的场景是原地恢复，异地恢复尚未验证
- etcd 数据恢复过程中需要停止所有 API server 实例，请知晓潜在风险并提前做好相应准备
- 恢复完数据后，需要对集群进行一次巡检







