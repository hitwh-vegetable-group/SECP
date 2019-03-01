# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: Skzwsm
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh

echo "> Loading Kube State Metrics..."
docker load -i hitwhvg-kube.tar

echo "> Loading Node Exporter..."
docker load -i hitwhvg-node-exporter.tar

echo "> Loading Addon Resizer..."
docker load -i hitwhvg-addon-resizer.tar

echo "> Loading Prometheus..."
echo "  > This file is kind of big, please wait..."
docker load -i hitwhvg-prometheus.tar

echo "> Loading Grafana..."
echo "  > This file is kind of big, please wait..."
docker load -i hitwhvg-grafana.tar
