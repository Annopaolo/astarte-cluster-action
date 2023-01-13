#!/bin/bash

# Wait for coredns to be ready before everything
kubectl wait --namespace kube-system \
  --for=jsonpath='{.status.readyReplicas}'=2 deploy/coredns \
  --timeout=90s || exit 1

# Manage Helm repositories
helm repo add jetstack https://charts.jetstack.io
helm repo add astarte https://helm.astarte-platform.org
helm repo update

# Install cert-manager
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.10.0 --set installCRDs=true || exit 1

# Install ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Wait for everything to settle
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s || exit 1

# Install Astarte operator
helm install astarte-operator astarte/astarte-operator --version "$1" --set image.tag="$2" || exit 1

# Wait 10s for it to settle
sleep 10
