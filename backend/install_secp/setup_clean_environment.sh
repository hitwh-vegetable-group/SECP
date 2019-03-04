#!/bin/sh
echo "-----------------------------------------------------"
echo "欢迎使用SECP Cloud环境部署脚本 - 清理环境"
echo "在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo "-----------------------------------------------------"

# 清理 HA 服务
echo ">>  正在清理 HA 服务..."
systemctl stop keepalived
systemctl stop haproxy
rm -rf /var/lib/haproxy
rm -rf /etc/keepalived
apt-get purge -y keepalived haproxy

# 清理 etcd 集群
echo ">>  正在清理 etcd 集群..."
echo ">>> 停止 etcd 服务..."

# systemctl daemon-reload
systemctl stop etcd

# 删除 etcd 的工作目录和数据目录
rm -rf /var/lib/etcd

# 删除 systemd unit 文件
rm -rf /etc/systemd/system/etcd.service

# 删除程序文件
rm -rf /opt/k8s/bin/etcd

# 删除 x509 证书文件
rm -rf /etc/etcd/cert
echo ">>> 重新加载系统守护者..."
systemctl daemon-reload

# 清理 Master 节点
echo ">>  正在清理 Master ..."
echo ">>> 停止 kube-apiserver kube-controller-manager kube-scheduler 服务..."
systemctl stop kube-apiserver kube-controller-manager kube-scheduler

# 删除 kube-apiserver 工作目录
rm -rf /var/run/kubernetes

# 删除 systemd unit 文件
rm -rf /etc/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler}.service

# 删除程序文件
rm -rf /opt/k8s/bin/{kube-apiserver,kube-controller-manager,kube-scheduler}

# 删除证书文件
rm -rf /etc/flanneld/cert /etc/kubernetes/cert
echo ">>> 重新加载系统守护者..."
systemctl daemon-reload

# 清理 Node 节点
echo ">>  正在清理 Node ..."
echo ">>> 停止 kubelet kube-proxy flanneld ..."
systemctl stop kubelet kube-proxy flanneld

# 删除 kubelet 工作目录
rm -rf /var/lib/kubelet

# 删除 flanneld 写入的网络配置文件
rm -rf /var/run/flannel

# 删除 systemd unit 文件
rm -rf /etc/systemd/system/{kubelet,flanneld,docker}.service

# 删除 docker
echo ">>  清理 Docker..."
apt purge -y docker docker-ce docker-engine docker.io containerd runc
rm -rf /var/run/docker
rm -rf /usr/bin/docker
rm -rf /var/lib/docker
rm -rf /usr/share/bash-completion/completions/docker
rm -rf /etc/docker
echo ">>  正在清理部署 SECP Cloud 时生成的杂项..."

# iptables
#iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat

# 删除证书文件
rm -rf /etc/flanneld/cert /etc/kubernetes/cert

# 删除杂项文件
rm -rf /opt/k8s/*

# 删除用户组
userdel k8s
groupdel whell
echo ">>  SECP Cloud 用户环境清理完成！"
