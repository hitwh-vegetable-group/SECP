# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

RSAKEY="/etc/ssh/ssh_host_rsa_key.pub"
ECDSAKEY="/etc/ssh/ssh_host_ecdsa_key.pub"

set -o errexit

echo "请确保使用管理员身份运行GIT BASH!"

# RSA && ECDSA Keys
if [ ! -f $RSAKEY ]; then
echo "生成RSA密钥中..."
ssh-keygen.exe -t rsa -f /etc/ssh/ssh_host_rsa_key
fi
if [ ! -f $ECDSAKEY ]; then
echo "生成ECDSA密钥中..."
ssh-keygen.exe -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
fi

# Start SSHD
echo "正在启动SSHD..."
/usr/bin/sshd.exe
