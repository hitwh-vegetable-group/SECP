# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

FROM hitwhvg/ubuntu:16.04
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

# Copy LNMP tarball
COPY lnmp1.5-full.tar.gz /lnmp/tarball/lnmp.tgz
COPY lnmp_restart.sh /lnmp

# Change apt source
RUN apt update 
RUN apt upgrade -y
RUN apt install -y apt-transport-https
RUN rm -f /etc/apt/sources.list
COPY sources.list /etc/apt
RUN apt update

# Unzip tarball
RUN cd /lnmp/tarball && tar -zxvf ./lnmp.tgz -C /lnmp

# Deploy LNMP
RUN cd /lnmp/lnmp1.5-full && pwd && ls -l --block-size=M
RUN cd /lnmp/lnmp1.5-full && chmod +x ./install.sh
RUN cd /lnmp/lnmp1.5-full && LNMP_Auto="y" DBSelect="2" DB_Root_Password="hitwh1604102" InstallInnodb="y" PHPSelect="5" SelectMalloc="1" ./install.sh lnmp

# Clean environment
RUN rm -rf /lnmp/tarball && rm -rf /lnmp/lnmp1.5-full

USER root
EXPOSE 80 443 3306
ENTRYPOINT /lnmp/lnmp_restart.sh