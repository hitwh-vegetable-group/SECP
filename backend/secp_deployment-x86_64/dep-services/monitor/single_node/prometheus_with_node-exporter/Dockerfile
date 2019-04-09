# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

FROM busybox:glibc
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

COPY prometheus                             /bin/prometheus
COPY promtool                               /bin/promtool
COPY node_exporter                          /bin/node_exporter
COPY prometheus.yml                         /etc/prometheus/prometheus.yml
COPY console_libraries/                     /usr/share/prometheus/console_libraries/
COPY consoles/                              /usr/share/prometheus/consoles/

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