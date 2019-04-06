# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

set -o errexit

echo "请确保使用管理员身份运行GIT BASH!"

# RSA && ECDSA Keys
echo "生成密钥中..."
ssh-keygen.exe -t rsa -f /etc/ssh/ssh_host_ecdsa_key
ssh-keygen.exe -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key

# Start SSHD
echo "正在启动SSHD..."
/usr/bin/sshd.exe
