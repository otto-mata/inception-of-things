#!/usr/bin/env bash

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

printf '\nlogin with admin:'
argocd admin initial-password \
	-n argocd
printf '\n'

printf 'waiting for argocd server to be joinable...'
until nc -z argocd.local 443
do
	sleep 1
	printf '.'
done
printf '\nLogin to argocd:\n'
argocd login argocd.local --grpc-web

printf 'Update admin password:\n'
argocd account update-password

kubectl config set-context \
	--current \
	--namespace=argocd

argocd app create iot-part3 \
	--repo https://github.com/otto-mata/inception-of-things.git \
	--path p3/manifests/ \
	--dest-server https://kubernetes.default.svc \
	--dest-namespace dev

argocd app sync iot-part3
