# Scripts de Gerenciamento AppGear

Scripts organizados por topologia para facilitar o gerenciamento da stack.

## 📁 Estrutura

```
scripts/
├── topology-a-minimal/      # Topologia A Minimal (Docker Compose)
│   ├── startup-stack.sh     # Inicia stack
│   ├── shutdown-stack.sh    # Para stack
│   ├── status-stack.sh      # Status detalhado
│   └── README.md            # Documentação específica
│
├── topology-a-standard/     # [FUTURO] Topologia A Standard (Kubernetes)
├── topology-b/              # [FUTURO] Topologia B
│
├── validate-topology-a.sh   # Validação Topologia A
├── validate-topology-b.sh   # Validação Topologia B
└── README.md               # Este arquivo
```

---

## 🎯 Quick Start

### Topologia A Minimal (Atual)

```bash
# Iniciar stack
sudo ./scripts/topology-a-minimal/startup-stack.sh

# Ver status
sudo ./scripts/topology-a-minimal/status-stack.sh

# Parar stack
sudo ./scripts/topology-a-minimal/shutdown-stack.sh
```

**Documentação completa:** [topology-a-minimal/README.md](topology-a-minimal/README.md)

---

## 📚 Por Topologia

### Topologia A Minimal
**Status:** ✅ Implementada (Docker Compose)  
**Ambiente:** Desenvolvimento local  
**Scripts:** 3 (startup, shutdown, status)

**Serviços:**
- PostgreSQL, Redis
- Traefik, Kong
- LiteLLM (Groq)
- Flowise, n8n

**Ver:** [topology-a-minimal/](topology-a-minimal/)

---

### Topologia A Standard
**Status:** ⏳ Planejada (FASE 2)  
**Ambiente:** Produção (Kubernetes)  
**Adiciona:**
- Coraza WAF
- Istio Service Mesh
- Prometheus, Grafana
- Jaeger (tracing)

---

### Topologia B
**Status:** ⏳ Planejada (FASE 3)  
**Ambiente:** Multi-tenant  
**Adiciona:**
- Separação por tenant
- Multi-região
- HA (High Availability)

---

## 🔧 Scripts de Validação

### validate-topology-a.sh
Valida implementação da Topologia A.

```bash
./scripts/validate-topology-a.sh
```

### validate-topology-b.sh
Valida implementação da Topologia B.

```bash
./scripts/validate-topology-b.sh
```

---

## 📖 Convenções

### Nomenclatura
- **Topologia:** `topology-{letra}-{variante}/`
- **Scripts:** `{ação}-stack.sh`

### Exemplos
- `topology-a-minimal/startup-stack.sh`
- `topology-a-standard/startup-stack.sh`
- `topology-b/startup-stack.sh`

### Permissões
Todos os scripts de gerenciamento requerem **sudo**.

---

## 🚀 Roadmap

- [x] **FASE 1:** Topologia A Minimal (Docker Compose) - ✅ Concluída
- [ ] **FASE 2:** Topologia A Standard (Kubernetes + Observabilidade)
- [ ] **FASE 3:** Topologia B (Multi-tenant)

---

**Última atualização:** 28 de novembro de 2025  
**Versão:** 1.0
