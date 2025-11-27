# Development - AppGear

Este diretório contém todos os módulos técnicos e código de desenvolvimento da plataforma.

---

## 📁 Estrutura

```
development/
├── v0/                    # Baseline v0 (estável)
├── v0.1/                  # Versão 0.1
├── v0.2/                  # Versão 0.2
├── v0.3/                  # ✅ Retrofit v0.3 (ATIVO - linha de desenvolvimento)
│   ├── stack-unificada-v0.3.yaml    # Baseline da stack v0.3
│   └── modulos/                     # Módulos M00-M17
└── ...
```

---

## 🎯 Versões Ativas

| Versão | Status | Uso | Estabilidade |
|--------|--------|-----|--------------|
| **v0** | ✅ Estável | Baseline original | Congelado |
| **v0.3** | ✅ Ativo | Retrofit em andamento | Em desenvolvimento |

---

## 📦 Módulos Técnicos (v0.3)

### Stack Core (M00-M05) - Infraestrutura Base

| ID | Módulo | Status | Descrição |
|----|--------|--------|-----------|
| M00 | Fundamentos | ✅ Retrofitted | `.env`, stack unificada, convenções |
| M01 | GitOps | ✅ Retrofitted | Argo CD, ApplicationSets |
| M02 | Cadeia de Borda | ✅ Retrofitted | Traefik→Coraza→Kong→Istio |
| M03 | Observabilidade | ✅ Retrofitted | Prometheus, Grafana, Loki |
| M04 | Bancos de Dados | ✅ Retrofitted | PostgreSQL, Redis, Qdrant, Redpanda |
| M05 | Segurança Base | ✅ Retrofitted | Vault, OPA/Kyverno, Falco |

### Services Core (M06-M08)

| ID | Módulo | Status | Descrição |
|----|--------|--------|-----------|
| M06 | Identidade | 🟡 Em progresso | Keycloak, midPoint, OpenFGA |
| M07 | Backstage | 🟡 Em progresso | Portal unificado, FinOps |
| M08 | Apps Core | 🟡 Em progresso | LiteLLM, Flowise, n8n, Directus, Appsmith |

### Business Suites (M09-M12)

| ID | Suite | Status | Descrição |
|----|-------|--------|-----------|
| M09 | Factory | 🟡 Em progresso | Geração de código, CDEs |
| M10 | Brain | 🟡 Em progresso | RAG, AI Agents, AutoML |
| M11 | Operations | 🟡 Em progresso | Digital Twins, RPA, API Economy |
| M12 | Guardian | 🟡 Em progresso | Security Suite, Legal AI, IGA |

### Advanced Features (M13-M17)

| ID | Módulo | Status | Descrição |
|----|--------|--------|-----------|
| M13 | Workspaces | ⏳ Planejado | vClusters, multi-tenancy |
| M14 | Pipelines AI-First | ⏳ Planejado | Gate de IA, SBOM, RAPID |
| M15 | DR/Backup | ⏳ Planejado | Velero, VolumeSnapshots |
| M16 | Conectividade | ⏳ Planejado | Tailscale mesh VPN |
| M17 | Políticas | ⏳ Planejado | Policy-as-Code, compliance |

---

## 🎯 Stack Unificada v0.3

Arquivo central: `v0.3/stack-unificada-v0.3.yaml`

Define:
- ✅ Componentes oficiais (Core + Add-ons)
- ✅ Ordem de implantação
- ✅ Dependências entre módulos
- ✅ Edge pipeline (Traefik→Coraza→Kong→Istio)
- ✅ Estratégias Argo CD

---

## 🔄 Workflow de Desenvolvimento

### 1. Trabalhar em Módulo

```bash
cd development/v0.3/modulos/M[XX]-nome-do-modulo/
```

### 2. Validar Mudanças

```bash
# Da raiz do repositório
./scripts/run_all_checks.py
```

### 3. Testar Localmente

```bash
# Topology A (Docker Compose)
cd deployments/topology-a/minimal
docker-compose up -d

# Ou Topology B (Kubernetes)
cd deployments/topology-b/minimal
kubectl apply -f .
```

### 4 Commit e Push

```bash
git add development/v0.3/
git commit -m "feat(M00): descrição da mudança"
git push
```

---

## 📚 Documentação Relacionada

- **Contrato de Arquitetura:** `../docs/architecture/contract/contract-v0.md`
- **Interoperabilidade:** `../docs/architecture/interoperability/interoperability-v0.md`
- **Roadmap:** `../roadmap/roadmap_retrofit.md`

---

## 🎓 Convenções

### Nomenclatura de Módulos
- Format: `MXX-nome-do-modulo-vX.md`
- Exemplo: `M00-Fundamentos-v0.3.md`

### Versionamento
- v0: Baseline original (estável, congelado)
- v0.1, v0.2: Iterações intermediárias
- v0.3: Linha de desenvolvimento ativa (retrofit)

### Estrutura de Módulo
```
modulos/MXX-nome/
├── MXX-nome-vX.md        # Documentação técnica
├── manifests/            # YAMLs Kubernetes
├── compose/              # docker-compose snippets
└── examples/             # Exemplos de uso
```

---

**Mantido por:** Equipe AppGear  
**Última Atualização:** 27 de novembro de 2025
