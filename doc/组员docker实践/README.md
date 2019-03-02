文档作者: HITwh Vegetable Group :: ArHShRn

# 基于ubuntu:16.04搭建一个含有宝塔面板的服务器镜像

## 熟悉docker的使用

  怎么拉取镜像 docker pull
  怎么查看系统存在的镜像 docker images
  怎么启动一个docker容器 docker run（以及-it 参数的使用）
  怎么启动停止以及重启一个docker容器 docker run / stop / restart 
  怎么进入一个正在运行的docker容器并进行互动 docker exec -it
  如果出现错误，怎么查看日志 docker logs
  怎么查看目前所有的容器 docker ps -a
  怎么删除一个容器 docker rm （以及-f的使用情况）
  怎么删除一个镜像 docker rmi 

## 熟悉Dockerfile的语法格式

如何通过此文件创建一个镜像 docker build -t repo/name:tag .

（详细了解repo/name:tag部分）