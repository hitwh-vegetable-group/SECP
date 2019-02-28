# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: Skzwsm
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh

echo "> Saving Kube State Metrics..."
docker save hitwhvg/kube-state-metrics:v1.4.0  > hitwhvg-kube.tar

echo "> Saving Node Exporter..."
docker save hitwhvg/node-exporter:v0.17.0  > hitwhvg-node-exporter.tar

echo "> Saving Addon Resizer..."
docker save hitwhvg/addon-resizer:v1.8.4  > hitwhvg-addon-resizer.tar

echo "> Saving Prometheus..."
echo "  > This file is kind of big, please wait..."
docker save hitwhvg/prometheus:v2.5  > hitwhvg-prometheus.tar

echo "> Saving Grafana..."
echo "  > This file is kind of big, please wait..."
docker save hitwhvg/grafana:v5.4.0  > hitwhvg-grafana.tar
