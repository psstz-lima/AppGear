# GitOps – M10 (Brain / AI)

Este diretório contém a estrutura GitOps para o módulo **M10** (Inteligência Artificial).

## 🚧 Status: Fase 4 (Planejamento)

Este módulo contém a definição **GitOps** da suíte Brain (LiteLLM).

> **Nota:** Na **Fase 2 (Standard)**, o LiteLLM é deployado via manifestos diretos em `deployments/topology-a/standard/k8s/04-ai/`.

### Implementação Atual (Fase 2)
- **Namespace:** `appgear`
- **Componentes:**
  - LiteLLM (Deployment, 2 réplicas)
  - Integração Groq API
- **Deploy:** Via `kubectl apply` (Manifestos diretos)

### Futuro (Fase 4 - GitOps)
Este diretório será utilizado para a migração para ArgoCD/Kustomize, gerenciando:
- LiteLLM com Autoscaling avançado
- Vector Stores (Qdrant/Chroma)
- Agentes Autônomos
- RAG Pipelines
