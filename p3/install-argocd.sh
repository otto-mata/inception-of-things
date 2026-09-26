#!/usr/bin/env bash

if ! `command -v argocd`
then
	printf "Installing argocd\n"
	curl -sSL \
		-o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v3.5.3/argocd-linux-amd64
	sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
	rm /tmp/argocd-linux-amd64
fi
printf "argocd installed\n"
