#!/bin/sh
echo "-----------------------------------------------------"
echo "欢迎使用SECP Cloud环境部署脚本 - 脚本更新"
echo "在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo "-----------------------------------------------------"

echo ">>  删除所有文件."
rm -rf * 
echo ">>  等待重新上传..."
rz
echo ">>  转换Unix换行符..."
dos2unix * 
echo ">>  添加可执行权限..."
chmod +x ./*.sh
echo ">>  分发部署脚本..."
source /opt/secp_deployment-x86_64/dep-shells/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip}"
	ssh root@${node_ip} "mkdir -p /opt/secp_deployment-x86_64/dep-shells"
    scp ${SECP_DEP_SHELLS}/* root@${node_ip}:${SECP_DEP_SHELLS}
    ssh root@${node_ip} "cd /opt/secp_deployment-x86_64/dep-shells && chmod +x ./*.sh"
  done
echo ">>  SECP Cloud 用户环境部署脚本部署完成！"