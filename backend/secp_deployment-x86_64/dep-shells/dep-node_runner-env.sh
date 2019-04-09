#!/bin/sh
echo ">>  -----------------------------------------------------"
echo ">>          SECP Cloud 环境部署脚本 - 节点环境配置 "
echo ">>               此脚本不应该被用户自行运行！"
echo ">>  -----------------------------------------------------"
sleep 1
echo ">>  正在配置环境..."

echo '# SECP Cloud Environment Variables' >>~/.bashrc
echo 'PATH=/opt/k8s/bin:$PATH:$HOME/bin:$JAVA_HOME/bin' >>~/.bashrc
#echo 'GOROOT=/usr/local/go' >>~/.bashrc
#echo 'GOPATH=/opt/k8s/bin/gopath' >>~/.bashrc
#echo 'PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >>~/.bashrc
echo 'SECP_DEPPATH=/opt/secp_deployment-x86_64' >>~/.bashrc

apt-get install -y conntrack ipvsadm ipset jq sysstat curl iptables

echo ">>  现在关闭防火墙..."
systemctl stop firewalld
systemctl disable firewalld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
iptables -P FORWARD ACCEPT

echo ">>  现在关闭SWAP分区并取消自动挂载..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo ">>  现在关闭SELinux..."
setenforce 0
grep SELINUX /etc/selinux/config

echo ">>  现在加载内核..."
modprobe br_netfilter
modprobe ip_vs

echo ">>  现在修改NAT网桥设置..."
cp ./kubernetes.conf  /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf
mount -t cgroup -o cpu,cpuacct none /sys/fs/cgroup/cpu,cpuacct

echo ">>  现在同步时间..."
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0
systemctl restart rsyslog 
systemctl restart crond

echo ">>  现在创建必要文件夹结构..."
mkdir -p /opt/secp_deployment-x86_64/dep-components/cfssl
mkdir -p /opt/secp_deployment-x86_64/dep-components/docker/images
mkdir -p /opt/secp_deployment-x86_64/dep-components/etcd
mkdir -p /opt/secp_deployment-x86_64/dep-components/flanneld
mkdir -p /opt/secp_deployment-x86_64/dep-components/golang
mkdir -p /opt/secp_deployment-x86_64/dep-components/kubernetes
mkdir -p /opt/secp_deployment-x86_64/dep-services/bt-panel
mkdir -p /opt/secp_deployment-x86_64/dep-services/monitor
mkdir -p /opt/secp_deployment-x86_64/dep-shells
mkdir -p /opt/k8s/bin
mkdir -p /etc/kubernetes/cert
mkdir -p /etc/etcd/cert
mkdir -p /var/lib/etcd
cp ./environment.sh /opt/k8s/bin && chmod +x /opt/k8s/bin/*
echo ">>  SECP Cloud 节点环境配置完成！"
sleep 1