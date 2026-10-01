#!/usr/bin/env bash
set -euo pipefail

if command -v kubectl; then exit 0; fi

KUBECTL_VERSION="v1.37.1"
KUBECTL_URL="https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
KUBECTL_SUM_URL="$KUBECTL_URL.sha256"

KUBECTL_TEMP_DIR=`mktemp --directory`
pushd "$KUBECTL_TEMP_DIR"
curl -sfLO "$KUBECTL_URL"
curl -sfLO "$KUBECTL_SUM_URL"
printf " kubectl" >> kubectl.sha256
sha256sum --check kubectl.sha256 2>&1 >/dev/null|| (rm -f "kubectl" "kubectl.sha256"; exit 1)
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
popd
rm -rf "$KUBECTL_TEMP_DIR"
