# AppGear - Estrutura do Repositório

**Versão:** 2.0 - Reorganizado  
**Data:** 27 de novembro de 2025

---

## 📁 Estrutura Completa

```
AppGear/
│
├── 📋 Arquivos Raiz (Informação Geral)
│   ├── README.md                    # Este arquivo - Visão geral
│   ├── LICENSE.md                   # Licença
│   ├── MANIFESTO.md                 # Visão e história do projeto
│   ├── STATUS-ATUAL.md              # Status atual do projeto
│   ├── NOTICE.md                    # Avisos legais
│   ├── THIRD_PARTY_LICENSES.md      # Licenças de terceiros
│   ├── requirements.txt             # Dependências Python
│   └── requirements-tests.txt       # Dependências de teste
│
├── 🚀 deployments/                  # IMPLANTAÇÕES (Ambientes prontos)
│   ├── README.md                    # Documentação de deployments
│   ├── topology-a/                  # Docker Compose
│   │   ├── README-topology-a.md     # Guia completo Topologia A
│   │   ├── minimal/                 # ✅ 7 componentes (PRONTO)
│   │   │   ├── docker-compose.yml
│   │   │   ├── .env.example
│   │   │   └── config/
│   │   ├── standard/                # 15 componentes (FUTURO)
│   │   └── full/                    # 25+ componentes (FUTURO)
│   └── topology-b/                  # Kubernetes
│       ├── README-topology-b.md     # (FUTURO)
│       ├── minimal/                 # K8s minimal (FUTURO)
│       ├── standard/                # K8s standard (FUTURO)
│       └── enterprise/              # K8s enterprise (FUTURO)
│
├── 📚 docs/                         # DOCUMENTAÇÃO
│   ├── README.md                    # Índice de documentação
│   ├── architecture/                # Arquitetura oficial
│   │   ├── contract/                # Contrato v0 (fonte da verdade)
│   │   ├── audit/                   # Auditoria v0
│   │   ├── interoperability/        # Interoperabilidade v0
│   │   └── ...
│   ├── guides/                      # Guias práticos
│   │   ├── ai-ci-cd-flow.md
│   │   ├── keda-scale-to-zero.md
│   │   └── ...
│   ├── reports/                     # Relatórios técnicos
│   └── policy/                      # Políticas e governance
│
├── 🔧 development/                  # DESENVOLVIMENTO (Módulos técnicos)
│   ├── README.md                    # Guia de desenvolvimento
│   ├── v0/                          # Baseline v0 (estável)
│   ├── v0.1/                        # Versão 0.1
│   ├── v0.2/                        # Versão 0.2
│   ├── v0.3/                        # ✅ Retrofit v0.3 (ATIVO)
│   │   ├── stack-unificada-v0.3.yaml
│   │   └── modulos/ (M00-M17)
│   └── ...
│
├── 📦 gitops/                       # GITOPS (Argo CD - Topologia B)
│   ├── README.md
│   ├── apps/                        # Applications (90+)
│   ├── appsets/                     # ApplicationSets
│   └── bootstrap/                   # App-of-Apps bootstrap
│
├── 🛠️  scripts/                     # SCRIPTS UTILITÁRIOS
│   ├── README.md
│   ├──  validate-topology-a.sh       # ✅ Validação Docker Compose
│   ├── validate-topology-b.sh       # Validação Kubernetes
│   ├── run_all_checks.py            # Checks de documentação
│   ├── check_docs.py
│   ├── edge_chain.py
│   └── ...
│
├── 🗺️  roadmap/                     # ROADMAPS E PLANEJAMENTO
│   ├── README.md
│   └── roadmap_retrofit.md          # Roadmap completo de retrofit
│
├── 📦 archive/                      # CÓDIGO LEGADO (deprecated)
│   └── ...
│
└── .archive/                        # Arquivos temporários da reorganização
    └── oldstructure/
```

---

## 🎯 Onde Encontrar Cada Coisa

### Para USAR a Plataforma
📍 **deployments/**
- Docker Compose: `deployments/topology-a/minimal/`
- Kubernetes: `deployments/topology-b/` (futuro)
- Guias: `deployments/topology-a/README-topology-a.md`

### Para ENTENDER a Arquitetura
📍 **docs/architecture/**
- Contrato: `docs/architecture/contract/contract-v0.md`
- Auditoria: `docs/architecture/audit/audit-v0.md`
- Interoperabilidade: `docs/architecture/interoperability/interoperability-v0.md`

### Para DESENVOLVER Módulos
📍 **development/**
- Módulos v0.3: `development/v0.3/`
- Stack unificada: `development/v0.3/stack-unificada-v0.3.yaml`
- Módulos técnicos: M00-M17

### Para VALIDAR Configurações
📍 **scripts/**
- Topology A: `./scripts/validate-topology-a.sh`
- Topology B: `./scripts/validate-topology-b.sh`
- Docs: `./scripts/run_all_checks.py`

### Para ENTENDER o Projeto
📍 **Raiz do repositório:**
- README.md (você está aqui)
- MANIFESTO.md (história e visão)
- STATUS-ATUAL.md (estado atual)

---

## 🚀 Quick Start

### 1. Primeira Vez - Ler Documentação
```bash
# Entender o projeto
cat README.md
cat MANIFESTO.md
cat STATUS-ATUAL.md

# Entender arquitetura
cat docs/architecture/contract/contract-v0.md
```

### 2. Implantar Topologia A (Docker Compose)
```bash
# Navegar para deployment
cd deployments/topology-a/minimal

# Configurar
cp .env.example .env
nano .env  # Adicione sua OPENAI_API_KEY

# Iniciar
docker-compose up -d

# Validar
cd ../../..
./scripts/validate-topology-a.sh
```

### 3. Explorar Componentes
- **Flowise:** http://localhost:3000 (admin / appgear_dev)
- **n8n:** http://localhost:5678 (admin / appgear_dev)
- **Traefik:** http://localhost:8080

---

## 📊 Status por Diretório

| Diretório | Status | Descrição |
|-----------|--------|-----------|
| `deployments/topology-a/minimal/` | ✅ Pronto | Docker Compose funcional |
| `deployments/topology-a/standard/` | ⏳ Planejado | 15 componentes |
| `deployments/topology-b/` | ⏳ Planejado | Kubernetes (Semana 6-9) |
| `docs/architecture/` | ✅ Completo | Documentação oficial |
| `development/v0.3/` | ✅ Ativo | Módulos M00-M17 |
| `gitops/` | ✅ Estruturado | 90+ apps Argo CD |
| `scripts/` | ✅ Funcionando | 5/5 checks passando |
| `roadmap/` | ✅ Documentado | Plano completo |

---

## 🎓 Convenções

### Nomenclatura de Arquivos
- **Configuração:** `*.yml`, `*.yaml`
- **Documentação:** `*.md` (Markdown)
- **Scripts:** `*.sh` (Shell), `*.py` (Python)
- **Exemplos:** `*.example`

### Estrutura de Diretórios
- **Raiz:** Informações gerais e arquivos de projeto
- **deployments/:** Ambientes prontos para uso
- **docs/:** Documentação oficial e guias
- **development/:** Código e módulos técnicos
- **scripts/:** Ferramentas e validações
- **gitops/:** Manifests Argo CD (Topologia B)

---

## 🔄 Navegação Rápida

### Arquivos Importantes (Raiz)
```bash
README.md                # Você está aqui
MANIFESTO.md             # História do projeto
STATUS-ATUAL.md          # Estado atual
```

### Começar a Usar
```bash
cd deployments/topology-a/minimal
docker-compose up -d
```

### Entender Arquitetura
```bash
cd docs/architecture/contract
cat contract-v0.md
```

### Validar Configurações
```bash
./scripts/validate-topology-a.sh
./scripts/run_all_checks.py
```

---

## 📝 Changelog da Reorganização

### v2.0 - 27/nov/2025
- ✅ Separados deployments, docs, development
- ✅ Movidos guides/ → docs/guides/
- ✅ Movidos reports/ → docs/reports/
- ✅ Movidos policy/ → docs/policy/
- ✅ Criada estrutura topology-a/{minimal,standard,full}
- ✅ Criada estrutura topology-b/{minimal,standard,enterprise}
- ✅ Todos os caminhos atualizados
- ✅ READMEs em cada nível

### v1.0 - Original
- Estrutura plana na raiz

---

## 🆘 Troubleshooting

### "Não encontro o docker-compose.yml"
```bash
# Agora está em:
cd deployments/topology-a/minimal
```

### "Scripts não funcionam"
```bash
# Execute da raiz do repositório:
./scripts/validate-topology-a.sh
```

### "Onde está a documentação?"
```bash
# Arquitetura oficial:
docs/architecture/

# Guias práticos:
docs/guides/
```

---

**Mantido por:** Paulo Lima + Antigravity AI  
**Última Atualização:** 27 de novembro de 2025, 02:20  
**Versão da Estrutura:** 2.0
