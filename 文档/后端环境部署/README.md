开源许可 GNU AGPL v3.0

文档作者: HITwh Vegetable Group :: ArHShRn

# 服务器后端环境部署

*为了去除sudo的复杂性，所有操作均在ROOT用户下执行*

- [x] APT 换清华大学源以及软件更新
- [x] Golang 环境配置
- [x] Docker 环境配置
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

3. 进入[清华大学开源软件镜像站](https://mirror.tuna.tsinghua.edu.cn/help/ubuntu/)

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
   cd ./golang
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
   tar -zxvf ./go1.12.linux-amd64.tar.gz -C /usr/local
   ```

3. 编辑当前用户环境变量

   ```bash
   vi ~/.profile
   ```

4. 为GOLANG添加GOROOT GOPATH 环境变量

   ```bash
   export GOROOT=/usr/local/go
   export GOPATH=/etc/gopath
   export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
   ```

   

5. 载入环境变量

   ```bash
   source ~/.profile
   ```

   

6. 查看Golang版本以检查Golang是否成功配置完成

   ```bash
   go version
   ```

   
## Docker 环境配置

### 删除之前的安装

仅删除可执行文件

```bash
apt remove -y docker docker-ce docker-engine docker.io containerd runc
```

删除包括所有配置文件

```
apt purge -y docker docker-ce docker-engine docker.io containerd runc
```



###获取并安装DOCKER-CE

1. 获取Containerd、Docker CE CLI以及Docker CE（注意，安装顺序也如此）

   ```bash
   cd /home
   mkdir ./docker
   cd ./docker
   wget https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/containerd.io_1.2.2-3_amd64.deb
   wget https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce-cli_18.09.2~3-0~ubuntu-xenial_amd64.deb
   wget https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_18.09.2~3-0~ubuntu-xenial_amd64.deb
   ```

   

2. 安装获取的三个包

   ```bash
   dpkg -i ./containerd.io_1.2.2-3_amd64.deb
   dpkg -i ./docker-ce-cli_18.09.2~3-0~ubuntu-xenial_amd64.deb
   dpkg -i ./docker-ce_18.09.2~3-0~ubuntu-xenial_amd64.deb
   ```

   

3. 启动Docker服务

   ```bash
   systemctl restart docker
   ```

4. 查看Docker版本以检查Docker是否成功配置完成

   ```
   docker version
   ```

   期望的输出

   ```
   Client:
    Version:           18.09.2
    API version:       1.39
    Go version:        go1.10.6
    Git commit:        6247962
    Built:             Sun Feb 10 04:13:50 2019
    OS/Arch:           linux/amd64
    Experimental:      false
   
   Server: Docker Engine - Community
    Engine:
     Version:          18.09.2
     API version:      1.39 (minimum version 1.12)
     Go version:       go1.10.6
     Git commit:       6247962
     Built:            Sun Feb 10 03:42:13 2019
     OS/Arch:          linux/amd64
     Experimental:     false
   ```

### 解决PULL镜像速度过慢的问题

####Docker 中国官方镜像

在使用时，Docker 中国官方镜像加速可通过 registry.docker-cn.com 访问。

该镜像库只包含流行的公有镜像。私有镜像仍需要从美国镜像库中拉取。

例如：

```
docker pull registry.docker-cn.com/library/ubuntu:16.04
```

#### 配置 Docker 守护进程

配置 Docker 守护进程默认使用 Docker 官方镜像加速，这样可以默认通过官方镜像加速拉取镜像，而无需在每次拉取时指定 registry.docker-cn.com

具体方法为：修改 `/etc/docker/daemon.json` 文件并添加上 registry-mirrors 键值

```json
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
```

保存后重启 Docker 以生效

```bash
systemctl restart docker
```