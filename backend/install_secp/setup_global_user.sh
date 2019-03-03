#!/bin/sh
echo "欢迎使用SECP Cloud环境部署脚本 - 用户"
echo "在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo "-----------------------------------------------------"
echo "正在配置环境..."

# Add Hosts
cat ./hosts_append >> /etc/hosts
echo "重启网络环境..."
systemctl restart networking

# Add Docker config
mkdir -p  /etc/docker/
touch /etc/docker/daemon.json
cat ./daemon.json >> /etc/docker/daemon.json