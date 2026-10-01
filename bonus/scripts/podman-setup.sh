#!/usr/bin/env bash
set -euo pipefail

if [ -f /var/run/docker.sock ]
then
    ln -sv /run/podman/podman.sock /var/run/docker.sock
fi

if ! systemctl is-enabled podman.socket
then
    systemctl enable --now podman.socket
    mkdir -pv /etc/containers/containers.conf.d
    echo 'service_timeout=0' > /etc/containers/containers.conf.d/timeout.conf
    printf '[containers]\nlog_driver = "k8s-file"' >> /etc/containers/containers.conf
fi
