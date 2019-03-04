#!/bin/sh
#set -o errexit

echo "-----------------------------------------------------"
echo "欢迎使用SECP Cloud环境部署脚本 - 用户"
echo "在Ansible做成之前，您将持续使用此脚本配置后台基本环境"
echo "-----------------------------------------------------"
echo "正在配置环境..."
echo ">>  非第一次配置时尝试清理Docker..."
apt purge -y docker docker-ce docker-engine docker.io containerd runc

# -----------------------------------------------------
# 授权免密登录其他节点
echo "\n>>  生成RSA证书用于免密登陆部署其他节点..."
ssh-keygen -t rsa
echo "\n>>  配置 Master 节点的 root 免密登录..."
ssh-copy-id root@secp-master
echo "\n>>  配置 Node1 节点的 root 免密登录..."
ssh-copy-id root@secp-node1
echo "\n>>  配置 Node2 节点的 root 免密登录..."
ssh-copy-id root@secp-node2

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
# 签署 CA 根域名证书
echo "\n>>  签署 CA 根域名证书..."
mkdir -p /opt/k8s/cert
cd /opt/k8s/bin

echo "\n>>  请上传CFSSL工具集."
rz

#echo "\n>>  获取CFSSL工具集..."
#wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
#mv cfssl_linux-amd64 /opt/k8s/bin/cfssl

#wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
#mv cfssljson_linux-amd64 /opt/k8s/bin/cfssljson

#wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
#mv cfssl-certinfo_linux-amd64 /opt/k8s/bin/cfssl-certinfo

cd /opt/k8s/
chmod +x /opt/k8s/bin/*
export PATH=/opt/k8s/bin:$PATH

#TODOS
# profiles: hitwhvg-secp
# user: root
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "hitwhvg-secp": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Weihai",
      "L": "Weihai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

echo "\n>>  生成证书..."
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
echo "\n>>  生成证书结果如下:"
ls ca*

echo "\n>>  分发 CA 根域名证书..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 CA 根域名证书..."
    ssh root@${node_ip} "mkdir -p /etc/kubernetes/cert"
    scp ca*.pem ca-config.json root@${node_ip}:/etc/kubernetes/cert
  done

# -----------------------------------------------------  
# 部署 kubectl
echo "\n>>  部署 kubectl..."
cd /home/k8s
tar -zxvf hitwhvg-kubernetes-utils.tar.gz

echo "\n>>  分发 kubectl..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 kubectl..."
    scp ./kubectl root@${node_ip}:/opt/k8s/bin/
    ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
  done
  
echo "\n>>  创建 admin 证书和私钥..."
cd /opt/k8s
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Weihai",
      "L": "Weihai",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF

echo "\n>>  生成证书..."
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=hitwhvg-secp admin-csr.json | cfssljson -bare admin
echo "\n>>  生成证书结果如下:"
ls admin*

echo "\n>>  配置 kubeconfig ..."
source /opt/k8s/bin/environment.sh
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kubectl.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=kubectl.kubeconfig
# 设置上下文参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=kubectl.kubeconfig
# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig

echo "\n>>  分发 kubeconfig ..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 kubeconfig..."
    ssh root@${node_ip} "mkdir -p ~/.kube"
    scp kubectl.kubeconfig root@${node_ip}:~/.kube/config
  done

# -----------------------------------------------------  
# 部署 ETCD  
echo "\n>>  部署 etcd 集群..."
cd /home/etcd
tar -zxvf hitwhvg-etcd-utils.tar.gz

echo "\n>>  分发 etcd 组件..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 etcd 组件..."
    scp ./etcd* root@${node_ip}:/opt/k8s/bin
    ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
  done
  
echo "\n>>  签署 etcd 证书..."
cd /opt/k8s
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "192.168.200.137",
    "192.168.200.134",
    "192.168.200.135",
	"secp-master",
	"secp-node1",
	"secp-node2"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Weihai",
      "L": "Weihai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

echo "\n>>  生成证书..."
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
    -ca-key=/etc/kubernetes/cert/ca-key.pem \
    -config=/etc/kubernetes/cert/ca-config.json \
    -profile=hitwhvg-secp etcd-csr.json | cfssljson -bare etcd
echo "\n>>  生成证书结果如下:"
ls etcd*

echo "\n>>  分发证书..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发证书..."
    ssh root@${node_ip} "mkdir -p /etc/etcd/cert"
    scp etcd*.pem root@${node_ip}:/etc/etcd/cert/
  done
  
echo "\n>>  创建 etcd.service 服务..."
source /opt/k8s/bin/environment.sh
cat > etcd.service.template <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
User=root
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/opt/k8s/bin/etcd \\
  --data-dir=/var/lib/etcd \\
  --name=##NODE_NAME## \\
  --cert-file=/etc/etcd/cert/etcd.pem \\
  --key-file=/etc/etcd/cert/etcd-key.pem \\
  --trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
  --peer-cert-file=/etc/etcd/cert/etcd.pem \\
  --peer-key-file=/etc/etcd/cert/etcd-key.pem \\
  --peer-trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls=https://##NODE_IP##:2380 \\
  --initial-advertise-peer-urls=https://##NODE_IP##:2380 \\
  --listen-client-urls=https://##NODE_IP##:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://##NODE_IP##:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=${ETCD_NODES} \\
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

source /opt/k8s/bin/environment.sh
for (( i=0; i < 3; i++ ))
  do
    sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" etcd.service.template > etcd-${NODE_IPS[i]}.service 
  done
ls *.service

echo "\n>>  分发 etcd.service 服务..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 etcd.service 服务..."
    ssh root@${node_ip} "mkdir -p /var/lib/etcd" 
    scp etcd-${node_ip}.service root@${node_ip}:/etc/systemd/system/etcd.service
  done

echo "\n>>  启动 etcd ..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 执行操作中,由于要重新加载系统守护者，所以过程缓慢，请耐心等待..."
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd&"
  done
  
echo "\n>>  睡眠5s后再发起 etcd 集群状态查询..."
sleep 5
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 节点 root@${node_ip} 的 etcd 服务状态如下:"
    ssh root@${node_ip} "systemctl status etcd|grep Active"
  done
  
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> etcd 集群状态如下:"
    ETCDCTL_API=3 /opt/k8s/bin/etcdctl \
    --endpoints=https://${node_ip}:2379 \
    --cacert=/etc/kubernetes/cert/ca.pem \
    --cert=/etc/etcd/cert/etcd.pem \
    --key=/etc/etcd/cert/etcd-key.pem endpoint health
  done

# -----------------------------------------------------    
# 部署 flanneld
echo "\n>>  部署 flanneld ..."
cd /home/flanneld
tar -zxvf hitwhvg-flanneld-utils.tar.gz

echo "\n>>  分发 FLANNELD ..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 FLANNELD ..."
    scp ./{flanneld,mk-docker-opts.sh} root@${node_ip}:/opt/k8s/bin/
    ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
  done

echo "\n>>  签署证书..."
cd /opt/k8s
cat > flanneld-csr.json <<EOF
{
  "CN": "flanneld",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Weihai",
      "L": "Weihai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

echo "\n>>  生成证书..."
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=hitwhvg-secp flanneld-csr.json | cfssljson -bare flanneld
echo "\n>>  生成证书结果如下:"
ls flanneld*pem

echo "\n>>  分发 FLANNELD 证书..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 FLANNELD 证书..."
    ssh root@${node_ip} "mkdir -p /etc/flanneld/cert"
    scp flanneld*.pem root@${node_ip}:/etc/flanneld/cert
  done
  
echo "\n>>  检视状态..."
source /opt/k8s/bin/environment.sh
etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/cert/ca.pem \
  --cert-file=/etc/flanneld/cert/flanneld.pem \
  --key-file=/etc/flanneld/cert/flanneld-key.pem \
  set ${FLANNEL_ETCD_PREFIX}/config '{"Network":"'${CLUSTER_CIDR}'", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'
  
echo "\n>>  创建 flanneld.service 服务..."
source /opt/k8s/bin/environment.sh
export IFACE=${VIP_IF}
cat > flanneld.service << EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=/opt/k8s/bin/flanneld \\
  -etcd-cafile=/etc/kubernetes/cert/ca.pem \\
  -etcd-certfile=/etc/flanneld/cert/flanneld.pem \\
  -etcd-keyfile=/etc/flanneld/cert/flanneld-key.pem \\
  -etcd-endpoints=${ETCD_ENDPOINTS} \\
  -etcd-prefix=${FLANNEL_ETCD_PREFIX} \\
  -iface=${IFACE}
ExecStartPost=/opt/k8s/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF

echo "\n>>  分发 flanneld.service 服务..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 flanneld.service 服务..."
    scp flanneld.service root@${node_ip}:/etc/systemd/system/
  done
  
echo "\n>>  启动 FLANNELD ..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable flanneld && systemctl restart flanneld"
  done
  
echo "\n>>  检视 FLANNELD 状态..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 节点 root@${node_ip} 的 FLANNELD 服务状态如下:"
    ssh root@${node_ip} "systemctl status flanneld|grep Active"
  done
  
source /opt/k8s/bin/environment.sh
etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/cert/ca.pem \
  --cert-file=/etc/flanneld/cert/flanneld.pem \
  --key-file=/etc/flanneld/cert/flanneld-key.pem \
  get ${FLANNEL_ETCD_PREFIX}/config
  
source /opt/k8s/bin/environment.sh
etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/cert/ca.pem \
  --cert-file=/etc/flanneld/cert/flanneld.pem \
  --key-file=/etc/flanneld/cert/flanneld-key.pem \
  ls ${FLANNEL_ETCD_PREFIX}/subnets
  
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "ip addr show flannel.1|grep -w inet"
  done

# -----------------------------------------------------
# 部署Master节点
echo "\n>>  部署 Master 节点..."
cd /home/k8s
mkdir ./server
mv kube-apiserver kube-scheduler kube-controller-manager ./server

echo "\n>>  正在分发 Kubernetes 服务端二进制文件..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 Kubernetes 服务端二进制文件..."
    scp ./server/* root@${node_ip}:/opt/k8s/bin/
	scp /home/k8s/kubeadm root@${node_ip}:/opt/k8s/bin
	scp /home/k8s/kubelet root@${node_ip}:/opt/k8s/bin
	scp /home/k8s/kube-proxy root@${node_ip}:/opt/k8s/bin
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
	ssh root@${node_ip} "mkdir -p /etc/keepalived/"
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

# -----------------------------------------------------
# 部署APISERVER
echo "\n>>  部署 kube-apiserver ..."
# 创建 kubernetes 证书
echo "\n>>  创建证书..."
cd /opt/k8s
source /opt/k8s/bin/environment.sh
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "localhost",
    "127.0.0.1",
    "192.168.200.137",
    "192.168.200.134",
    "192.168.200.135",
    "secp-master",
    "secp-node1",
	"secp-node2",
    "${MASTER_VIP}",
    "${CLUSTER_KUBERNETES_SVC_IP}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Weihai",
      "L": "Weihai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

echo "\n>>  生成证书..."
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=hitwhvg-secp kubernetes-csr.json | cfssljson -bare kubernetes
echo "\n>>  生成证书结果如下:"
ls kubernetes*pem

echo "\n>>  分发证书..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发证书..."
    ssh root@${node_ip} "mkdir -p /etc/kubernetes/cert/"
    scp kubernetes*.pem root@${node_ip}:/etc/kubernetes/cert/
  done
  
echo "\n>>  创建加密配置文件..."
source /opt/k8s/bin/environment.sh
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

echo "\n>>  分发加密配置文件..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发加密配置文件..."
    scp encryption-config.yaml root@${node_ip}:/etc/kubernetes/
  done
  
echo "\n>>  创建 kube-apiserver.service 服务配置..."
source /opt/k8s/bin/environment.sh
cat > kube-apiserver.service.template <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
ExecStart=/opt/k8s/bin/kube-apiserver \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --anonymous-auth=false \\
  --experimental-encryption-provider-config=/etc/kubernetes/encryption-config.yaml \\
  --advertise-address=##NODE_IP## \\
  --bind-address=##NODE_IP## \\
  --insecure-port=0 \\
  --authorization-mode=Node,RBAC \\
  --runtime-config=api/all \\
  --enable-bootstrap-token-auth \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=${NODE_PORT_RANGE} \\
  --tls-cert-file=/etc/kubernetes/cert/kubernetes.pem \\
  --tls-private-key-file=/etc/kubernetes/cert/kubernetes-key.pem \\
  --client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --kubelet-client-certificate=/etc/kubernetes/cert/kubernetes.pem \\
  --kubelet-client-key=/etc/kubernetes/cert/kubernetes-key.pem \\
  --service-account-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --etcd-cafile=/etc/kubernetes/cert/ca.pem \\
  --etcd-certfile=/etc/etcd/cert/etcd.pem \\
  --etcd-keyfile=/etc/etcd/cert/etcd-key.pem \\
  --etcd-servers=${ETCD_ENDPOINTS} \\
  --enable-swagger-ui=true \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/kube-apiserver-audit.log \\
  --event-ttl=1h \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2
Restart=on-failure
RestartSec=5
Type=notify
User=root
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

source /opt/k8s/bin/environment.sh
for (( i=0; i < 3; i++ ))
  do
    sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-apiserver.service.template > kube-apiserver-${NODE_IPS[i]}.service 
  done
ls kube-apiserver*.service

echo "\n>>  分发 kube-apiserver.service 服务配置..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 分发 kube-apiserver.service 服务配置..."
    ssh root@${node_ip} "mkdir -p /var/log/kubernetes"
    scp kube-apiserver-${node_ip}.service root@${node_ip}:/etc/systemd/system/kube-apiserver.service
  done
 
echo "\n>>  启动 kube-apiserver.service..." 
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-apiserver && systemctl restart kube-apiserver"
  done

echo "\n>>  检视 kube-apiserver.service 服务运行状态..."   
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 节点 root@${node_ip} 的服务状态如下:"
    ssh root@${node_ip} "systemctl status kube-apiserver |grep 'Active:'"
  done
  
#source /opt/k8s/bin/environment.sh
#ETCDCTL_API=3 etcdctl \
#    --endpoints=${ETCD_ENDPOINTS} \
#    --cacert=/etc/kubernetes/cert/ca.pem \
#    --cert=/etc/etcd/cert/etcd.pem \
#    --key=/etc/etcd/cert/etcd-key.pem \
#    get /registry/ --prefix --keys-only
	
echo ">>  现在请检查集群信息！"
kubectl cluster-info
kubectl get all --all-namespaces
kubectl get componentstatuses

echo ">>  授予 kubernetes 证书访问 kubelet API 的权限..."
kubectl create clusterrolebinding \
  kube-apiserver:kubelet-apis \
  --clusterrole=system:kubelet-api-admin \
  --user kubernetes
echo ">>  SECP Cloud 用户环境部署脚本部署完成！"

# -----------------------------------------------------
# 部署 kube-controller-manager
echo ">> 创建证书..."
cd /opt/k8s
cat > kube-controller-manager-csr.json <<EOF
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "localhost",
      "127.0.0.1",
      "192.168.200.137",
      "192.168.200.134",
      "192.168.200.135",
      "secp-master",
      "secp-node1",
	  "secp-node2"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "Weihai",
        "L": "Weihai",
        "O": "system:kube-controller-manager",
        "OU": "System"
      }
    ]
}
EOF

echo ">>  生成证书..."
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=hitwhvg-secp kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
  
echo ">>  分发证书..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp kube-controller-manager*.pem root@${node_ip}:/etc/kubernetes/cert/
  done

echo ">>  创建并分发 kubeconfig 文件..."
source /opt/k8s/bin/environment.sh
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp kube-controller-manager.kubeconfig root@${node_ip}:/etc/kubernetes/
  done
  
echo ">>  创建并分发 kube-controller-manager systemd unit 文件..."
source /opt/k8s/bin/environment.sh
cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/opt/k8s/bin/kube-controller-manager \\
  --port=0 \\
  --secure-port=10252 \\
  --bind-address=127.0.0.1 \\
  --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/etc/kubernetes/cert/ca.pem \\
  --cluster-signing-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --experimental-cluster-signing-duration=87600h \\
  --root-ca-file=/etc/kubernetes/cert/ca.pem \\
  --service-account-private-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --leader-elect=true \\
  --feature-gates=RotateKubeletServerCertificate=true \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --horizontal-pod-autoscaler-use-rest-clients=true \\
  --horizontal-pod-autoscaler-sync-period=10s \\
  --tls-cert-file=/etc/kubernetes/cert/kube-controller-manager.pem \\
  --tls-private-key-file=/etc/kubernetes/cert/kube-controller-manager-key.pem \\
  --use-service-account-credentials=true \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2
Restart=on
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp kube-controller-manager.service root@${node_ip}:/etc/systemd/system/
  done
  
echo ">>  启动 kube-controller-manager 服务..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "mkdir -p /var/log/kubernetes"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-controller-manager && systemctl restart kube-controller-manager"
  done
 
echo ">>  检查 kube-controller-manager 服务运行状态..." 
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "systemctl status kube-controller-manager|grep Active"
  done
netstat -lnpt|grep kube-controll

echo ">>  查看当前的 leader..."
kubectl get endpoints kube-controller-manager --namespace=kube-system  -o yaml
echo ">>  注意：请手动停掉一个或两个节点的 kube-controller-manager 服务"
echo ">>  观察其它节点的日志，看是否获取了 leader 权限。"
echo ">>  等待5秒后继续..."
sleep 5

# -----------------------------------------------------
# 部署 kube-scheduler
echo ">> 创建证书..."
cd /opt/k8s
cat > kube-scheduler-csr.json <<EOF
{
    "CN": "system:kube-scheduler",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "localhost",
      "127.0.0.1",
      "192.168.200.137",
      "192.168.200.134",
      "192.168.200.135",
      "secp-master",
      "secp-node1",
	  "secp-node2"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "Weihai",
        "L": "Weihai",
        "O": "system:kube-scheduler",
        "OU": "System"
      }
    ]
}
EOF

echo ">>  生成证书..."
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=hitwhvg-secp kube-scheduler-csr.json | cfssljson -bare kube-scheduler
  
echo ">>  分发证书..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp kube-scheduler*.pem root@${node_ip}:/etc/kubernetes/cert/
  done

echo ">>  创建并分发 kubeconfig 文件..."
source /opt/k8s/bin/environment.sh
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-context system:kube-scheduler \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp kube-scheduler.kubeconfig root@${node_ip}:/etc/kubernetes/
  done
  
echo ">>  创建并分发 kube-scheduler systemd unit 文件..."
source /opt/k8s/bin/environment.sh
cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/opt/k8s/bin/kube-scheduler \\
  --address=127.0.0.1 \\
  --kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
  --leader-elect=true \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp kube-scheduler.service root@${node_ip}:/etc/systemd/system/
  done
  
echo ">>  启动 kube-scheduler 服务..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "mkdir -p /var/log/kubernetes"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-scheduler && systemctl restart kube-scheduler"
  done
 
echo ">>  检查 kube-scheduler 服务运行状态..." 
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "systemctl status kube-scheduler|grep Active"
  done
netstat -lnpt|grep kube-sche

echo ">>  查看当前的 leader..."
kubectl get endpoints kube-scheduler --namespace=kube-system  -o yaml
echo ">>  注意：请手动停掉一个或两个节点的 kube-controller-manager 服务"
echo ">>  观察其它节点的日志，看是否获取了 leader 权限。"
echo ">>  等待5秒后继续..."
sleep 5

# -----------------------------------------------------
# 部署 docker
echo ">>  部署 docker ..."
cd /home/docker
tar -zxvf hitwhvg-docker-utils.tgz

echo ">>  分发 docker ..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp ./docker/docker*  root@${node_ip}:/opt/k8s/bin/
    ssh root@${node_ip} "chmod +x /opt/k8s/bin/*"
  done

echo ">>  创建和分发 systemd unit 文件..."
cd /opt/k8s
cat > docker.service <<"EOF"
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
Environment="PATH=/opt/k8s/bin:/bin:/sbin:/usr/bin:/usr/sbin"
EnvironmentFile=-/run/flannel/docker
ExecStart=/opt/k8s/bin/dockerd --log-level=error $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    scp docker.service root@${node_ip}:/etc/systemd/system/
	ssh root@${node_ip} "iptables -P FORWARD ACCEPT && cat 'iptables -P FORWARD ACCEPT' > /etc/rc.local"
	ssh root@${node_ip} "mkdir -p  /etc/docker/"
	scp /home/install_secp/daemon.json root@${node_ip}:/etc/docker/daemon.json
  done
  
echo ">>  启动 docker 服务..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "systemctl stop firewalld && systemctl disable firewalld"
    ssh root@${node_ip} "iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat"
    ssh root@${node_ip} "iptables -P FORWARD ACCEPT"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable docker && systemctl restart docker"
    ssh root@${node_ip} 'for intf in /sys/devices/virtual/net/docker0/brif/*; do echo 1 > $intf/hairpin_mode; done'
    ssh root@${node_ip} "sysctl -p /etc/sysctl.d/kubernetes.conf"
  done

echo ">>  检查服务运行状态..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> 对节点 root@${node_ip} 操作中..."
    ssh root@${node_ip} "systemctl status docker|grep Active"
  done
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "ip addr show flannel.1 && ip addr show docker0"
  done
  
echo ">>  SECP Cloud 部署完成！"

# -----------------------------------------------------
# 部署 kubelet
echo ">>  创建 kubelet bootstrap kubeconfig 文件..."
cd /opt/k8s
source /opt/k8s/bin/environment.sh
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name} 操作中..."
	
    # 创建 token
    export BOOTSTRAP_TOKEN=$(kubeadm token create \
      --description kubelet-bootstrap-token \
      --groups system:bootstrappers:${node_name} \
      --kubeconfig ~/.kube/config)

    # 设置集群参数
    kubectl config set-cluster kubernetes \
      --certificate-authority=/etc/kubernetes/cert/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

    # 设置客户端认证参数
    kubectl config set-credentials kubelet-bootstrap \
      --token=${BOOTSTRAP_TOKEN} \
      --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

    # 设置上下文参数
    kubectl config set-context default \
      --cluster=kubernetes \
      --user=kubelet-bootstrap \
      --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

    # 设置默认上下文
    kubectl config use-context default --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
  done
kubeadm token list --kubeconfig ~/.kube/config
kubectl get secrets  -n kube-system

echo ">>  分发 bootstrap kubeconfig 文件到所有 worker 节点..."
source /opt/k8s/bin/environment.sh
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    scp kubelet-bootstrap-${node_name}.kubeconfig root@${node_name}:/etc/kubernetes/kubelet-bootstrap.kubeconfig
  done
  
echo ">>  创建和分发 kubelet 参数配置文件..."
cd /opt/k8s
source /opt/k8s/bin/environment.sh
cat > kubelet.config.json.template <<EOF
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "authentication": {
    "x509": {
      "clientCAFile": "/etc/kubernetes/cert/ca.pem"
    },
    "webhook": {
      "enabled": true,
      "cacheTTL": "2m0s"
    },
    "anonymous": {
      "enabled": false
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "address": "##NODE_IP##",
  "port": 10250,
  "readOnlyPort": 0,
  "cgroupDriver": "cgroupfs",
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientCertificate": true,
    "RotateKubeletServerCertificate": true
  },
  "clusterDomain": "${CLUSTER_DNS_DOMAIN}",
  "clusterDNS": ["${CLUSTER_DNS_SVC_IP}"]
}
EOF
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do 
    echo ">>> ${node_ip}"
    sed -e "s/##NODE_IP##/${node_ip}/" kubelet.config.json.template > kubelet.config-${node_ip}.json
    scp kubelet.config-${node_ip}.json root@${node_ip}:/etc/kubernetes/kubelet.config.json
  done
  
echo ">>  创建和分发 kubelet systemd unit 文件..."
cat > kubelet.service.template <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=/opt/k8s/bin/kubelet \\
  --bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.kubeconfig \\
  --cert-dir=/etc/kubernetes/cert \\
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \\
  --config=/etc/kubernetes/kubelet.config.json \\
  --hostname-override=##NODE_NAME## \\
  --pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest \\
  --allow-privileged=true \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
source /opt/k8s/bin/environment.sh
for node_name in ${NODE_NAMES[@]}
  do 
    echo ">>> ${node_name}"
    sed -e "s/##NODE_NAME##/${node_name}/" kubelet.service.template > kubelet-${node_name}.service
    scp kubelet-${node_name}.service root@${node_name}:/etc/systemd/system/kubelet.service
  done
  
echo ">>  Bootstrap Token Auth 和授予权限..."
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --group=system:bootstrappers

echo ">>  启动 kubelet 服务..."
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "mkdir -p /var/lib/kubelet"
    ssh root@${node_ip} "swapoff -a"
    ssh root@${node_ip} "mkdir -p /var/log/kubernetes"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kubelet && systemctl restart kubelet"
  done
kubectl get csr

echo ">>  自动 approve CSR 请求..."
cd /opt/k8s
cat > csr-crb.yaml <<EOF
 # Approve all CSRs for the group "system:bootstrappers"
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: auto-approve-csrs-for-group
 subjects:
 - kind: Group
   name: system:bootstrappers
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
   apiGroup: rbac.authorization.k8s.io
---
 # To let a node of the group "system:nodes" renew its own credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-client-cert-renewal
 subjects:
 - kind: Group
   name: system:nodes
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
   apiGroup: rbac.authorization.k8s.io
---
# A ClusterRole which instructs the CSR approver to approve a node requesting a
# serving cert matching its client cert.
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: approve-node-server-renewal-csr
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
---
 # To let a node of the group "system:nodes" renew its own server credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-server-cert-renewal
 subjects:
 - kind: Group
   name: system:nodes
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: approve-node-server-renewal-csr
   apiGroup: rbac.authorization.k8s.io
EOF
kubectl apply -f csr-crb.yaml

echo "请等待三个节点的 CSR 被自动 approve..."
echo "休息一分钟吧！"
sleep 60
kubectl get csr
kubectl get nodes
echo "请检查节点是否 Ready ，如果否请立刻查明原因！（等待5秒...）"
sleep 5
kubectl create sa kubelet-api-test
kubectl create clusterrolebinding kubelet-api-test --clusterrole=system:kubelet-api-admin --serviceaccount=default:kubelet-api-test












# -----------------------------------------------------
# 部署 kube-proxy
echo ">>  部署 kube-proxy 组件..."

cd /k8s/bin
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Weihai",
      "L": "Weihai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=hitwhvg-secp  kube-proxy-csr.json | cfssljson -bare kube-proxy
  
  
  
source /opt/k8s/bin/environment.sh
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

source /opt/k8s/bin/environment.sh
for node_name in ${NODE_NAMES[@]}
  do
    echo ">>> ${node_name}"
    scp kube-proxy.kubeconfig root@${node_name}:/etc/kubernetes/
  done
  
cat >kube-proxy.config.yaml.template <<EOF
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: ##NODE_IP##
clientConnection:
  kubeconfig: /etc/kubernetes/kube-proxy.kubeconfig
clusterCIDR: ${CLUSTER_CIDR}
healthzBindAddress: ##NODE_IP##:10256
hostnameOverride: ##NODE_NAME##
kind: KubeProxyConfiguration
metricsBindAddress: ##NODE_IP##:10249
mode: "ipvs"
EOF

source /opt/k8s/bin/environment.sh
for (( i=0; i < 3; i++ ))
  do 
    echo ">>> ${NODE_NAMES[i]}"
    sed -e "s/##NODE_NAME##/${NODE_NAMES[i]}/" -e "s/##NODE_IP##/${NODE_IPS[i]}/" kube-proxy.config.yaml.template > kube-proxy-${NODE_NAMES[i]}.config.yaml
    scp kube-proxy-${NODE_NAMES[i]}.config.yaml root@${NODE_NAMES[i]}:/etc/kubernetes/kube-proxy.config.yaml
  done
  
  
source /opt/k8s/bin/environment.sh
cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=/var/lib/kube-proxy
ExecStart=/opt/k8s/bin/kube-proxy \\
  --config=/etc/kubernetes/kube-proxy.config.yaml \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

source /opt/k8s/bin/environment.sh
for node_name in ${NODE_NAMES[@]}
  do 
    echo ">>> ${node_name}"
    scp kube-proxy.service root@${node_name}:/etc/systemd/system/
  done
  
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "mkdir -p /var/lib/kube-proxy"
    ssh root@${node_ip} "mkdir -p /var/log/kubernetes"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable kube-proxy && systemctl restart kube-proxy"
  done
source /opt/k8s/bin/environment.sh
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "systemctl status kube-proxy|grep Active"
  done
  
echo ">>  SECP Cloud 配置完成！请用 kubectl get nodes 检查状态！"