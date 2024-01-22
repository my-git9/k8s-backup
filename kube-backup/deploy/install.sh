#!/usr/bin/env bash
#set -x
set -o errexit
set -o nounset
set -o pipefail

source var.sh
## 上传镜像
load_and_push_image(){
    docker login --password ${REGISTRY_PASSWORD} --username ${REGISTRY_USER} ${REGISTRY}
    docker load -i images-$MANIFEST.tar

    for i in `cat images.txt |grep -v ^# |grep -v ^$`
    do
      imagename=`echo $i |awk -F '/' '{$1="";print $0}'`
      docker tag $i ${REGISTRY}${imagename// //}
      docker push ${REGISTRY}${imagename// //}
    done
    }

# 发布
deploy(){

  echo -e "\033[44;35;5mssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfm9fS3+TwH8NIAPns8WEIcV9sUrIbe/1eEUEW3ZciXITAJuSUhL8X8QnvfjLijxITjSGfvty6iUMm6u/v6lxQiPWqNgAKhPtEwko6BbdGScO+hagOzkMR/XIDXEVXq7mchzvXGB6EGghCESkRKeegRVygGFWXiIUBMrcDBDzyGcR0ErHOysp5ZEEGo6kH+7j/sKgi5B0CdKolHfjyeNHkuNQfL19hvLgkSNJNFRYK5U67T0Z4BC+c99ymY3R6W7gjM4h7wOgsXC6FRrsS3ERUf7t89gGwuWdN4urt/3ulXyfhfpEzCufPCFySt/8Yqwm4GDMCTKilF62sNHZ950IX root@dce-10-21-5-74\033[0m\n"
  echo "请将上面的SSH公钥加入拥有资源备份Git仓库权限的账号中"
  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
  # sed -i "s#{REGISTRY}#${REGISTRY}#g" deployment.yaml
  # kubectl apply -f deployment.yaml
  kubectl create ns kube-backup || echo "名称空间已存在"
  kubectl apply -f rbac.yaml,kube-backup-ssh-secret.yaml
  envsubst < cronjob-ssh.yaml  | kubectl apply -f -
  envsubst < job-cleanup.yaml  | kubectl apply -f -
}

read -p "是否加载镜像离线包(y/n)：" PUSHIMAGE
if [[ $PUSHIMAGE == "y" || $PUSHIMAGE == "Y" ]]; then
load_and_push_image
fi
deploy

