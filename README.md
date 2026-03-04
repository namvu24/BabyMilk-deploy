# BabyMilk Deploy — Helm Chart & K8s Manifests

GitOps deployment configuration for [BabyMilk](../babymilk/README.md). This repo is designed to be separate from the application code for clean GitOps workflows (e.g., ArgoCD, Flux).

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  k3d Cluster                                             │
│                                                          │
│  ┌─────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │ Traefik │───►│    Nginx     │    │   BabyMilk   │     │
│  │ Ingress │    │  (static +   │───►│  (Go API)    │     │
│  │  :80    │    │   proxy)     │    │   :8080      │     │
│  └─────────┘    └──────────────┘    └──────┬───────┘     │
│       │                                     │            │
│       │ /api/* ─────────────────────────────┘            │
│       │                                                  │
│       │              ┌──────────────┐                    │
│       │              │  PostgreSQL  │                    │
│       │              │    :5432     │
│       │              │              │                    │
│       │              └──────────────┘                    │
│       │                                                  │
└───────┼──────────────────────────────────────────────────┘
        │
  localhost:8080
```

**Traffic flow:**
- `http://localhost:8080/` → Traefik Ingress → Nginx (serves `index.html`, `app.js`, `style.css`)
- `http://localhost:8080/api/*` → Traefik Ingress → BabyMilk Go backend → PostgreSQL

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (logged in to Docker Hub: `docker login`)
- [k3d](https://k3d.io/) v5+
- [Helm](https://helm.sh/docs/intro/install/) v3+
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## First-time Bootstrap Checklist

Use this order for a clean setup:

1. Create/connect to target cluster and verify `kubectl` context.
2. Install ArgoCD in `argocd` namespace.
3. Install Vault and initialize + unseal it.
4. Enable Vault KV v2 at `secret/`.
5. Install External Secrets Operator (ESO) (chart `0.19.2` for k8s `1.27.x`).
6. Write `dbpassword` to Vault at `secret/babymilk/postgresql`.
7. Apply ArgoCD apps in order:
  - `argocd/external-secrets.yaml`
  - `argocd/secrets-vault.yaml`
  - `argocd/dev.yaml`
8. For production, apply `argocd/prod.yaml`.

## Quick Start

All scripts are in the **babymilk** repo under `scripts/`.

### 1. Create k3d cluster

```bash
# Linux/macOS
./scripts/k3d-setup.sh

# Windows (PowerShell)
.\scripts\k3d-setup.ps1
```

This creates:
- k3d cluster `babymilk` with Traefik ingress mapped to `localhost:8080`

### 2. Build, push, and deploy

```bash
# Linux/macOS
./scripts/deploy-local.sh

# Windows (PowerShell)
.\scripts\deploy-local.ps1
```

This will:
1. Build the Docker image and push to Docker Hub (`namvu24/babymilk`)
2. Add the Bitnami Helm repo and update dependencies
3. Deploy BabyMilk + PostgreSQL via Helm
4. Wait for all pods to be ready

### 3. Access the app

Open **http://localhost:8080** in your browser.

### 4. Verify deployment

```bash
kubectl get all -n babymilk
kubectl logs -n babymilk -l app.kubernetes.io/name=babymilk
helm status babymilk -n babymilk
```

### 5. Teardown

```bash
# Linux/macOS
./scripts/k3d-teardown.sh

# Windows (PowerShell)
.\scripts\k3d-teardown.ps1
```

## Chart Structure

```
charts/babymilk/
├── Chart.yaml              # Chart metadata + PostgreSQL dependency
├── values.yaml             # Default values
├── values-local.yaml       # k3d-specific overrides
├── .helmignore
└── templates/
    ├── _helpers.tpl         # Template helpers (names, labels, DB URL)
    ├── deployment.yaml      # BabyMilk Go backend
    ├── service.yaml         # BabyMilk ClusterIP service
    ├── ingress.yaml         # Traefik ingress (/api → app, / → nginx)
    ├── configmap.yaml       # nginx.conf
    ├── secret.yaml          # DATABASE_URL
    ├── nginx-deployment.yaml # Nginx (init container copies static files)
    └── nginx-service.yaml   # Nginx ClusterIP service
```

## Values Reference

| Key | Default | Description |
|-----|---------|-------------|
| `replicaCount` | `1` | Number of BabyMilk replicas |
| `image.repository` | `namvu24/babymilk` | Docker image repository |
| `image.tag` | `latest` | Docker image tag |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `service.type` | `ClusterIP` | BabyMilk service type |
| `service.port` | `8080` | BabyMilk service port |
| `nginx.enabled` | `true` | Deploy Nginx reverse proxy |
| `nginx.image.repository` | `nginx` | Nginx image |
| `nginx.image.tag` | `alpine` | Nginx image tag |
| `ingress.enabled` | `true` | Enable Ingress resource |
| `ingress.className` | `traefik` | Ingress class (k3d default) |
| `ingress.host` | `""` | Ingress hostname (empty = any) |
| `database.user` | `babymilk` | PostgreSQL username |
| `database.password` | `babymilk-secret` | PostgreSQL password |
| `database.name` | `babymilk` | PostgreSQL database name |
| `postgresql.enabled` | `true` | Deploy Bitnami PostgreSQL |
| `postgresql.primary.persistence.size` | `1Gi` | PVC size |

## GitOps Usage

This repo is structured for GitOps tools like ArgoCD or Flux:

```yaml
# ArgoCD Application example
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: babymilk
spec:
  source:
    repoURL: https://github.com/your-org/babymilk-deploy
    path: charts/babymilk
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: babymilk
```

## Manual Helm Commands

```bash
# Add Bitnami repo (first time only)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update chart dependencies
helm dependency update charts/babymilk

# Install / upgrade
helm upgrade --install babymilk charts/babymilk \
  -f charts/babymilk/values-local.yaml \
  -n babymilk --create-namespace --wait

# Check status
helm status babymilk -n babymilk

# Uninstall
helm uninstall babymilk -n babymilk
```

### Install Vault (in cluster)

```bash
# Add HashiCorp repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault (dev/single pod style)
helm upgrade --install vault hashicorp/vault \
  -n vault --create-namespace \
  --set "server.dev.enabled=false" \
  --set "injector.enabled=true" \
  --wait

# Initialize Vault and save output locally
kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > vault-init.json
```

PowerShell (extract unseal key + root token):

```powershell
$init = Get-Content .\vault-init.json | ConvertFrom-Json
$unsealKey = $init.unseal_keys_b64[0]
$rootToken = $init.root_token
```

Unseal Vault:

```bash
kubectl exec -n vault vault-0 -- vault operator unseal $unsealKey
```

Enable KV v2 at `secret/` (required before writing app secrets):

```bash
# Check existing mounts
kubectl exec -n vault vault-0 -- sh -c "VAULT_TOKEN=$rootToken vault secrets list"

# Enable only if `secret/` does not exist
kubectl exec -n vault vault-0 -- sh -c "VAULT_TOKEN=$rootToken vault secrets enable -path=secret kv-v2"
```

### Install External Secrets Operator (ESO)

> For k3s/k8s `v1.27.x`, pin ESO chart to `0.19.2`.

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace \
  --version 0.19.2 \
  --set installCRDs=true \
  --wait
```

Verify ESO:

```bash
kubectl get pods -n external-secrets
kubectl get crd | findstr external-secrets.io
```

### Add DB password to Vault (shared ExternalSecret)

Current manifests under `platform/vault-eso/` read:
- secret path: `secret/data/babymilk/postgresql`
- property: `dbpassword`

Write password to Vault:

```bash
kubectl exec -n vault vault-0 -- sh -c "VAULT_TOKEN=$rootToken vault kv put secret/babymilk/postgresql dbpassword='YOUR_STRONG_DB_PASSWORD'"
```

Verify value exists:

```bash
kubectl exec -n vault vault-0 -- sh -c "VAULT_TOKEN=$rootToken vault kv get secret/babymilk/postgresql"
```

## Deploy to Dev/Prod with ArgoCD (Non-local)

Use these manifests in `argocd/`:
- `argocd/external-secrets.yaml` (installs ESO)
- `argocd/secrets-vault.yaml` (installs shared SecretStore + ExternalSecrets in namespace `app`)
- `argocd/dev.yaml` (deploys BabyMilk to namespace `app`)
- `argocd/prod.yaml` (deploys BabyMilk to namespace `app`)

### 1) Install/verify ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
```

### 2) Deploy Dev (with Vault + ESO)

Apply in this order:

```bash
# ESO controller + CRDs
kubectl apply -f argocd/external-secrets.yaml

# Shared SecretStore + ExternalSecret resources
kubectl apply -f argocd/secrets-vault.yaml

# Dev app chart
kubectl apply -f argocd/dev.yaml
```

Verify:

```bash
kubectl get applications -n argocd
kubectl get externalsecret,secret -n app
kubectl get pods -n app
```

### 3) Deploy Prod

```bash
kubectl apply -f argocd/prod.yaml
kubectl get applications -n argocd
kubectl get pods -n app
```

Notes:
- Each cluster requires Vault to be initialized/unsealed and `dbpassword` present at `secret/babymilk/postgresql`.
- If an app stays OutOfSync/Degraded, inspect events/logs in ArgoCD and the target namespace resources.

## CDN Frontend Path (TODO)

Current routing model supports same-host CDN split by path:
- `/api/*` stays dynamic (origin backend service)
- `/` and `/static/*` are frontend paths and now include configurable cache headers from nginx

New values:
- `nginx.cacheControl.html` (default: `no-cache, no-store, must-revalidate`)
- `nginx.cacheControl.static` (default: `public, max-age=300`)

Environment overrides:
- `values-local.yaml`: static cache set to `max-age=60` for faster local iteration
- `values-dev.yaml`: static cache set to `max-age=300`

Example deploy:

```bash
helm upgrade --install babymilk charts/babymilk \
  -f charts/babymilk/values-local.yaml \
  -f charts/babymilk/values-local-secrets.yaml \
  -n local --wait
```
