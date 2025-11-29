# Topologia A Standard - Kubernetes

Implementação da stack AppGear em Kubernetes usando K3s, focada em observabilidade e escalabilidade.

## 🎯 Estrutura de Diretórios

```
standard/
├── k8s/
│   ├── 00-namespaces/       # Namespaces e Secrets
│   ├── 02-databases/        # PostgreSQL, Redis
│   ├── 04-ai/               # LiteLLM (2 réplicas)
│   ├── 05-apps/             # Flowise, n8n
│   └── 06-observability/    # Prometheus, Grafana
│
└── scripts/
    ├── setup-k3s-a-standard.sh       # Instala K3s
    ├── deploy-stack-a-standard.sh    # Deploy completo com verificação de conflito
    └── cleanup-stack-a-standard.sh   # Remove recursos
```

## 🚀 Instalação e Uso

Use o script de atalho para facilitar:

```bash
# 1. Instalar K3s
./scripts/shortcuts/stack-a-standard.sh install

# 2. Deploy da Stack
./scripts/shortcuts/stack-a-standard.sh deploy

# 3. Acessar Serviços (Port-forward)
./scripts/shortcuts/stack-a-standard.sh ports
```

> **⚠️ Exclusão Mútua:** Este deploy falhará se a Topologia Minimal (Docker Compose) estiver rodando. Pare-a antes de iniciar.

## 📦 Componentes

| Componente | Tipo | Namespace | Porta (Local) | Obs |
|------------|------|-----------|---------------|-----|
| PostgreSQL | StatefulSet | appgear | - | Acesso interno apenas |
| Redis | StatefulSet | appgear | - | Acesso interno apenas |
| LiteLLM | Deployment | appgear | 4000 | 2 Réplicas, Load Balanced |
| Flowise | Deployment | appgear | 3000 | Schema `public` |
| n8n | Deployment | appgear | 5678 | Schema `n8n` (isolado) |
| Prometheus | Deployment | observability | 9099 | Monitoramento de métricas |
| Grafana | Deployment | observability | 3001 | Dashboards visuais |

## 🔍 Diferenças vs Minimal

| Aspecto | Minimal (Compose) | Standard (K8s) |
|---------|-------------------|----------------|
| Orquestração | Docker Compose | Kubernetes (K3s) |
| Escalabilidade | Manual | Automática (HPA ready) |
| Alta Disponibilidade | Não | Sim (LiteLLM multi-réplica) |
| Observabilidade | Logs básicos | Prometheus + Grafana |
| Segurança | Básica | Secrets Management + RBAC |
| Dados | Volumes Docker | PVCs Persistentes |

---

**Versão:** 2.0
**Status:** ✅ Completa
**Data:** 28 de novembro de 2025
