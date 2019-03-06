# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: Skzwsm
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh

echo "> Loading Kube State Metrics..."
/opt/k8s/bin/docker load -i hitwhvg-kube.tar

echo "> Loading Node Exporter..."
/opt/k8s/bin/docker load -i hitwhvg-node-exporter.tar

echo "> Loading Addon Resizer..."
/opt/k8s/bin/docker load -i hitwhvg-addon-resizer.tar

echo "> Loading Prometheus..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load -i hitwhvg-prometheus.tar

echo "> Loading Prometheus With Node-Exporter..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load -i hitwhvg-hitwhvg-prom-ne.tar

echo "> Loading Grafana..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load -i hitwhvg-grafana.tar

echo "> Loading Pod Infra..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load -i hitwhvg-pod-infra.tar
