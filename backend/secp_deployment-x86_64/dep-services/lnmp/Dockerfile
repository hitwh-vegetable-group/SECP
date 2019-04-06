# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn
# LOG --
# +------------------------------------------------------------------------+
# |          LNMP V1.5 for Ubuntu Linux Server, Written by Licess          |
# +------------------------------------------------------------------------+
# |           For more information please visit https://lnmp.org           |
# +------------------------------------------------------------------------+
# |    lnmp status manage: lnmp {start|stop|reload|restart|kill|status}    |
# +------------------------------------------------------------------------+
# |  phpMyAdmin: http://IP/phpmyadmin/                                     |
# |  phpinfo: http://IP/phpinfo.php                                        |
# |  Prober:  http://IP/p.php                                              |
# +------------------------------------------------------------------------+
# |  Add VirtualHost: lnmp vhost add                                       |
# +------------------------------------------------------------------------+
# |  Default directory: /home/wwwroot/default                              |
# +------------------------------------------------------------------------+
# |  MySQL/MariaDB root password:                                          |
# +------------------------------------------------------------------------+
# +-------------------------------------------+
# |    Manager for LNMP, Written by Licess    |
# +-------------------------------------------+
# |              https://lnmp.org             |
# +-------------------------------------------+
# nginx (pid 92693 92692 92691 92690 92689 92688 92687 92686 92684 92683 92682 92681 92680) is running...
# php-fpm is runing!
#  * MySQL running (93220)
# State      Recv-Q Send-Q Local Address:Port               Peer Address:Port              
# LISTEN     0      128          *:80                       *:*                  
# LISTEN     0      128         :::3306                    :::*                  
# Install lnmp takes 20 minutes.
# Install lnmp V1.5 completed! enjoy it.


FROM hitwhvg/ubuntu:16.04-update
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

# Copy LNMP tarball
COPY lnmp1.5-full.tgz /lnmp/lnmp1.5-full.tgz

# Change apt source
# RUN apt update && \
#     apt install -y apt-utils && \
#     apt upgrade -y && \
#     apt install -y apt-transport-https

# RUN rm -f /etc/apt/sources.list
# COPY sources.list /etc/apt
# RUN apt update

# Unzip tarball
RUN cd /lnmp && tar -zxvf ./lnmp1.5-full.tgz

# Deploy LNMP
RUN cd /lnmp/lnmp1.5-full && \
    chmod +x ./install.sh && \
    LNMP_Auto="y" \
    DBSelect="3" \
    DB_Root_Password="hitwh1604102" \
    InstallInnodb="y" \
    PHPSelect="8" \
    SelectMalloc="1" \
    ./install.sh lnmp

# Clean environment
RUN rm -rf /lnmp/*

# Entry
COPY lnmp_restart.sh /lnmp
RUN cd /lnmp && \
    chmod +x ./lnmp_restart.sh

# MySQL no password login
RUN sed -i 's/^#password *\= *your\_password/password    \= hitwh1604102/g' /etc/my.cnf

# USER root
EXPOSE 80 443 3306 8000
WORKDIR /lnmp
ENTRYPOINT /lnmp/lnmp_restart.sh & top