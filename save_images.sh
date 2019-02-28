# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: Skzwsm

#!/bin/sh

echo "hitwhvg-grafana"
docker save hitwhvg/grafana:v5.4.0  > hitwhvg-grafana.tar
echo "hitwhvg-addonresizer"
docker save hitwhvg/addon-resizer:v1.8.4  > hitwhvg-addon-resizer.tar
echo "hitwhvg-kube"
docker save hitwhvg/kube-state-metrics:v1.4.0  > hitwhvg-kube.tar
echo "hitwhvg-node-exporter"
docker save hitwhvg/node-exporter:v0.17.0  > hitwhvg-node-exporter.tar
echo "hitwhvg-prometheus"
docker save hitwhvg/prometheus:v2.5  > hitwhvg-prometheus.tar
