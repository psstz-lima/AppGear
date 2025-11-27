# Scripts - AppGear

Scripts utilitários para validação, testes e automação.

---

## 📁 Scripts Disponíveis

### Validação de Topologias

**`validate-topology-a.sh`** ✅
- Valida Topologia A (Docker Compose)
- Verifica 7 serviços rodando
- Testa cadeia de borda
- Valida acessibilidade

```bash
./scripts/validate-topology-a.sh
```

**`validate-topology-b.sh`**
- Valida Topologia B (Kubernetes)
- Verifica namespaces, pods
- Testa GitOps, Istio, KEDA

```bash
./scripts/validate-topology-b.sh
```

### Validação de Documentação

**`run_all_checks.py`** ✅
- Executa todos os checks de documentação
- 5 validações automatizadas

```bash
python3 scripts/run_all_checks.py
```

**`check_docs.py`** ✅
- Valida matriz de módulos e componentes
- Verifica consistency

**`edge_chain.py`** ✅
- Valida cadeia de borda (Traefik→Coraza→Kong→Istio)
- 4 testes pytest

**`docs_semantic_checks.py`** ✅
- Valida cruzamento módulos/fluxos/mapa

**`modules_files_checks.py`** ✅
- Valida existência de arquivos de módulos

**`modules_gitops_checks.py`** ✅
- Valida estrutura GitOps/Kustomize

---

## 🚀 Uso

### Quick Validation

```bash
# Validar tudo
cd /home/paulo-lima/AppGear
./scripts/run_all_checks.py

# Validar Topology A
./scripts/validate-topology-a.sh
```

### Executar da Raiz

**IMPORTANTE:** Todos os scripts devem ser executados da raiz do repositório:

```bash
# ✅ CORRETO
cd /home/paulo-lima/AppGear
./scripts/validate-topology-a.sh

# ❌ ERRADO
cd scripts
./validate-topology-a.sh
```

---

## 📊 Status dos Scripts

| Script | Status | Checks | Última Validação |
|--------|--------|--------|------------------|
| `validate-topology-a.sh` | ✅ OK | 10 checks | 27/nov/2025 |
| `validate-topology-b.sh` | ✅ OK | 12 checks | - |
| `run_all_checks.py` | ✅ OK | 5 validações | 27/nov/2025 |
| `check_docs.py` | ✅ OK | Matriz OK | 27/nov/2025 |
| `edge_chain.py` | ✅ OK | 4/4 testes | 27/nov/2025 |

---

**Mantido por:** Equipe AppGear  
**Última Atualização:** 27 de novembro de 2025
