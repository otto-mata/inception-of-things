#!/usr/bin/env bash
set -euo pipefail

if ! systemctl is-enabled podman.socket
then
    systemctl enable --now podman.socket
    mkdir -pv /etc/containers/containers.conf.d
    echo 'service_timeout=0' > /etc/containers/containers.conf.d/timeout.conf
    printf '[containers]\nlog_driver = "k8s-file"' >> /etc/containers/containers.conf
    systemctl enable --now podman-docker.service
fi
