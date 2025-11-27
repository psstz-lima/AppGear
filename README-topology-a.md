# AppGear - Topologia A (Docker Compose)
## Guia de início rápido - Stack mínima

**Tempo de Setup:** ~15 minutos  
**Recursos Necessários:** 4GB RAM, 2 CPU, 10GB disco  
**Componentes:** 7 serviços core

---

## 📋 Pré-requisitos

- ✅ **Docker** instalado e rodando (versão 20.10+)
- ✅ **Docker Compose** (versão 2.0+)
- ✅ **4GB RAM** disponível
- ✅ **10GB disco** disponível
- ✅ **Chave de API** de algum provedor de IA (OpenAI, Anthropic, Groq, ou Ollama local)

### Verificar Instalação

```bash
docker --version
docker-compose --version
docker ps  # Deve rodar sem erro
```

---

## 🚀 Setup em 3 Passos

### 1. Configurar Variáveis de Ambiente

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar .env e configurar:
nano .env  # ou seu editor preferido

# IMPORTANTE: Configurar pelo menos:
# - OPENAI_API_KEY (ou outro provider)
# - Trocar senhas default
```

### 2. Iniciar Stack

```bash
# Iniciar todos os serviços
docker-compose up -d

# Aguardar ~2 minutos para todos iniciarem
docker-compose logs -f
```

### 3. Verificar Funcionamento

```bash
# Executar script de validação
./scripts/validate-topology-a.sh

# Ou verificar manualmente:
docker-compose ps
# Todos os 7 serviços devem estar "Up"
```

---

## 🌐 Acessar Serviços

Após inicialização bem-sucedida:

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Traefik Dashboard** | http://localhost:8080 | Sem autenticação (dev) |
| **Kong Admin API** | http://localhost:8001 | Sem autenticação (dev) |
| **Flowise** | http://localhost:3000 | admin / appgear_dev |
| **n8n** | http://localhost:5678 | admin / appgear_dev |
| **PostgreSQL** | localhost:5432 | appgear / appgear_dev_password |
| **Redis** | localhost:6379 | Senha: appgear_redis_dev |
| **LiteLLM** | http://localhost:4000 | Header: Authorization: Bearer sk-appgear-dev-key |

---

## 📊 Componentes do Stack

### 1. Traefik (Ingress Controller)
- **Porta:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Função:** Entrypoint de borda, roteamento HTTP
- **Dashboard:** http://localhost:8080

### 2. Kong (API Gateway)
- **Porta:** 8000 (Proxy), 8001 (Admin)
- **Função:** API Gateway, gerenciamento de rotas
- **Config:** `config/kong.yml`

### 3. PostgreSQL (Banco de Dados)
- **Porta:** 5432
- **Função:** Banco principal (Flowise, n8n, LiteLLM, apps)
- **Schemas:** flowise, n8n, litellm, apps, public

### 4. Redis (Cache)
- **Porta:** 6379
- **Função:** Cache, sessões, filas
- **Usado por:** LiteLLM (cache de respostas), n8n, Flowise

### 5. LiteLLM (Gateway Único de IA) ⭐ CRÍTICO
- **Porta:** 4000
- **Função:** Gateway centralizando acesso a LLMs
- **Providers:** OpenAI, Anthropic, Ollama, Groq, etc.
- **Config:** `config/litellm-config.yaml`

**Regra de Ouro:** TODO acesso a LLMs deve passar pelo LiteLLM!

### 6. Flowise (Orquestração IA)
- **Porta:** 3000
- **Função:** Criar workflows visuais de IA
- **Usa:** LiteLLM, PostgreSQL

### 7. n8n (Automação)
- **Porta:** 5678
- **Função:** Workflows de automação
- **Usa:** LiteLLM, PostgreSQL

---

## 🧪 Testando o Stack

### Teste 1: Verificar Todos os Serviços

```bash
# Listar todos os containers
docker-compose ps

# Verificar logs de um serviço específico
docker-compose logs flowise

# Verificar saúde
docker-compose exec postgres pg_isready
docker-compose exec redis redis-cli ping
```

### Teste 2: LiteLLM (Gateway de IA)

```bash
# Testar API do LiteLLM
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-appgear-dev-key" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Teste 3: Criar Workflow no Flowise

1. Acessar http://localhost:3000
2. Login: admin / appgear_dev
3. Criar novo workflow
4. Adicionar node "LLM Chain"
5. Configurar para usar LiteLLM endpoint: `http://litellm:4000`
6. Executar e testar

### Teste 4: Cadeia de Borda

```bash
# Testar roteamento Traefik → Kong → LiteLLM
curl http://localhost/api/litellm/health

# Verificar Traefik Dashboard
open http://localhost:8080
```

---

## 🔧 Troubleshooting

### Problema: Serviço não inicia

```bash
# Ver logs do serviço
docker-compose logs [nome-do-serviço]

# Reiniciar serviço específico
docker-compose restart [nome-do-serviço]

# Rebuild se necessário
docker-compose up -d --build [nome-do-serviço]
```

### Problema: LiteLLM não conecta ao provider

```bash
# Verificar variáveis de ambiente
docker-compose config | grep OPENAI_API_KEY

# Verificar configuração
cat config/litellm-config.yaml

# Verificar logs
docker-compose logs litellm
```

### Problema: Porta já em uso

```bash
# Descobrir o que está usando a porta
lsof -i :3000  # exemplo para porta 3000

# Parar o processo ou mudar porta no docker-compose.yml
```

### Problema: PostgreSQL não inicializa

```bash
# Remover volumes e recriar
docker-compose down -v
docker-compose up -d

# Verificar logs
docker-compose logs postgres
```

---

## 📦 Comandos Úteis

### Gerenciamento

```bash
# Iniciar stack
docker-compose up -d

# Parar stack
docker-compose down

# Parar e remover volumes (CUIDADO: perde dados)
docker-compose down -v

# Ver logs em tempo real
docker-compose logs -f

# Logs de um serviço específico
docker-compose logs -f flowise

# Reiniciar tudo
docker-compose restart

# Rebuild de imagens
docker-compose build --no-cache
```

### Manutenção

```bash
# Limpar containers parados
docker container prune

# Limpar imagens não usadas
docker image prune -a

# Limpar volumes não usados (CUIDADO)
docker volume prune

# Ver uso de disco
docker system df
```

### Backup

```bash
# Backup PostgreSQL
docker-compose exec postgrespostgres pg_dump -U appgear appgear > backup.sql

# Backup volumes (exemplo)
docker run --rm -v appgear_postgres_data:/source -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup.tar.gz -C /source .
```

---

## 🎯 Próximos Passos

Após validar que tudo funciona:

### 1. Criar Primeiro Workflow (Flowise)
- Acessar http://localhost:3000
- Criar chatbot simples
- Testar integração com LiteLLM

### 2. Criar Automação (n8n)
- Acessar http://localhost:5678
- Criar workflow de exemplo
- Integrar com Flowise

### 3. Progressão para Stack Standard
- Adicionar Prometheus, Grafana, Loki
- Adicionar Vault
- Adicionar Directus, Appsmith, Metabase
- Ver: [Fase 2 do Implementation Plan]

---

## ⚠️ Avisos Importantes

### Segurança

> **NÃO USE EM PRODUÇÃO!** Este é um ambiente de desenvolvimento.

- ❌ Senhas são defaults (troque antes de usar)
- ❌ Sem HTTPS real (certificados auto-assinados)
- ❌ Sem autenticação forte
- ❌ Logs verbosos
- ❌ Traefik dashboard exposto

### Recursos

- Mínimo: 4GB RAM, 2 CPU
- Recomendado: 8GB RAM, 4 CPU
- Espaço disco: ~10GB para volumes

### Dados

- Todos os dados ficam em volumes Docker
- `docker-compose down -v` **APAGA TUDO**
- Fazer backups regularmente durante desenvolvimento

---

## 📚 Documentação Adicional

- [Contrato de Arquitetura v0](docs/architecture/contract/contract-v0.md)
- [Implementation Plan](implementation_plan.md)
- [Scripts de Validação](scripts/)
- [Análise Completa da Plataforma](analise_completa_appgear.md)

---

## 🐛 Problemas Conhecidos

- [ ] Coraza WAF não incluído no minimal (será adicionado no Standard)
- [ ] Istio não disponível em Docker (apenas Topologia B/Kubernetes)
- [ ] vClusters não disponíveis (apenas Topologia B)
- [ ] KEDA Scale-to-Zero não aplicável ao Docker Compose

---

## 📞 Suporte

- Issues: Documentar problemas encontrados
- Validação: Executar `./scripts/validate-topology-a.sh`
- Logs: `docker-compose logs -f`

---

**Versão:** 1.0 - Topologia A Minimal  
**Data:** 27 de novembro de 2025  
**Próxima Versão:** Topologia A Standard (15 componentes)
