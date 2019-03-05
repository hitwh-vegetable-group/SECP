#!/bin/sh
echo ">>  -----------------------------------------------------"
echo ">>       欢迎使用 SECP Cloud 环境部署脚本 - 清理环境"
echo ">>  在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo ">>  -----------------------------------------------------"

# 清理 HA 服务
echo ">>  正在清理 HA 服务..."
systemctl stop keepalived
systemctl stop haproxy
rm -rf /var/lib/haproxy
rm -rf /etc/keepalived
apt-get purge -y keepalived haproxy

# 清理 etcd 集群
echo ">>  正在清理 etcd 集群..."
systemctl stop etcd
rm -rf /var/lib/etcd
rm -rf /etc/systemd/system/etcd.service
rm -rf /opt/k8s/bin/etcd
rm -rf /etc/etcd
echo ">>> 重新加载系统守护者..."
systemctl daemon-reload

# 清理 Master 节点
echo ">>  正在清理 Master ..."
echo ">>> 停止服务..."
systemctl stop kube-apiserver kube-controller-manager kube-scheduler
rm -rf /var/run/kubernetes
rm -rf /etc/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler}.service
rm -rf /opt/k8s/bin/{kube-apiserver,kube-controller-manager,kube-scheduler}
rm -rf /etc/flanneld/cert /etc/kubernetes/cert
echo ">>> 重新加载系统守护者..."
systemctl daemon-reload

# 清理 Node 节点
echo ">>  正在清理 Node ..."
echo ">>> 停止服务..."
systemctl stop kubelet kube-proxy flanneld docker
rm -rf /var/lib/kubelet
rm -rf /var/run/flannel
rm -rf /etc/systemd/system/{kubelet,flanneld,docker}.service
rm -rf /root/kubernetes.conf
rm -rf /etc/sysctl.d/kubernetes.conf

# 删除 docker
echo ">>  清理 Docker..."
apt purge -y docker docker-ce docker-engine docker.io containerd runc
dpkg -P containerd.io
systemctl stop containerd
rm -rf /var/run/docker
rm -rf /usr/bin/docker
rm -rf /var/lib/docker
rm -rf /usr/share/bash-completion/completions/docker
rm -rf /etc/docker
rm -rf /run/containerd
rm -rf /var/lib/containerd
rm -rf /usr/bin/containerd
rm -rf /etc/containerd
rm -rf /opt/containerd

# 删除多余文件
echo ">>  正在清理部署 SECP Cloud 时生成的杂项..."
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
rm -rf /etc/flanneld/cert /etc/kubernetes/cert
rm -rf /opt/k8s
rm -rf /opt/containerd
rm -rf /usr/local/go
rm -rf /opt/go
# rm -rf /opt/secp_deployment-x86_64
userdel k8s
groupdel whell
clear
echo ">>  SECP Cloud 环境清理完成！请手动删除在 ~/.bashrc 中加入的环境变量！"
echo ">>  export PATH=.:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
echo ">>  等候5秒后打开 ~/.bashrc 若想取消请发送 ^C"
sleep 5
vi ~/.bashrc
