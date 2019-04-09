# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

# hitwhvg/welcome-infra:v1.0.0

FROM hitwhvg/lnmp:v1.5.0
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

# No pwd login
ENV MYSQL_ALLOW_EMPTY_PASSWORD yes

# Copt tarball
COPY welcome.tgz /opt
RUN cd /opt && \
    tar -zxvf ./welcome.tgz && \
    mv ./Welcome ./welcome

# Update composer
RUN cd /opt/welcome && \
    composer update -vvv

# Build the env

# 

# USER root
EXPOSE 80 443 3306 8000
WORKDIR /opt/welcome
ENTRYPOINT /lnmp/lnmp_restart.sh & top -d 10