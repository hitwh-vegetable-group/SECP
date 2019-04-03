# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

FROM ubuntu:16.04
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

COPY lnmp1.5-full.tar.gz /opt

RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/
RUN mkdir -p /prometheus && \
    chown -R nobody:nogroup etc/prometheus /prometheus

USER nobody
EXPOSE 9090
VOLUME     [ "/prometheus" ]
WORKDIR    /prometheus
ENTRYPOINT /bin/prometheus \
             --config.file=/etc/prometheus/prometheus.yml \
             --storage.tsdb.path=/prometheus \
             --web.console.libraries=/usr/share/prometheus/console_libraries \
             --web.console.templates=/usr/share/prometheus/consoles \
             & /bin/node_exporter