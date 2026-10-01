#!/usr/bin/env bash

set -xo pipefail

if [ ! $ARGOCD_ADMIN_PASSWORD ]
then
  printf 'ARGOCD_ADMIN_PASSWORD environment is not set, exiting.\n'
  exit 1
fi

k3d cluster create \
	--api-port 127.0.0.1:6550 \
	-p "8080:80@loadbalancer" \
	-p "8443:443@loadbalancer"

kubectl create namespace argocd
kubectl create namespace dev

kubectl apply \
	-n argocd \
	--server-side \
	--force-conflicts \
	-f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.3/manifests/install.yaml

kubectl create ingress argocd-ingress \
  --rule='argocd.local/*=argocd-server:80' \
  -n argocd

kubectl patch configmap argocd-cmd-params-cm \
	-n argocd \
	--type=merge \
	-p '{"data": { "server.insecure": "true" }}'

kubectl create ingress playground-ingress \
    --rule='playground.local/*=playground:80' \
    -n dev


printf 'waiting for Ingress to get an IP...'
until kubectl wait \
	--for=jsonpath='{.status.loadBalancer.ingress[0].ip}' \
	-n kube-system \
	--timeout=1s \
	services/traefik 2>/dev/null
do
	printf '.'
done

server_ip=`kubectl get services/traefik \
	-n kube-system \
	-o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`

printf "\nservices/traefik address: %s\n" "$server_ip"

echo "$server_ip  argocd.local playground.local" | tee -a /etc/hosts

printf 'waiting for administrative password generation...'
until argocd admin initial-password -n argocd 2>/dev/null >/dev/null
do
	sleep 1
	printf '.'
done

NEW_ARGOCD_ADMIN_PASSWORD=`mkpasswd -m bcrypt_a -R 10 "$ARGOCD_ADMIN_PASSWORD"`
printf 'replacing ArgoCD password with `%s`\n' "$NEW_ARGOCD_ADMIN_PASSWORD"
kubectl \
  patch secret \
  -n argocd argocd-secret \
  -p '{"stringData": { "admin.password": "'$NEW_ARGOCD_ADMIN_PASSWORD'", "admin.passwordMtime": "'`date +%Y-%m-%dT%H:%M:%SZ`'"}}'

kubectl config set-context \
	--current \
	--namespace=argocd

printf 'waiting for argocd server to be joinable...'
until nc -z argocd.local 443
do
	sleep 1
	printf '.'
done

argocd \
  login argocd.local \
  --grpc-web \
  --insecure \
  --username admin \
  --password "$ARGOCD_ADMIN_PASSWORD"

argocd app create iot-bonus \
	--repo https://github.com/otto-mata/inception-of-things.git \
	--path bonus/manifests/playground \
	--dest-server https://kubernetes.default.svc \
	--dest-namespace dev \
	--revision bonus

argocd app sync iot-bonus
