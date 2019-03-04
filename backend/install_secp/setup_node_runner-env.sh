#!/bin/sh
echo "欢迎使用SECP Cloud环境部署脚本 - 用户"
echo "在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo "-----------------------------------------------------"
echo "正在配置环境..."
# Env path
sh -c "echo 'PATH=/opt/k8s/bin:$PATH:$HOME/bin:$JAVA_HOME/bin' >>/root/.bashrc"
echo 'PATH=/opt/k8s/bin:$PATH:$HOME/bin:$JAVA_HOME/bin' >>~/.bashrc
apt-get install -y conntrack ipvsadm ipset jq sysstat curl iptables

# Firewall
echo ">>  现在关闭防火墙..."
systemctl stop firewalld
systemctl disable firewalld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
iptables -P FORWARD ACCEPT

# Swap off
echo ">>  现在关闭SWAP分区并取消自动挂载..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# SELinux Off
echo ">>  现在关闭SELinux..."
setenforce 0
grep SELINUX /etc/selinux/config

# Core
echo ">>  现在加载内核..."
modprobe br_netfilter
modprobe ip_vs

# NAT
echo ">>  现在修改NAT网桥设置..."
cp ./kubernetes.conf  /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf
mount -t cgroup -o cpu,cpuacct none /sys/fs/cgroup/cpu,cpuacct

# TimeZone
echo ">>  现在同步时间..."
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0
systemctl restart rsyslog 
systemctl restart crond
#apt-get install -y ntpdate
#ntpdate cn.pool.ntp.org

# Folders
echo ">>  现在创建必要文件夹结构..."
mkdir -p /opt/k8s/bin
mkdir -p /etc/kubernetes/cert
mkdir -p /etc/etcd/cert
mkdir -p /var/lib/etcd
echo ">>  SECP Cloud 用户环境部署脚本部署完成！"