#!/usr/bin/env bash
set -euo pipefail

environment="${1:-dev}"
if [[ "$environment" != "dev" && "$environment" != "prod" ]]; then
  echo "Usage: $0 [dev|prod]"
  exit 1
fi

echo "[1/3] Ensuring argocd namespace exists..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "[2/3] Installing/upgrading Argo CD (server-side apply)..."
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD server deployment..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

root_manifest="argocd/root-dev.yaml"
if [[ "$environment" == "prod" ]]; then
  root_manifest="argocd/root-prod.yaml"
fi

echo "[3/3] Applying root app: ${root_manifest}"
kubectl apply -f "${root_manifest}"

echo "Bootstrap completed for environment: ${environment}"
echo "Check status with: kubectl get applications -n argocd"
