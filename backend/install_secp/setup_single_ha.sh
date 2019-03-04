#!/bin/sh
#set -o errexit

echo "-----------------------------------------------------"
echo "欢迎使用SECP Cloud环境部署脚本 - 用户"
echo "在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo "-----------------------------------------------------"
echo "正在配置环境..."

# -----------------------------------------------------
# 分发节点初始化脚本
echo "\n>>  分发 node_runner-env 文件到每个节点..."

source environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 node_runner-env"
	mkdir -p /home/install_secp
    scp /home/install_secp/* root@${node_ip}:/home/install_secp
    ssh root@${node_ip} "cd /home/install_secp && chmod +x ./*.sh && ./setup_node_runner-env.sh"
  done

# -----------------------------------------------------
# 分发节点环境配置脚本
echo "\n>>  分发环境配置脚本到每个节点..."
source environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 environment.sh"
    scp environment.sh root@${node_ip}:/opt/k8s/bin/
    ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
  done

# -----------------------------------------------------
# 部署 HA 服务
echo "\n>>  部署 HA 服务..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 安装 KeepAlived 以及 HAProxy..."
    ssh root@${node_ip} "apt install -y keepalived haproxy"
  done
  
echo "\n>>  生成 HAProxy 配置文件..."
cd /opt/k8s
cat > haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /var/run/haproxy-admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    nbproc 1

defaults
    log     global
    timeout connect 5000
    timeout client  10m
    timeout server  10m

listen  admin_stats
    bind 0.0.0.0:10080
    mode http
    log 127.0.0.1 local0 err
    stats refresh 10s
    stats uri /status
    stats realm welcome login\ Haproxy
    stats auth admin:123456
    stats hide-version
    stats admin if TRUE

listen kube-master
    bind 0.0.0.0:8443
    mode tcp
    option tcplog
    balance source
    server 192.168.200.137 192.168.200.137:6443 check inter 2000 fall 2 rise 2 weight 1
    server 192.168.200.134 192.168.200.134:6443 check inter 2000 fall 2 rise 2 weight 1
    server 192.168.200.135 192.168.200.135:6443 check inter 2000 fall 2 rise 2 weight 1
EOF

echo "\n>>  分发 HAProxy 配置文件..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 HAProxy 配置文件..."
    scp ./haproxy.cfg root@${node_ip}:/etc/haproxy
  done
  
echo "\n>>  生成 KeepAlived - Master 配置文件..."
cd /opt/k8s

source /opt/k8s/bin/environment.sh
cat  > keepalived-master.conf <<EOF
global_defs {
    router_id becp_cloud
}

vrrp_script check-haproxy {
    script "killall -0 haproxy"
    interval 5
    weight -30
}

vrrp_instance VI-kube-master {
    state MASTER
    priority 120
    dont_track_primary
    interface ${VIP_IF}
    virtual_router_id 68
    advert_int 3
    track_script {
        check-haproxy
    }
    virtual_ipaddress {
        ${MASTER_VIP}
    }
}
EOF

echo "\n>>  生成 KeepAlived - Backup 配置文件..."
cd /opt/k8s

source /opt/k8s/bin/environment.sh
cat  > keepalived-backup.conf <<EOF
global_defs {
    router_id becp_cloud-backup
}

vrrp_script check-haproxy {
    script "killall -0 haproxy"
    interval 5
    weight -30
}

vrrp_instance VI-kube-master {
    state BACKUP
    priority 110
    dont_track_primary
    interface ${VIP_IF}
    virtual_router_id 68
    advert_int 3
    track_script {
        check-haproxy
    }
    virtual_ipaddress {
        ${MASTER_VIP}
    }
}
EOF

echo "\n>>  分发 KeepAlived - Master/Backup 配置文件..."
scp keepalived-master.conf root@192.168.200.137:/etc/keepalived/keepalived.conf
scp keepalived-backup.conf root@192.168.200.134:/etc/keepalived/keepalived.conf
scp keepalived-backup.conf root@192.168.200.135:/etc/keepalived/keepalived.conf

echo "\n>>  启动 HAProxy ..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 启动 HAProxy 服务..."
    ssh root@${node_ip} "systemctl restart haproxy"
  done

echo "\n>>  检视 HAProxy 状态..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 检视 HAProxy 状态..."
    ssh root@${node_ip} "systemctl status haproxy|grep Active"
	ssh root@${node_ip} "netstat -lnpt|grep haproxy"
  done

echo "\n>>  启动 KeepAlived ..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 启动 KeepAlived 服务..."
    ssh root@${node_ip} "systemctl restart keepalived"
  done

echo "\n>>  检视 KeepAlived 状态..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 检视 KeepAlived 状态..."
    ssh root@${node_ip} "systemctl status keepalived|grep Active"
	ssh root@${node_ip} "ip addr show ${VIP_IF}"
    ssh root@${node_ip} "ping -c 1 ${MASTER_VIP}"
  done