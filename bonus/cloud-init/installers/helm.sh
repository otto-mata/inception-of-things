#!/usr/bin/env bash
set -euo pipefail

if command -v helm; then exit 0; fi

HELM_VERSION="v4.3.0"
HELM_TARBALL="helm-$HELM_VERSION-linux-amd64.tar.gz"
HELM_TARBALL_URL="https://get.helm.sh/$HELM_TARBALL"
HELM_TARBALL_SUM_URL="https://get.helm.sh/$HELM_TARBALL.sha256sum"

HELM_TEMP_DIR=`mktemp --directory`
pushd "$HELM_TEMP_DIR"
curl -sfLO "$HELM_TARBALL_URL"
curl -sfLO "$HELM_TARBALL_SUM_URL"
sha256sum -c "$HELM_TARBALL.sha256sum" 2>&1 >/dev/null|| (rm -f "$HELM_TARBALL" "$HELM_TARBALL.sha256sum"; exit 1)
tar xf "$HELM_TARBALL"
install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/helm
popd
rm -rf "$HELM_TEMP_DIR"
