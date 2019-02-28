# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: Skzwsm

#!/bin/sh

echo "hitwhvg-grafana"
docker load -i hitwhvg-grafana.tar
echo "hitwhvg-addon-resizer"
docker load -i hitwhvg-addon-resizer.tar
echo "hitwhvg-kube"
docker load -i hitwhvg-kube.tar
echo "hitwhvg-node-exporter"
docker load -i hitwhvg-node-exporter.tar
echo "hitwhvg-prometheus"
docker load -i hitwhvg-prometheus.tar
