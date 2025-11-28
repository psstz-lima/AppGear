# M08 Apps Core - FASE 1 Addendum

**Módulo:** M08 - Apps Core (LiteLLM, Flowise, n8n, Directus, Appsmith, Metabase)  
**Documentação Completa:** [module-08-v0.3.md](module-08-v0.3.md)  
**Este Addendum:** Instruções específicas para **FASE 1 - Topologia A Minimal** (Docker Compose)

---

## ⚠️ Importante

A documentação principal (module-08-v0.3.md) descreve a arquitetura **COMPLETA** com Kubernetes + Istio.

Este addendum fornece comandos e configurações para a **implementação simplificada da FASE 1** usando Docker Compose.

---

## 🎯 O que está implementado na FASE 1

| Componente | Status | Versão | Observações |
|------------|--------|--------|-------------|
| **LiteLLM** | ✅ Implementado | main-latest | Gateway IA unificado |
| **Flowise** | ✅ Implementado | 1.4.7 | Workflows IA (PostgreSQL) |
| **n8n** | ✅ Implementado | latest | Automação (PostgreSQL) |
| **Directus** | ❌ FASE 2 | - | Planejado |
| **Appsmith** | ❌ FASE 2 | - | Planejado |
| **Metabase** | ❌ FASE 2 | - | Planejado |

---

## 📁 Arquivos de Configuração

### Localização
```
deployments/topology-a/minimal/
├── docker-compose.yml         # Definição dos serviços
├── .env                        # Variáveis de ambiente
├── .env.example               # Template de configuração
└── config/
    ├── kong.yml               # Kong routes
    ├── litellm-config.yaml    # LiteLLM models
    └── init-postgres.sql      # DB initialization
```

### Configuração Atual (docker-compose.yml)

#### LiteLLM
```yaml
litellm:
  image: ghcr.io/berriai/litellm:main-latest
  container_name: appgear-litellm
  ports:
    - "4000:4000"
  environment:
    LITELLM_MASTER_KEY: ${LITELLM_MASTER_KEY}
    DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
  volumes:
    - ./config/litellm-config.yaml:/app/config.yaml
  command: ["--config", "/app/config.yaml"]
```

#### n8n
```yaml
n8n:
  image: n8nio/n8n:latest
  container_name: appgear-n8n
  ports:
    - "5678:5678"
  environment:
    DB_TYPE: postgresdb
    DB_POSTGRESDB_HOST: postgres
    DB_POSTGRESDB_PORT: 5432
    DB_POSTGRESDB_DATABASE: ${POSTGRES_DB}
    DB_POSTGRESDB_USER: ${POSTGRES_USER}
    DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
    N8N_USER: ${N8N_USER}
    N8N_PASSWORD: ${N8N_PASSWORD}
```

#### Flowise (Criado Manualmente)
> ⚠️ **Importante:** Devido a bug no Flowise latest, usamos v1.4.7 via `docker run`

Comando:
```bash
sudo docker run -d \
  --name appgear-flowise \
  --network appgear-net-core \
  --restart unless-stopped \
  -p 3000:3000 \
  -e DATABASE_TYPE=postgres \
  -e DATABASE_HOST=postgres \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USER=appgear \
  -e DATABASE_PASSWORD=appgear_secure_2025_P@ssw0rd \
  -e DATABASE_NAME=appgear \
  -e DATABASE_SCHEMA=flowise \
  -e FLOWISE_USERNAME=admin \
  -e FLOWISE_PASSWORD=flowise_secure_2025_Fl0w! \
  -e APIKEY_PATH=/root/.flowise \
  -e SECRETKEY_PATH=/root/.flowise \
  -e LOG_LEVEL=info \
  -v flowise_data:/root/.flowise \
  --label traefik.enable=true \
  --label "traefik.http.routers.flowise.rule=PathPrefix(\`/flowise\`)" \
  --label traefik.http.services.flowise.loadbalancer.server.port=3000 \
  flowiseai/flowise:1.4.7 \
  flowise start
```

---

## 🚀 Comandos Práticos - FASE 1

### Iniciar Serviços

```bash
# Navegar para deployment
cd ~/AppGear/deployments/topology-a/minimal

# Iniciar serviços base
sudo docker-compose up -d traefik kong postgres redis litellm n8n

# Iniciar Flowise manualmente (v1.4.7)
# Use comando acima na seção "Flowise"

# Verificar status
sudo docker-compose ps
sudo docker ps | grep flowise
```

### Parar Serviços

```bash
# Parar serviços do compose
sudo docker-compose down

# Parar Flowise manual
sudo docker stop appgear-flowise
sudo docker rm appgear-flowise
```

### Ver Logs

```bash
# LiteLLM
sudo docker logs appgear-litellm --tail 50 -f

# n8n
sudo docker logs appgear-n8n --tail 50 -f

# Flowise
sudo docker logs appgear-flowise --tail 50 -f

# Todos (compose)
sudo docker-compose logs -f
```

### Reiniciar Serviço Específico

```bash
# n8n
sudo docker-compose restart n8n

# LiteLLM
sudo docker-compose restart litellm

# Flowise (parar e recriar)
sudo docker stop appgear-flowise
sudo docker rm appgear-flowise
# Execute comando de criação novamente
```

---

## 🔧 Troubleshooting

### LiteLLM mostrando "unhealthy"

**Causa:** Healthcheck retorna 401 (requer auth)  
**Solução:** Isso é normal!

```bash
# Verificar se está funcional
sudo docker logs appgear-litellm --tail 20

# Deve mostrar: "Uvicorn running on http://0.0.0.0:4000"

# Testar com auth
curl -H "Authorization: Bearer sk-appgear-master-key-2025-LiteL1M!" \
     http://localhost:4000/health
```

### Flowise crashando

**Causa:** Versão latest tem bug de migração PostgreSQL

**Solução:** Usar v1.4.7

```bash
# Limpar
sudo docker stop appgear-flowise
sudo docker rm appgear-flowise

# Limpar schema
sudo docker exec appgear-postgres psql -U appgear -c \
  "DROP SCHEMA IF EXISTS flowise CASCADE; CREATE SCHEMA flowise; GRANT ALL ON SCHEMA flowise TO appgear;"

# Recriar com v1.4.7 (comando completo na seção Flowise acima)
```

### n8n "Database is not ready"

**Causa:** PostgreSQL ainda não iniciado completamente

**Solução:**
```bash
# Aguardar PostgreSQL estar healthy
sudo docker-compose ps postgres

# Deve mostrar: "Up (healthy)"

# Reiniciar n8n
sudo docker-compose restart n8n

# Aguardar ~30 segundos e testar
curl http://localhost:5678
```

---

## 🌐 Acessar Interfaces

### Flowise
- **URL:** http://localhost:3000
- **Usuário:** admin
- **Senha:** flowise_secure_2025_Fl0w!

### n8n
- **URL:** http://localhost:5678
- **Usuário:** eu.plima@outlook.com.br (ou conforme .env)
- **Senha:** n8n_secure_2025_N8n! (ou conforme .env)

### LiteLLM API
- **URL:** http://localhost:4000
- **Auth:** Bearer sk-appgear-master-key-2025-LiteL1M!

**Exemplo de uso:**
```bash
curl -X POST http://localhost:4000/chat/completions \
  -H "Authorization: Bearer sk-appgear-master-key-2025-LiteL1M!" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## 📊 Diferenças vs Documentação Principal

| Aspecto | Documentação v0.3 | FASE 1 Implementada |
|---------|------------------|---------------------|
| **Orquestração** | Kubernetes | Docker Compose |
| **Ingress** | Kong Ingress Controller | Traefik labels |
| **Auth** | Keycloak + SSO | Autenticação básica |
| **Secrets** | Kubernetes Secrets | Variáveis .env |
| **Service Mesh** | Istio (mTLS STRICT) | Network bridge |
| **Flowise** | latest via Helm | 1.4.7 via docker run |

---

## 🎯 Preparação para FASE 2

Quando evoluir para FASE 2 (Standard), adicionar:

### Directus
```yaml
directus:
  image: directus/directus:latest
  ports:
    - "8055:8055"
  environment:
    KEY: ${DIRECTUS_KEY}
    SECRET: ${DIRECTUS_SECRET}
    DB_CLIENT: postgres
    DB_HOST: postgres
    # ... configs
```

### Appsmith
```yaml
appsmith:
  image: appsmith/appsmith-ce:latest
  ports:
    - "8081:80"
  volumes:
    - appsmith_data:/appsmith-stacks
```

### Metabase
```yaml
metabase:
  image: metabase/metabase:latest
  ports:
    - "3001:3000"
  environment:
    MB_DB_TYPE: postgres
    MB_DB_HOST: postgres
    # ... configs
```

---

## 📚 Ver Também

- **Documentação Completa:** [module-08-v0.3.md](module-08-v0.3.md)
- **Guia de Instalação:** [../../docs/guides/installation-guide-topology-a-minimal.md](../../docs/guides/installation-guide-topology-a-minimal.md)
- **Status de Implementação:** [../implementation-status.md](../implementation-status.md)

---

**Versão:** 1.0  
**Data:** 27 de novembro de 2025  
**Válido para:** FASE 1 - Topologia A Minimal
