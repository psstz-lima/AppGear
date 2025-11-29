# GitOps – M03 (Observabilidade)

Este diretório contém a estrutura GitOps para o módulo **M03** (Observabilidade).

## 🚧 Status: Fase 4 (Planejamento)

Este módulo contém a definição **GitOps** da stack de observabilidade.

> **Nota:** Na **Fase 2 (Standard)**, o Prometheus e Grafana são deployados via manifestos diretos em `deployments/topology-a/standard/k8s/06-observability/`.

### Implementação Atual (Fase 2)
- **Namespace:** `observability`
- **Componentes:**
  - Prometheus (Porta 9099)
  - Grafana (Porta 3001)
- **Deploy:** Via `kubectl apply` (Manifestos diretos)

### Futuro (Fase 4 - GitOps)
Este diretório será utilizado para a migração para ArgoCD/Kustomize, gerenciando:
- Prometheus Operator
- Loki (Logs)
- Tempo (Tracing)
- Dashboards as Code
