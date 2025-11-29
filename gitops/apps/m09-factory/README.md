# GitOps – M09 (Factory / Workflows)

Este diretório contém a estrutura GitOps para o módulo **M09** (Fábrica de Workflows).

## 🚧 Status: Fase 3 (Planejamento)

A implementação ativa deste módulo na **Fase 2 (Standard Topology)** está localizada em:
👉 `deployments/topology-a/standard/k8s/05-apps/`

### Implementação Atual (Fase 2)
- **Namespace:** `appgear`
- **Componentes:**
  - Flowise (AI Workflow Builder)
  - n8n (Automation)
- **Deploy:** Via `kubectl apply` (Manifestos diretos)

### Futuro (Fase 3 - GitOps)
Este diretório será utilizado para a migração para ArgoCD/Kustomize, gerenciando:
- Flowise HA
- n8n Workers (Escalabilidade)
- Templates de Workflow
- Ambientes de Desenvolvimento (CDE)
