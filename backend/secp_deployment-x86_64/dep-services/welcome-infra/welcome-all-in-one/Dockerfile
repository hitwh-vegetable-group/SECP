# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

# hitwhvg/welcome:v1.0.0

FROM hitwhvg/welcome-infra:v1.0.0
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

# Copt tarball
COPY welcome.tgz /opt
RUN cd /opt && \
    tar -zxvf ./welcome.tgz && \
    mv ./Welcome ./welcome

# nginx vhost config
# Ngnix Location : /usr/local/nginx/conf/vhost TO-DO

# 

# USER root
EXPOSE 80 443 3306 8000
WORKDIR /opt/welcome
ENTRYPOINT /lnmp/lnmp_restart.sh & top -d 10