# AppGear - Plataforma de Automação e IA

**Status:** ✅ FASE 2 Completa | Topologias: Minimal (Compose) + Standard (K8s)

---

## 🚀 Início Rápido

### Topologia A Minimal (Docker Compose)
Ideal para desenvolvimento local rápido.

```bash
# Iniciar
./scripts/shortcuts/stack-a-minimal.sh start

# Acessar
# Flowise:  http://localhost:3000
# LiteLLM:  http://localhost:4000
# n8n:      http://localhost:5678
```

### Topologia A Standard (Kubernetes)
Ideal para staging/produção com observabilidade.

```bash
# Instalar K3s (primeira vez)
./scripts/shortcuts/stack-a-standard.sh install

# Deploy
./scripts/shortcuts/stack-a-standard.sh deploy

# Criar port-forwards
./scripts/shortcuts/stack-a-standard.sh ports

# Acessar
# Flowise:    http://localhost:3000
# LiteLLM:    http://localhost:4000
# n8n:        http://localhost:5678
# Prometheus: http://localhost:9099
# Grafana:    http://localhost:3001 (admin/appgear_grafana_2025)
```

### Topologia A Full (Fase 3)
*Em breve: Acesso via Ingress (sem port-forward) e WAF.*
```bash
# 🚧 Planejado para Fase 3
```

### Topologia B (Fase 4)
*Em breve: Ambiente Enterprise com Istio, Vault e GitOps.*
```bash
# 🚧 Planejado para Fase 4
```

> **⚠️ Importante:** As topologias são mutuamente exclusivas. O sistema impedirá que você inicie uma se a outra estiver rodando para evitar conflitos de porta e dados. Use `cleanup` antes de trocar.

---

## 📦 O que é AppGear?

Plataforma modular para automação e workflows de IA, integrando:

- **LiteLLM** - Gateway unificado para LLMs (Groq, OpenAI)
- **Flowise** - Constructor visual de workflows de IA
- **n8n** - Automação de processos
- **PostgreSQL** - Banco de dados persistente
- **Redis** - Cache de alto desempenho
- **Prometheus + Grafana** - Observabilidade completa _(K8s)_

---

## 🗂️ Estrutura do Projeto

```
AppGear/
├── deployments/
│   └── topology-a/
│       ├── minimal/          # Docker Compose
│       └── standard/         # Kubernetes (K3s)
│
├── scripts/
│   ├── shortcuts/            # Atalhos de gerenciamento
│   │   ├── stack-a-minimal.sh
│   │   └── stack-a-standard.sh
│   ├── topology-a-minimal/   # Scripts Minimal
│   └── topology-a-standard/  # Scripts Standard
│
├── docs/                     # Documentação completa
└── .secrets/                # Credenciais (não versionado)
```

---

## 🎯 Funcionalidades por Topologia

| Funcionalidade | Minimal | Standard |
|----------------|---------|----------|
| **Orquestração** | Docker Compose | Kubernetes (K3s) |
| **Escalabilidade** | Manual | Automática (HPA) |
| **Alta Disponibilidade** | ❌ | ✅ (2x LiteLLM) |
| **Observabilidade** | Logs | Prometheus + Grafana |
| **Storage** | Volumes | PVCs (35Gi) |
| **RBAC** | ❌ | ✅ |
| **Secrets** | .env | K8s Secrets |

---

## 📚 Documentação

### Guias de Instalação
- [Topologia A Minimal](docs/guides/installation-guide-topology-a-minimal.md)
- [Topologia A Standard](deployments/topology-a/standard/README.md)

### Scripts
- [Guia Rápido](scripts/QUICKSTART.md)
- [README Scripts](scripts/README.md)

### Status e Planejamento
- [Status Atual](STATUS-ATUAL.md) - Estado do projeto
- [Roadmap](development/README.md) - Planejamento futuro

---

## 🧪 Testes

### Minimal (Docker Compose)
```bash
./scripts/shortcuts/stack-a-minimal.sh test
```

### Standard (Kubernetes)
```bash
./scripts/topology-a-standard/test-e2e-a-standard.sh
```

---

## 🔧 Troubleshooting

### Minimal
Veja [installation-guide-topology-a-minimal.md](docs/guides/installation-guide-topology-a-minimal.md#troubleshooting)

### Standard
```bash
# Ver logs
./scripts/shortcuts/stack-a-standard.sh logs <pod-name>

# Status detalhado
./scripts/shortcuts/stack-a-standard.sh status

# Recrear deployment
kubectl rollout restart deployment/<name> -n appgear
```

---

## 🤝 Contribuindo

1. Clone o repositório
2. Siga os guias de instalação
3. Execute os testes E2E antes de commits

---

## 📄 Licença

Este projeto está licenciado sob a [Proprietary License](LICENSE.md).

---

## 🏆 Status do Projeto

### FASE 1: Topologia A Minimal (Docker Compose)
- **Status:** ✅ CONCLUÍDA (100%)
- **Foco:** Desenvolvimento local, testes rápidos.

### FASE 2: Topologia A Standard (Kubernetes)
- **Status:** ✅ CONCLUÍDA (100%)
- **Foco:** Staging, validação de arquitetura K8s.

### FASE 3 Topologia A Full (Planejada)
- **Status:** 🔮 PLANEJADA
- **Foco:** Ingress, WAF, Dashboards de Negócio.

### FASE 4: Topologia B (Enterprise)
- **Status:** 🔮 PLANEJADA
- **Foco:** Produção em escala, multi-tenancy.
- **Features:** Istio, Vault, vClusters, ArgoCD.

**Última Atualização:** 29 de novembro de 2025

---

**Desenvolvido com ❤️ usando Kubernetes, Docker, e as melhores práticas DevOps**
