#!/usr/bin/env bash

k3d cluster create --api-port 127.0.0.1:6550 -p "8080:80@loadbalancer" -p "8443:443@loadbalancer" --k3s-arg "--disable=traefik@server:0"
kubectl create namespace argocd
kubectl create namespace dev
kubectl apply -n argocd     --server-side     --force-conflicts     -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.3/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

printf 'waiting for service/argocd-server to get an IP...'
until kubectl get service/argocd-server -n argocd --output=jsonpath='{.status.loadBalancer}' | grep 'ingress' >/dev/null
do
	sleep 1
	printf '.'
done

server_ip=`kubectl get svc argocd-server -n argocd -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
printf "\nargocd-server address: %s\n" "$server_ip"

printf 'waiting for administrative password generation...'
until argocd admin initial-password -n argocd 2>/dev/null >/dev/null
do
	sleep 1
	printf '.'
done

printf '\nlogin with admin:'
argocd admin initial-password -n argocd
printf '\n'

printf 'waiting for argocd server to be joinable...'
until nc -z "$server_ip" 443
do
	sleep 1
	printf '.'
done
printf '\nLogin to argocd:\n'
argocd login "$server_ip"

printf 'Update admin password:\n'
argocd account update-password

kubectl config set-context --current --namespace=argocd
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace dev
argocd app sync guestbook
