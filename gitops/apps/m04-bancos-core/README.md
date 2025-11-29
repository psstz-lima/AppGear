# GitOps – M04 (Bancos Core)

Este diretório contém a estrutura GitOps para o módulo **M04** (Bancos de Dados Core).

## 🚧 Status: Fase 3 (Planejamento)

A implementação ativa deste módulo na **Fase 2 (Standard Topology)** está localizada em:
👉 `deployments/topology-a/standard/k8s/02-databases/`

### Implementação Atual (Fase 2)
- **Namespace:** `appgear`
- **Componentes:**
  - PostgreSQL (StatefulSet)
  - Redis (StatefulSet)
- **Deploy:** Via `kubectl apply` (Manifestos diretos)

### Futuro (Fase 3 - GitOps)
Este diretório será utilizado para a migração para ArgoCD/Kustomize, gerenciando:
- PostgreSQL HA (Patroni/CloudNativePG)
- Redis Cluster
- Qdrant (Vector DB)
- Backups via Velero
