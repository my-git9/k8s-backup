#!/bin/bash

CALICO_LABEL="calico-node"
CALICO_NAMESPACE="kube-system"
KUBEPROXY_LABEL="kube-proxy"

# util::wait_pod_ready waits for pod state becomes ready until timeout.
# Parmeters:
#  - $1: pod label, such as "app=etcd"
#  - $2: pod namespace, such as "kpanda-system"
#  - $3: time out, such as "200s"
function util::wait_pod_ready() {
    local pod_label=$1
    local pod_namespace=$2
    local timeout=$3

    echo "wait the $pod_label ready..."
    set +e
    util::kubectl_with_retry wait --for=condition=Ready --timeout=${timeout} pods -l k8s-app=${pod_label} -n ${pod_namespace}
    ret=$?
    set -e
    if [ $ret -ne 0 ];then
      echo "kubectl describe info: $(kubectl describe pod -l k8s-app=${pod_label} -n ${pod_namespace})"
    fi
    return ${ret}
}

# util::kubectl_with_retry will retry if execute kubectl command failed
# tolerate kubectl command failure that may happen before the pod is created by StatefulSet/Deployment.
function util::kubectl_with_retry() {
    local ret=0
    local count=0
    for i in {1..10}; do
        kubectl "$@"
        ret=$?
        if [[ ${ret} -ne 0 ]]; then
            echo "kubectl $@ failed, retrying(${i} times)"
            sleep 1
            continue
        else
          ((count++))
          # sometimes pod status is from running to error to running
          # so we need check it more times
          if [[ ${count} -ge 3 ]];then
            return 0
          fi
          sleep 1
          continue
        fi
    done

    echo "kubectl $@ failed"
    kubectl "$@"
    return ${ret}
}

# Avoid calico is locked
calicoctl ipam show >/dev/null 2>&1
if [ $? -eq 0 ]; then
  calicoctl datastore migrate unlock
else
  echo "[Error] calicoctl connection failed, please manually check for problems."
  exit 1
fi

# Wait and check calico ready
echo "Checking calico pod is ready..."
util::wait_pod_ready "${CALICO_LABEL}" "${CALICO_NAMESPACE}" 300s

# restart calico node and controller
echo "Restarting calico pods..."
delete_calico=$(kubectl get po -A -o go-template='{{range .items}}{{printf "%s=%s\n" .metadata.namespace .metadata.name}}{{end}}' | grep "calico")
for i in $delete_calico
do
  tmp_ns=${i%=*}
  tmp_pod_name=${i#*=}
  kubectl -n $tmp_ns delete po $tmp_pod_name
done

# Wait and check calico ready
util::wait_pod_ready "${CALICO_LABEL}" "${CALICO_NAMESPACE}" 300s

echo "Deleting bad ip pods..."
# calicoctl wep podip
CALICO_IPS=$(calicoctl get weps --all-namespaces --output=go-template='{{range .}}{{range .Items}}{{range .Spec.IPNetworks}}{{printf "%v\n" .}}{{end}}{{end}}{{end}}' | awk -F "/" '{ print $1 }')

## is calicoPod
function isCalicoPod(){
  return `kubectl get po $2 -n $1  -o yaml | grep cni.projectcalico.org > /dev/null`
}

# cluster all pods
podList=`kubectl get po -A | sed '1d'`

while read line; do
  namespace=`echo $line | awk '{print $1}'`
  podName=`echo $line | awk '{print $2}'`
  if `isCalicoPod $namespace $podName`; then
    podIP=`kubectl get po $podName -n $namespace -o yaml | egrep -w '^[[:space:]]+podIP' | awk -F : '{print $2}'`
    RES=$(echo $CALICO_IPS | grep -w $podIP | wc -l)
    if [ "$RES" -eq 0 ];then
      kubectl delete po ${podName} -n ${namespace}
    fi
  fi
done <<< "$(echo "$podList")"

# restart kube-proxy
echo "Restart kube-proxy..."
kubectl get po -n kube-system | grep kube-proxy | awk '{print $1}' | xargs kubectl delete po -n kube-system
util::wait_pod_ready "${KUBEPROXY_LABEL}" "${CALICO_NAMESPACE}" 300s
