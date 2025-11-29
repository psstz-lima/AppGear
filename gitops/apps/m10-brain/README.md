# GitOps – M10 (Brain / AI)

Este diretório contém a estrutura GitOps para o módulo **M10** (Inteligência Artificial).

## 🚧 Status: Fase 3 (Planejamento)

A implementação ativa deste módulo na **Fase 2 (Standard Topology)** está localizada em:
👉 `deployments/topology-a/standard/k8s/04-ai/`

### Implementação Atual (Fase 2)
- **Namespace:** `appgear`
- **Componentes:**
  - LiteLLM (Deployment, 2 réplicas)
  - Integração Groq API
- **Deploy:** Via `kubectl apply` (Manifestos diretos)

### Futuro (Fase 3 - GitOps)
Este diretório será utilizado para a migração para ArgoCD/Kustomize, gerenciando:
- LiteLLM com Autoscaling avançado
- Vector Stores (Qdrant/Chroma)
- Agentes Autônomos
- RAG Pipelines
