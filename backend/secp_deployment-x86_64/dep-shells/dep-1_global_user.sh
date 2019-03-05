# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh
#set -o errexit

echo ">>  -----------------------------------------------------"
echo ">>            欢迎使用 SECP Cloud 环境部署脚本"
echo ">>  在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo ">>  -----------------------------------------------------"

echo ">>  正在配置环境..."
cat ./hosts_append >> /etc/hosts
echo ">>  重启网络环境..."
systemctl restart networking
echo ">>  SECP Cloud 用户环境部署脚本部署完成！"
echo ">>  请务必保证所有节点均运行此脚本，"
echo ">>  之后在 Master 节点继续运行 dep-2_master.sh 开始部署 SECP Cloud 服务器集群！"