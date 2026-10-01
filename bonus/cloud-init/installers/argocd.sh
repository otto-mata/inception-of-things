#!/usr/bin/env bash
set -euo pipefail

if command -v argocd; then exit 0; fi

ARGOCD_URL="https://github.com/argoproj/argo-cd/releases/download/v3.5.3/argocd-linux-amd64"
ARGOCD_EXE=`basename $ARGOCD_URL`

curl -sSfLO "$ARGOCD_URL"
install -o root -g root -m 0755  "$ARGOCD_EXE" /usr/local/bin/argocd
rm "$ARGOCD_EXE"
