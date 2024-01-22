#!/bin/bash
kubelet_status=`systemctl status kubelet | sed -n 5p`
kubelet_status=($kubelet_status)
kubelet=${kubelet_status[1]}
if [ $kubelet != "active" ]; then
    echo "[Error] Kubelet is not active now, please start kubelet before recovering etcd."
    exit
else
    echo "Please input the master ips to be recovered, and seperated them with a blank space."
    read master_member
fi
echo "Please input the etcd V3 db file you want to recover with full path, and make sure it exists on all the masters."
read db
cluster_member=($master_member)
#hostips=$(hostname -I)
#ip_array=($hostips)
#hostip=${ip_array[0]}
echo "Please input local ip address for etcd endpoint."
read hostip

initial_cluster="--initial-cluster "
num_in=0
for ip in "${cluster_member[@]}"
do
    initial_cluster="${initial_cluster}dce-etcd-$ip=http://$ip:12380,"
    num_in=$((num_in+1))
done
length=${#initial_cluster}
length=$((length-1))
initial_cluster="${initial_cluster: 0: $length}"

mkdir -p /tmp/yaml_bak
echo "Please make sure you press enter at the same time on all the masters, ready to stop all the API server instances?"
read answer

mv /etc/daocloud/dce/kubelet/manifests/*.yaml /tmp/yaml_bak/
echo "All the API server yaml files have been moved from /etc/daocloud/dce/kubelet/manifests to /tmp/yaml_bak"

timestamp=`date +"%Y%m%d%H%M%S"`
mv /var/local/dce/etcd/etcd /var/local/dce/etcd/etcd_backup_${timestamp}
echo "Etcd data directory has been moved from /var/local/dce/etcd/etcd to /var/local/dce/etcd/etcd_backup_${timestamp} as backup."
export param="--endpoints=https://localhost:12379 --cert=/etc/daocloud/dce/certs/etcd/server.crt --key=/etc/daocloud/dce/certs/etcd/server.key --cacert=/etc/daocloud/dce/certs/ca.crt"
export ETCDCTL_API=3
echo "Starting to recover etcd cluster..."
sleep 30

/tmp/etcd_backup/etcdctl $param snapshot restore $db --data-dir /var/local/dce/etcd/etcd --name=dce-etcd-$hostip $initial_cluster --initial-advertise-peer-urls http://$hostip:12380
echo "Please make sure you press enter at the same time on all the masters, ready to start etcd instances?"
read answer

mv /tmp/yaml_bak/dce_etcd.yaml /etc/daocloud/dce/kubelet/manifests/dce_etcd.yaml
echo "Etcd yaml file has been moved from /tmp/yaml_bak/dce_etcd.yaml to /etc/daocloud/dce/kubelet/manifests/dce_etcd.yaml, waiting for etcd instances ready..."

retry_cnt=0
retry_total=30
while :
do
    if [ $retry_total -gt $retry_cnt ]; then
        etcd=`docker ps |grep etcd | grep -v pause | awk '{print $1}'`
        if [ -n "$etcd" ];then
            break
        else
            retry_cnt=$(($retry_cnt+1))
            sleep 30
        fi
    else
        echo "[Error] Start etcd instace failed."
        exit 1
    fi
done
echo "Please make sure you press enter at the same time on all the masters, ready to check etcd cluster health?"
read answer
cluster_health=`docker exec -it -e ETCDCTL_API=2 $etcd etcdctl cluster-health`
echo "Etcd cluster health status: $cluster_health"
health=${cluster_health: 0-8 :7}
if [ $health != "healthy" ]; then
    echo "[Error] Etcd cluster is unhealthy."
    exit
else
    /tmp/etcd_backup/etcdctl $param member list |
        while IFS= read -r line
        do
            ip_port=${line##*/}
            ip=${ip_port%:*}
            echo "Member: $ip"
            if [[ " ${cluster_member[*]} " =~ " ${ip} " ]]; then
                continue
            else
               echo "[Error] Unexpected etcd member IP ${ip}."
               exit
            fi
        done
fi
num_out=`/tmp/etcd_backup/etcdctl $param member list | wc -l`
echo "${num_out} etcd members recoverd."
if [ ${num_in} != ${num_out} ]; then
    echo "[Error] The number of etcd member is not right."
    exit
fi

echo "Etcd cluster has been successfully recovered. Please make sure you press enter at the same time on all the masters, ready to recover all the API server instances?"
read answer

mv /tmp/yaml_bak/dce_kube_apiserver*.yaml /etc/daocloud/dce/kubelet/manifests/
sleep 5

echo "Restarting kubelet..."
systemctl restart kubelet
sleep 5

mv /tmp/yaml_bak/*.yaml /etc/daocloud/dce/kubelet/manifests/
echo "Etcd V3 data has been successfully recovered, now you can recover V2 data on any one master."
