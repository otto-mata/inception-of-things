#!/usr/bin/env bash
set -euo pipefail

if command -v k3d; then exit o; fi

K3D_VERSION="v5.9.0"
K3D_URL="https://raw.githubusercontent.com/k3d-io/k3d/refs/tags/$K3D_VERSION/install.sh"
curl -sfL "$K3D_URL" | bash
