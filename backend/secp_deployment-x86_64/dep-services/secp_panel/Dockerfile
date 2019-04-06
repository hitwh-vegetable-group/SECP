# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

# hitwhvg/welcome-infra:v1.0.0
ARG DOMAIN="main.arvirtual.love"

FROM hitwhvg/lnmp:v1.5.0
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

# Copy Files
COPY secp_panel.tgz /secp/secp_panel.tgz
COPY nginx_config.conf /usr/local/nginx/conf/vhost/main.arvirtual.love.conf
COPY .user.ini /secp/.user.ini

# unzip
RUN cd /secp && \
    tar -zxvf ./secp_panel.tgz -C /secp

# Build the vhost env
RUN chmod -R 755 /secp && \
    chown -R www:www /secp
RUN chmod 644 /secp/.user.ini

# Clean env
RUN rm -rf secp_panel.tgz

# USER root
EXPOSE 80 443 3306 8000
WORKDIR /secp
ENTRYPOINT /lnmp/lnmp_restart.sh & top -d 10