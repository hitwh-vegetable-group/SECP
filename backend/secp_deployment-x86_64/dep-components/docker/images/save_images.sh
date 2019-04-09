# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: Skzwsm
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh

echo "> Loading Busybox..."
/opt/k8s/bin/docker save hitwhvg/busybox:glibc > hitwhvg-busybox-glibc.tar

echo "> Loading Ubuntu..."
/opt/k8s/bin/docker save hitwhvg/ubuntu:16.04 > hitwhvg-ubuntu-16.04.tar

echo "> Saving Kube State Metrics..."
/opt/k8s/bin/docker save hitwhvg/kube-state-metrics:v1.4.0  > hitwhvg-kube.tar

echo "> Saving Node Exporter..."
/opt/k8s/bin/docker save hitwhvg/node-exporter:v0.17.0  > hitwhvg-node-exporter.tar

echo "> Saving Addon Resizer..."
/opt/k8s/bin/docker save hitwhvg/addon-resizer:v1.8.4  > hitwhvg-addon-resizer.tar

echo "> Saving Prometheus..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker save hitwhvg/prometheus:v2.5  > hitwhvg-prometheus.tar

echo "> Saving Prometheus With Node-Exporter..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker save hitwhvg/prom-ne:arhshrn > hitwhvg-prom-ne.tar

echo "> Saving Grafana..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker save hitwhvg/grafana:v5.4.0  > hitwhvg-grafana.tar

echo "> Saving Pod Infra..."
echo "  > This file is kind of big, please wait..."
/opt/k8s/bin/docker save registry.access.redhat.com/rhel7/pod-infrastructure:latest > hitwhvg-pod-infra.tar