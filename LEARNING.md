# Learning Journey: Kubernetes + Helm + ArgoCD

## 1) Goal
Build confidence to deploy, operate, and secure this app end-to-end using Kubernetes, Helm, and ArgoCD.

---

## 2) Current Learning Map

### Kubernetes
- [x] Pod
- [x] Deployment
- [x] ConfigMap
- [x] Service
- [x] Nginx basics
- [ ] Service Account
- [ ] RBAC
- [ ] Ingress deep dive

### Helm
- [x] Chart basics
- [x] Values strategy by environment (`values-dev`, `values-prod`, `values-local`)
- [ ] Template helpers and naming conventions
- [ ] Upgrade/rollback patterns

### ArgoCD
- [x] UI basics
- [ ] App sync lifecycle (OutOfSync, Synced, Healthy)
- [ ] Multi-app structure (app + secrets + platform)
- [ ] Drift detection and self-heal behavior

### CLI / Tooling
- [x] `kubectl apply`
- [x] `kubectl logs`
- [x] `kubectl get`
- [x] `kubectl config`
- [x] `kubectl describe`
- [x] `k3d`
- [ ] `kubectl rollout` workflows
- [ ] `kubectl exec` debugging workflows

---

## 3) Learning Phases

### Phase 1 — Core Runtime (Done/Stable)
- Understand resources: Deployment, Service, ConfigMap, Secret
- Verify app path: Ingress → Nginx → Backend → PostgreSQL

### Phase 2 — Environment Management (In Progress)
- Separate dev/prod values and secret flows
- Validate naming and release behavior (`babymilk` vs `babymilk-dev`)
- Standardize ArgoCD app sources per environment

### Phase 3 — Security + Platform Hardening (Next)
- ServiceAccount + RBAC
- TLS certificates
- Secret management with Vault + External Secrets
- Basic security scanning

### Phase 4 — Operability + Scale
- Monitoring and alerting
- CDN strategy
- Performance and reliability checks

---

## 4) Priority Backlog (Actionable)

1. [ ] Kubernetes ServiceAccount + RBAC for app components
2. [ ] Ingress/Nginx routing hardening and docs
3. [ ] TLS certificate setup (dev/prod strategy)
4. [ ] CDN path and cache strategy
5. [ ] Code/container scanning in CI
6. [ ] Monitoring dashboard + alert basics

---

## 5) Weekly Learning Log

## Week __
### What I learned
- 

### What I built/changed
- 

### Issues I hit
- 

### How I solved them
- 

### Next week focus
- 

---

## 6) Quick Reflection Prompts
- What broke this week, and why?
- What did I debug fastest, and what helped?
- Which area still feels unclear?
- What one topic would give the biggest confidence boost next?

---

## 7) Definition of Progress
- I can explain each deployed component and why it exists.
- I can trace a user request from ingress to backend.
- I can diagnose common failures (CrashLoopBackOff, 404, 504, auth issues).
- I can safely deploy changes through ArgoCD across environments.