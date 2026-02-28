# MilkApp Deploy — Helm Chart & K8s Manifests

GitOps deployment configuration for [MilkApp](../milkapp/README.md). This repo is designed to be separate from the application code for clean GitOps workflows (e.g., ArgoCD, Flux).

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  k3d Cluster                                             │
│                                                          │
│  ┌─────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │ Traefik │───►│    Nginx     │    │   MilkApp    │     │
│  │ Ingress │    │  (static +   │───►│  (Go API)    │     │
│  │  :80    │    │   proxy)     │    │   :8080      │     │
│  └─────────┘    └──────────────┘    └──────┬───────┘     │
│       │                                     │            │
│       │ /api/* ─────────────────────────────┘            │
│       │                                                  │
│       │              ┌──────────────┐                    │
│       │              │  PostgreSQL  │                    │
│       │              │  (Bitnami)   │                    │
│       │              │   :5432      │                    │
│       │              └──────────────┘                    │
│       │                                                  │
└───────┼──────────────────────────────────────────────────┘
        │
  localhost:8080
```

**Traffic flow:**
- `http://localhost:8080/` → Traefik Ingress → Nginx (serves `index.html`, `app.js`, `style.css`)
- `http://localhost:8080/api/*` → Traefik Ingress → MilkApp Go backend → PostgreSQL

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (logged in to Docker Hub: `docker login`)
- [k3d](https://k3d.io/) v5+
- [Helm](https://helm.sh/docs/intro/install/) v3+
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

All scripts are in the **milkapp** repo under `scripts/`.

### 1. Create k3d cluster

```bash
# Linux/macOS
./scripts/k3d-setup.sh

# Windows (PowerShell)
.\scripts\k3d-setup.ps1
```

This creates:
- k3d cluster `milkapp` with Traefik ingress mapped to `localhost:8080`

### 2. Build, push, and deploy

```bash
# Linux/macOS
./scripts/deploy-local.sh

# Windows (PowerShell)
.\scripts\deploy-local.ps1
```

This will:
1. Build the Docker image and push to Docker Hub (`jrbalrog9/babymilk`)
2. Add the Bitnami Helm repo and update dependencies
3. Deploy MilkApp + PostgreSQL via Helm
4. Wait for all pods to be ready

### 3. Access the app

Open **http://localhost:8080** in your browser.

### 4. Verify deployment

```bash
kubectl get all -n milkapp
kubectl logs -n milkapp -l app.kubernetes.io/name=milkapp
helm status milkapp -n milkapp
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
charts/milkapp/
├── Chart.yaml              # Chart metadata + PostgreSQL dependency
├── values.yaml             # Default values
├── values-local.yaml       # k3d-specific overrides
├── .helmignore
└── templates/
    ├── _helpers.tpl         # Template helpers (names, labels, DB URL)
    ├── deployment.yaml      # MilkApp Go backend
    ├── service.yaml         # MilkApp ClusterIP service
    ├── ingress.yaml         # Traefik ingress (/api → app, / → nginx)
    ├── configmap.yaml       # nginx.conf
    ├── secret.yaml          # DATABASE_URL
    ├── nginx-deployment.yaml # Nginx (init container copies static files)
    └── nginx-service.yaml   # Nginx ClusterIP service
```

## Values Reference

| Key | Default | Description |
|-----|---------|-------------|
| `replicaCount` | `1` | Number of MilkApp replicas |
| `image.repository` | `jrbalrog9/babymilk` | Docker image repository |
| `image.tag` | `latest` | Docker image tag |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `service.type` | `ClusterIP` | MilkApp service type |
| `service.port` | `8080` | MilkApp service port |
| `nginx.enabled` | `true` | Deploy Nginx reverse proxy |
| `nginx.image.repository` | `nginx` | Nginx image |
| `nginx.image.tag` | `alpine` | Nginx image tag |
| `ingress.enabled` | `true` | Enable Ingress resource |
| `ingress.className` | `traefik` | Ingress class (k3d default) |
| `ingress.host` | `""` | Ingress hostname (empty = any) |
| `database.user` | `milkapp` | PostgreSQL username |
| `database.password` | `milkapp-secret` | PostgreSQL password |
| `database.name` | `milkapp` | PostgreSQL database name |
| `postgresql.enabled` | `true` | Deploy Bitnami PostgreSQL |
| `postgresql.primary.persistence.size` | `1Gi` | PVC size |

## GitOps Usage

This repo is structured for GitOps tools like ArgoCD or Flux:

```yaml
# ArgoCD Application example
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: milkapp
spec:
  source:
    repoURL: https://github.com/your-org/milkapp-deploy
    path: charts/milkapp
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: milkapp
```

## Manual Helm Commands

```bash
# Add Bitnami repo (first time only)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update chart dependencies
helm dependency update charts/milkapp

# Install / upgrade
helm upgrade --install milkapp charts/milkapp \
  -f charts/milkapp/values-local.yaml \
  -n milkapp --create-namespace --wait

# Check status
helm status milkapp -n milkapp

# Uninstall
helm uninstall milkapp -n milkapp
```
