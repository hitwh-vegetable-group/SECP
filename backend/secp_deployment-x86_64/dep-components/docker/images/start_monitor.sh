# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn
#!/bin/sh
  
#Promethus
echo "Running Prometheus v2.5 ..."
docker run -d --restart=always -p 9090:9090 --name=prometheus hitwhvg/prometheus:v2.5

#Node Exporter
echo "Running Node Exporter v0.17.0 ..."
docker run -d --restart=always -p 9100:9100 --name=node-exporter hitwhvg/node-exporter:v0.17.0

#Grafana
echo "Running Grafana v5.4.0 ..."
docker run -d --restart=always -p 3000:3000 --name=grafana hitwhvg/grafana:v5.4.0