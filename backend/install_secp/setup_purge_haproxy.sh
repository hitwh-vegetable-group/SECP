#!/bin/sh
echo "-----------------------------------------------------"
echo "欢迎使用SECP Cloud环境部署脚本 - 清理环境"
echo "在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo "-----------------------------------------------------"

# 清理 HA 服务
echo ">>  正在清理 HA 服务..."
systemctl stop keepalived
systemctl stop haproxy
rm -rf /var/lib/haproxy/*
rm -rf /etc/keepalived/*
apt-get purge -y keepalived haproxy
echo ">>  SECP Cloud 用户环境部署脚本部署完成！"