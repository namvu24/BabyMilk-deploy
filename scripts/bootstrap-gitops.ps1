param(
  [ValidateSet("dev", "prod")]
  [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

Write-Host "[1/3] Ensuring argocd namespace exists..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

Write-Host "[2/3] Installing/upgrading Argo CD (server-side apply)..."
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "Waiting for Argo CD server deployment..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

$rootManifest = if ($Environment -eq "prod") { "argocd/root-prod.yaml" } else { "argocd/root-dev.yaml" }

Write-Host "[3/3] Applying root app: $rootManifest"
kubectl apply -f $rootManifest

Write-Host "Bootstrap completed for environment: $Environment"
Write-Host "Check status with: kubectl get applications -n argocd"
