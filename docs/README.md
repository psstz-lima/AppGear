# Documentação - AppGear

Este diretório contém toda a documentação oficial da plataforma AppGear.

---

## 📁 Estrutura

```
docs/
├── README.md                  # Este arquivo
├── architecture/              # Documentação de arquitetura (oficial)
│   ├── contract/              # Contrato v0 (fonte da verdade)
│   ├── audit/                 # Auditoria v0
│   ├── interoperability/      # Interoperabilidade v0
│   └── ...
├── guides/                    # Guias práticos
│   ├── ai-ci-cd-flow.md
│   ├── keda-scale-to-zero.md
│   ├── integrated-report.md
│   └── ...
├── reports/                   # Relatórios técnicos
│   └── ...
└── policy/                    # Políticas e governance
    └── ...
```

---

## 📚 Documentação por Categoria

### Arquitetura Oficial (OBRIGATÓRIA)

📍 `architecture/contract/`
- **contract-v0.md** - Contrato de arquitetura (fonte da verdade)
- Define stack, topologias, multi-tenancy, segurança

📍 `architecture/audit/`
- **audit-v0.md** - Guideline de auditoria
- Como auditar a plataforma contra o contrato

📍 `architecture/interoperability/`
- **interoperability-v0.md** - Regras de interoperabilidade
- Como módulos se integram
- Mapa global, fluxos AI-First

### Guias Práticos

📍 `guides/`
- **ai-ci-cd-flow.md** - Fluxo CI/CD orientado por IA
- **keda-scale-to-zero.md** - Como usar KEDA
- **integrated-report.md** - Procedimento de relatórios

### Relatórios

📍 `reports/`
- Relatórios técnicos e análises

### Políticas

📍 `policy/`
- Políticas de governança
- Compliance e regulamentações

---

## 🎯 Ordem de Leitura Recomendada

### Para Novos Desenvolvedores

1. **README.md** (raiz do repositório)
2. **MANIFESTO.md** (raiz - entenda a visão)
3. **architecture/contract/contract-v0.md** (arquitetura oficial)
4. **architecture/interoperability/interoperability-v0.md**
5. **guides/** (guias práticos conforme necessidade)

### Para Auditores

1. **architecture/contract/contract-v0.md**
2. **architecture/audit/audit-v0.md**
3. **architecture/interoperability/interoperability-v0.md**
4. **development/v0.3/** (módulos técnicos)

### Para Operadores

1. **deployments/topology-a/README-topology-a.md**
2. **guides/keda-scale-to-zero.md**
3. **guides/ai-ci-cd-flow.md**
4. **architecture/interoperability/** (troubleshooting)

---

## 📖 Documentos Principais

| Documento | Caminho | Status | Importância |
|-----------|---------|--------|-------------|
| Contrato v0 | `architecture/contract/contract-v0.md` | ✅ Completo | **CRÍTICO** |
| Auditoria v0 | `architecture/audit/audit-v0.md` | ✅ Completo | Alta |
| Interoperabilidade v0 | `architecture/interoperability/interoperability-v0.md` | ✅ Completo | Alta |
| AI-CI/CD Flow | `guides/ai-ci-cd-flow.md` | ✅ Completo | Média |
| KEDA Guide | `guides/keda-scale-to-zero.md` | ✅ Completo | Média |

---

## 🔍 Como Encontrar Documentação

### Por Tópico

**Arquitetura Geral:**
```bash
cat architecture/contract/contract-v0.md
```

**Como Auditar:**
```bash
cat architecture/audit/audit-v0.md
```

**Como Integrar Módulos:**
```bash
cat architecture/interoperability/interoperability-v0.md
```

**Fluxo CI/CD:**
```bash
cat guides/ai-ci-cd-flow.md
```

### Por Módulo (M00-M17)

Documentação dos módulos técnicos está em:
```bash
../development/v0.3/modulos/
```

---

## 📝 Contribuindo com Documentação

### Adicionando Novos Guias

1. Criar arquivo em `guides/`
2. Seguir template padrão
3. Adicionar referência neste README
4. Commit com mensagem descritiva

### Atualizando Arquitetura

> ⚠️ **ATENÇÃO:** Documentos em `architecture/` são oficiais!

Mudanças requerem:
1. Discussão prévia
2. Validação técnica
3. Atualização de versão
4. Comunicação para toda equipe

---

## 🎓 Convenções de Documentação

### Formato
- Markdown (.md) para tudo
- UTF-8 sem BOM
- LF line endings (Unix)

### Estrutura de Documento
```markdown
# Título
## Visão Geral
## Seção Principal 1
## Seção Principal 2
---
**Versão:** X.Y
**Data:** DD/MM/AAAA
```

### Links Internos
```markdown
[Texto](../caminho/relativo/arquivo.md)
[Seção](#ancor-em-kebab-case)
```

---

**Mantido por:** Equipe AppGear  
**Última Atualização:** 27 de novembro de 2025
