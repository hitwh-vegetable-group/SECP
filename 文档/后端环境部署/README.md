开源许可 GNU AGPL v3.0

# BECS 服务器后端环境部署

*为了去除sudo的复杂性，所有操作均在ROOT用户下执行*

- [x] APT 换清华大学源以及软件更新
- [x] Golang 环境配置
- [ ] Docker 环境配置
- [ ] etcd 环境配置
- [ ] Kubernetes 环境配置

## APT 换清华大学源以及软件更新

1. 进入apt源列表文件夹

   ```bash
   cd /etc/apt
   ```

2. 备份原source.list

   ```bash
   mv ./source.list ./source.list.origin
   ```

3. 进入

   [清华大学开源软件镜像站]: https://mirror.tuna.tsinghua.edu.cn/help/ubuntu/	"清华大学开源软件镜像站"

   选择 16.04 LTS 拷贝所有文本（或者直接利用以下提供的）

   ```
   # 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
   
   # 预发布软件源，不建议启用
   # deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-proposed main restricted universe multiverse
   # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-proposed main restricted universe multiverse
   ```

4. 新建source.list文件并将拷贝好的文本粘贴进去，最后保存文件

   ```
   vi ./source.list
   ```

5. 更新APT列表缓存并升级所有包

   ```bash
   apt update && apt upgrade -y
   ```

## Golang 环境配置

1. 下载GOLANG 1.12 并 核对GOLANG 1.12安装包SHA256

   下载

   ```bash
   cd /home
   mkdir ./golang
   wget https://studygolang.com/dl/golang/go1.12.linux-amd64.tar.gz
   ```

   核对SHA256

   ```bash
   sha256sum ./go1.12.linux-amd64.tar.gz
   ```

   应该显示

   ```
   750a07fef8579ae4839458701f4df690e0b20b8bcce33b437e4df89c451b6f13
   ```

   若未知原因导致SHA256不匹配，请执行以下命令并重新核对SHA256

   ```bash
   rm -f ./go1.12.linux-amd64.tar.gz
   wget https://studygolang.com/dl/golang/go1.12.linux-amd64.tar.gz
   ```

2. 解压缩tarball到 /usr/local 目录下

   ```bash
   tar -zxzf ./go1.12.linux-amd64.tar.gz -C /usr/local
   ```

3. 编辑当前用户环境变量

   ```
   vi ~/.profile
   ```

4. 为GOLANG添加GOROOT GOPATH 环境变量

   ```
   export GOROOT=/usr/local/go
   export GOPATH=/etc/gopath
   export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
   ```

   

5. 载入环境变量

   ```
   source ~/.profile
   ```

   

6. 查看Golang版本以检查Golang是否成功配置完成

   ```
   go version
   ```

   