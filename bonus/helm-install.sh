#!/usr/bin/env bash

HELM_VERSION="v4.3.0"
HELM_TARBALL="helm-$HELM_VERSION-linux-amd64.tar.gz"
HELM_TARBALL_URL="https://get.helm.sh/$HELM_TARBALL"
HELM_TARBALL_SUM_URL="https://get.helm.sh/$HELM_TARBALL.sha256sum"

HELM_TEMP_DIR=`mktemp --directory`
pushd "$HELM_TEMP_DIR"
curl -sfLO "$HELM_TARBALL_URL"
curl -sfLO "$HELM_TARBALL_SUM_URL"
printf "File check:\n"
sha256sum -c "$HELM_TARBALL.sha256sum" || (rm -f "$HELM_TARBALL_SUM_URL" "$HELM_TARBALL_URL"; exit 1)
tar xf "$HELM_TARBALL"
install -v linux-amd64/helm /usr/local/bin/helm
popd
rm -rf "$HELM_TEMP_DIR"
printf "Installed Helm\n"
