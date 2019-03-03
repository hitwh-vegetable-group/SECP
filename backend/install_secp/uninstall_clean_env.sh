#!/bin/sh

# 清理 etcd 集群
systemctl daemon-reload
systemctl stop etcd
# 删除 etcd 的工作目录和数据目录
rm -rf /var/lib/etcd
# 删除 systemd unit 文件
rm -rf /etc/systemd/system/etcd.service
# 删除程序文件
rm -rf /opt/k8s/bin/etcd
# 删除 x509 证书文件
rm -rf /etc/etcd/cert/*

# 清理 Master 节点
systemctl daemon-reload
systemctl stop kube-apiserver kube-controller-manager kube-scheduler
# 删除 kube-apiserver 工作目录
rm -rf /var/run/kubernetes
# 删除 systemd unit 文件
rm -rf /etc/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler}.service
# 删除程序文件
rm -rf /opt/k8s/bin/{kube-apiserver,kube-controller-manager,kube-scheduler}
# 删除证书文件
rm -rf /etc/flanneld/cert /etc/kubernetes/cert

# 清理 Node 节点
systemctl daemon-reload
systemctl stop kubelet kube-proxy flanneld
# umount kubelet 挂载的目录
# mount | grep '/var/lib/kubelet'| awk '{print $3}'|xargs sudo umount
# 删除 kubelet 工作目录
rm -rf /var/lib/kubelet
# 删除 docker 工作目录
# rm -rf /var/lib/docker
# 删除 flanneld 写入的网络配置文件
rm -rf /var/run/flannel/
# 删除 docker 的一些运行文件
# rm -rf /var/run/docker/
# 删除 systemd unit 文件
rm -rf /etc/systemd/system/{kubelet,flanneld}.service
# 删除程序文件
rm -rf /opt/k8s/bin/*
# 删除证书文件
rm -rf /etc/flanneld/cert /etc/kubernetes/cert

# 删除杂项文件
rm -rf /opt/k8s

# 删除用户组
userdel k8s
groupdel whell
