# AppGear - Guias de Instalação

Guias completos de instalação da plataforma AppGear, organizados por topologia e complexidade.

---

## 📚 Guias Disponíveis

### Topologia A - Plataforma de Automação IA

#### 🟢 Minimal (FASE 1) - Disponível
- **Complexidade:** Básica
- **Componentes:** 7 serviços
- **Tempo:** 30-60 minutos
- **Recursos:** 4GB RAM, 2 CPUs, 10GB disco
- **Guia:** [installation-guide-topology-a-minimal.md](installation-guide-topology-a-minimal.md)

**O que inclui:**
- ✅ Traefik (Ingress)
- ✅ Kong (API Gateway)
- ✅ PostgreSQL (Banco de dados)
- ✅ Redis (Cache)
- ✅ LiteLLM (Gateway IA unificado)
- ✅ Flowise v1.4.7 (Workflows IA)
- ✅ n8n (Automação)

**Ideal para:**
- Desenvolvimento local
- Testes iniciais
- Validação de conceitos
- Aprendizado da plataforma

---

#### 🟡 Standard (FASE 2) - Em Desenvolvimento
- **Complexidade:** Intermediária
- **Componentes:** 15 serviços
- **Tempo:** 1-2 horas
- **Recursos:** 8GB RAM, 4 CPUs, 20GB disco
- **Guia:** `installation-guide-topology-a-standard.md` (futuro)

**Adiciona ao Minimal:**
- 🔄 Prometheus (Métricas)
- 🔄 Grafana (Dashboards)
- 🔄 Loki (Logs centralizados)
- 🔄 Directus (CMS Headless)
- 🔄 Appsmith (Low-code apps)
- 🔄 Metabase (Analytics)
- 🔄 Qdrant (Banco vetorial)
- 🔄 Vault (Secrets)

**Ideal para:**
- Ambientes de staging
- Projetos pequenos/médios
- Observabilidade completa
- RAG e embeddings

---

#### 🔴 Enterprise (FASE 3) - Planejado
- **Complexidade:** Avançada
- **Componentes:** 20+ serviços
- **Tempo:** 2-4 horas
- **Recursos:** 16GB RAM, 8 CPUs, 50GB disco
- **Guia:** `installation-guide-topology-a-enterprise.md` (futuro)

**Adiciona ao Standard:**
- Alta disponibilidade
- Backup automático
- Disaster recovery
- Multi-datacenter
- Segurança avançada

**Ideal para:**
- Produção
- Grandes volumes
- Compliance necessário
- SLA crítico

---

### Topologia B - Factory de MVPs (FASE 4+) - Planejado

#### 🟢 Minimal - Planejado
- Topologia A Standard + Templates MVP
- **Guia:** `installation-guide-topology-b-minimal.md` (futuro)

#### 🟡 Standard - Planejado
- CI/CD completo
- Testes automatizados
- Deploy multi-ambiente
- **Guia:** `installation-guide-topology-b-standard.md` (futuro)

---

## 🗺️ Roadmap de Guias

| Guia | Status | Previsão |
|------|--------|----------|
| **Topology A - Minimal** | ✅ Completo | - |
| Topology A - Standard | 🔄 Desenvolvimento | FASE 2 |
| Topology A - Enterprise | 📋 Planejado | FASE 3 |
| Topology B - Minimal | 📋 Planejado | FASE 4 |
| Topology B - Standard | 📋 Planejado | FASE 5 |

**Legenda:** ✅ Disponível | 🔄 Em desenvolvimento | 📋 Planejado

---

## 🚀 Como Escolher o Guia Correto

### Começando do Zero?
👉 **Use: Topology A - Minimal**
- Mais simples e rápido
- Aprenda os conceitos
- Valide a plataforma

### Já testou o Minimal?
👉 **Próximo: Topology A - Standard**
- Adiciona observabilidade
- Mais ferramentas (CMS, Analytics)
- Ambiente mais robusto

### Precisa de Produção?
👉 **Use: Topology A - Enterprise**
- Alta disponibilidade
- Backup e DR
- Segurança reforçada

### Quer criar MVPs rapidamente?
👉 **Use: Topology B**
- Templates prontos
- CI/CD automatizado
- Deploy rápido

---

## 📋 Pré-Requisitos Gerais

Todos os guias requerem:

### Hardware Mínimo (varia por topologia)
- Ver guia específico

### Software Base
- **SO:** Linux (Ubuntu 20.04+), macOS, ou Windows 10/11 com WSL2
- **Git:** 2.0+
- **Docker:** 20.10+
- **Docker Compose:** 1.29+ ou V2

### Conhecimentos
- Terminal/linha de comando
- Conceitos básicos de Docker
- Edição de arquivos

### Chaves de API
- OpenAI, Anthropic, Groq, ou Ollama local

---

## 📚 Estrutura dos Guias

Cada guia segue o mesmo formato:

1. **Pré-requisitos** - Hardware, software, conhecimentos
2. **Preparação** - Sistema, dependências
3. **Clonagem** - Repositório
4. **Configuração** - Variáveis, secrets
5. **Instalação** - Docker, compose
6. **Inicialização** - Stack completa
7. **Verificação** - Testes, validação
8. **Acesso** - Interfaces, credenciais
9. **Troubleshooting** - Problemas comuns
10. **Próximos Passos** - O que fazer depois

---

## 🔄 Migrações Entre Topologias

### De Minimal para Standard
- Manter dados PostgreSQL
- Adicionar novos serviços
- Atualizar configurações
- **Guia:** `migration-minimal-to-standard.md` (futuro)

### De Standard para Enterprise
- Configurar HA
- Adicionar backups
- Implementar DR
- **Guia:** `migration-standard-to-enterprise.md` (futuro)

---

## 🆘 Suporte

### Problemas durante instalação?
1. Consulte seção **Troubleshooting** do guia específico
2. Verifique [Issues no GitHub](../../issues)
3. Revise documentação em `docs/`

### Dúvidas sobre qual topologia usar?
- Veja seção "Como Escolher o Guia Correto" acima
- Comece sempre pelo **Minimal**
- Escale conforme necessidade

---

## 📝 Contribuindo com os Guias

Encontrou um erro? Quer melhorar algo?

1. Fork o repositório
2. Edite o guia em `docs/guides/`
3. Teste suas mudanças
4. Abra um Pull Request

---

## 🔖 Versões dos Guias

| Guia | Versão | Última Atualização |
|------|--------|-------------------|
| Topology A - Minimal | 1.1 | 27/11/2025 |
| Outros | - | - |

---

**Autor:** Paulo Lima + Antigravity AI  
**Projeto:** AppGear - AI-First Business Ecosystem Generator  
**Licença:** Ver LICENSE.md

---

✨ **Escolha seu guia e comece a implantação!** 🚀
