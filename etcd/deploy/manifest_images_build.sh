#!/usr/bin/env bash
source var.sh

# 登陆镜像仓库
docker login --password ${REGISTRY_PASSWORD} --username ${REGISTRY_USER} ${REGISTRY}

# 镜像包参数准备
#echo -e "\033[36m `ls -lh` \033[0m"
#read -p "请指定amd64架构镜像包: " amdpackage
#echo -e "\033[36m `ls -lh` \033[0m"
#read -p '请指定arm64架构镜像包:' armpackage


if [[ "$amdpackage" == "" || "$armpackage" == "" ]]; then
  echo "请按需求在var.sh中填写镜像包！"
  exit 1
fi


# 处理amd64镜像包
docker load -i $amdpackage > /tmp/images-amd.txt
cat /tmp/images-amd.txt |grep 'Loaded image: '|awk '{print $3}' >/tmp/images.txt
for i in `cat /tmp/images.txt |grep -v '^#' |grep -v ^$`
do
    imagename=`echo $i |awk -F '/' '{$1="";print $0}'`
    docker tag $i ${REGISTRY}${imagename// //}-amd64
    docker push ${REGISTRY}${imagename// //}-amd64
    docker rmi $i
done

# 处理arm64镜像包
docker load -i $armpackage > /tmp/images-arm.txt
cat /tmp/images-arm.txt |grep 'Loaded image: '|awk '{print $3}' >/tmp/images.txt
for i in `cat /tmp/images.txt |grep -v '^#' |grep -v ^$`
do
    imagename=`echo $i |awk -F '/' '{$1="";print $0}'`
    docker tag $i ${REGISTRY}${imagename// //}-arm64
    docker push ${REGISTRY}${imagename// //}-arm64
    docker rmi $i
done

# 清除manifests缓存
rm -rf ~/.docker/manifests/

# 混合镜像制作
export DOCKER_CLI_EXPERIMENTAL=enabled

for i in `cat /tmp/images.txt |grep -v '^#' |grep -v ^$`
do
    imagename=`echo $i |awk -F '/' '{$1="";print $0}'`
    image=${REGISTRY}${imagename// //}

    docker manifest create --insecure \
    ${REGISTRY}${imagename// //} \
    --amend ${REGISTRY}${imagename// //}-amd64 \
    --amend ${REGISTRY}${imagename// //}-arm64
    docker manifest push --insecure ${REGISTRY}${imagename// //}
done