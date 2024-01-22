# 备份主节点的配置

思路： 备份两个路径和一个文件

- /etc/kubernetes
- /var/lib/kubelet
- /etc/sysconfig/kubelet -> file; 为方便起见，最后脚本实际上是备份/etc/sysconfig 目录

主要命令：

```bash
# 10.20.123.19
# 10.20.123.20
rsync -av /etc/kubernetes root@10.20.123.20:/root/master-backup/master01
rsync -av /var/lib/kubelet root@10.20.123.20:/root/master-backup/master01
rsync -av /etc/sysconfig root@10.20.123.20:/root/master-backup/master01
```

```bash
# copy script
scp conf-backup.sh root@10.20.123.6:
scp conf-backup.sh root@10.20.123.7:

# must add ssh key for rsync, do it manually
vim .ssh/authorized_keys
```

```bash
# run the script as below, the parameter is the fold storing master configs
./conf-backup.sh master1
```

todo:

- add this script to cronjob to run periodically

ps: 实际上master已经有三节点高可用方案，这种备份应该是完全之策，使用的概率非常小
