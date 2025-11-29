# GitOps – M04 (Bancos Core)

Este diretório contém a estrutura GitOps para o módulo **M04** (Bancos de Dados Core).

## 🚧 Status: Fase 4 (Planejamento)

Este módulo contém a definição **GitOps** dos bancos de dados core.

> **Nota:** Na **Fase 2 (Standard)**, o PostgreSQL e Redis são deployados via manifestos diretos em `deployments/topology-a/standard/k8s/04-bancos-core/`.

### Implementação Atual (Fase 2)
- **Namespace:** `appgear`
- **Componentes:**
  - PostgreSQL (StatefulSet)
  - Redis (StatefulSet)
- **Deploy:** Via `kubectl apply` (Manifestos diretos)

### Futuro (Fase 4 - GitOps)
Este diretório será utilizado para a migração para ArgoCD/Kustomize, gerenciando:
- PostgreSQL HA (Patroni/CloudNativePG)
- Redis Cluster
- Qdrant (Vector DB)
- Backups via Velero
