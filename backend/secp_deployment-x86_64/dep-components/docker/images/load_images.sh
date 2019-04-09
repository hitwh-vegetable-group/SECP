# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: Skzwsm
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh

echo "> Loading Busybox..."
/opt/k8s/bin/docker load < hitwhvg-busybox-glibc.tar

echo "> Loading Ubuntu..."
/opt/k8s/bin/docker load < hitwhvg-ubuntu-16.04.tar

echo "> Loading Kube State Metrics..."
/opt/k8s/bin/docker load < hitwhvg-kube.tar

echo "> Loading Node Exporter..."
/opt/k8s/bin/docker load < hitwhvg-node-exporter.tar

echo "> Loading Addon Resizer..."
/opt/k8s/bin/docker load < hitwhvg-addon-resizer.tar

echo "> Loading Prometheus..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load < hitwhvg-prometheus.tar

echo "> Loading Prometheus With Node-Exporter..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load < hitwhvg-prom-ne.tar

echo "> Loading Grafana..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load < hitwhvg-grafana.tar

echo "> Loading Pod Infra..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker load < hitwhvg-pod-infra.tar
