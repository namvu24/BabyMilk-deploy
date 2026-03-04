# Shared Vault + ESO manifests

This folder contains one shared set of Vault/External Secrets manifests for isolated dev/prod clusters.
Apply the same path from ArgoCD in each cluster; resources land in that app destination namespace.

Vault expectations per cluster:
- Kubernetes auth role: `babymilk-secrets`
- KV path: `secret/data/babymilk/postgresql`
- field: `dbpassword`
