# M04 Bancos de Dados - FASE 1 Addendum

**Módulo:** M04 - Bancos de Dados (PostgreSQL, Redis, Qdrant, Redpanda)  
**Documentação Completa:** [module-04-v0.3.md](module-04-v0.3.md)  
**Este Addendum:** Instruções específicas para **FASE 1 - Topologia A Minimal** (Docker Compose)

---

## 🎯 O que está implementado na FASE 1

| Componente | Status | Versão | Uso |
|------------|--------|--------|-----|
| **PostgreSQL** | ✅ Implementado | 15-alpine | Banco principal |
| **Redis** | ✅ Implementado | 7-alpine | Cache e sessions |
| **Qdrant** | ❌ FASE 2 | - | Banco vetorial (RAG) |
| **Redpanda** | ❌ FASE 2+ | - | Event streaming |

---

## 📁 Configuração

### docker-compose.yml

#### PostgreSQL
```yaml
postgres:
  image: postgres:15-alpine
  container_name: appgear-postgres
  environment:
    POSTGRES_USER: ${POSTGRES_USER}
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    POSTGRES_DB: ${POSTGRES_DB}
  ports:
    - "5432:5432"
  volumes:
    - postgres_data:/var/lib/postgresql/data
    - ./config/init-postgres.sql:/docker-entrypoint-initdb.d/init.sql
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
    interval: 10s
    timeout: 5s
    retries: 5
```

#### Redis
```yaml
redis:
  image: redis:7-alpine
  container_name: appgear-redis
  command: redis-server --requirepass ${REDIS_PASSWORD}
  ports:
    - "6379:6379"
  volumes:
    - redis_data:/data
  healthcheck:
    test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
    interval: 10s
    timeout: 3s
    retries: 5
```

### init-postgres.sql
```sql
-- Criar schemas para multi-tenancy
CREATE SCHEMA IF NOT EXISTS apps;
CREATE SCHEMA IF NOT EXISTS flowise;
CREATE SCHEMA IF NOT EXISTS n8n;
CREATE SCHEMA IF NOT EXISTS litellm;

-- Criar estrutura de multi-tenancy
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES public.tenants(id),
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tenant e workspace padrão
INSERT INTO public.tenants (id, name) 
VALUES ('00000000-0000-0000-0000-000000000001', 'default')
ON CONFLICT DO NOTHING;

INSERT INTO public.workspaces (id, tenant_id, name)
VALUES ('00000000-0000-0000-0000-000000000001', 
        '00000000-0000-0000-0000-000000000001', 
        'development')
ON CONFLICT DO NOTHING;
```

---

## 🚀 Comandos Práticos

### PostgreSQL

#### Conectar via psql
```bash
# Via docker exec
sudo docker exec -it appgear-postgres psql -U appgear -d appgear

# Comandos úteis dentro do psql:
\l              # Listar databases
\dn             # Listar schemas
\dt schema.*    # Listar tabelas de um schema
\q              # Sair
```

#### Consultas comuns
```bash
# Listar schemas
sudo docker exec appgear-postgres psql -U appgear -d appgear -c "\dn"

# Ver tabelas do schema flowise
sudo docker exec appgear-postgres psql -U appgear -d appgear -c "\dt flowise.*"

# Ver tenant e workspaces
sudo docker exec appgear-postgres psql -U appgear -d appgear -c \
  "SELECT * FROM public.tenants;"

sudo docker exec appgear-postgres psql -U appgear -d appgear -c \
  "SELECT * FROM public.workspaces;"
```

#### Backup e Restore
```bash
# Backup completo
sudo docker exec appgear-postgres pg_dump -U appgear appgear > backup.sql

# Backup de schema específico
sudo docker exec appgear-postgres pg_dump -U appgear -n flowise appgear > flowise_backup.sql

# Restore
cat backup.sql | sudo docker exec -i appgear-postgres psql -U appgear -d appgear
```

#### Limpar dados de teste
```bash
# Limpar schema flowise (se Flowise com problemas)
sudo docker exec appgear-postgres psql -U appgear -d appgear -c \
  "DROP SCHEMA IF EXISTS flowise CASCADE; \
   CREATE SCHEMA flowise; \
   GRANT ALL ON SCHEMA flowise TO appgear;"
```

### Redis

#### Conectar via redis-cli
```bash
# Via docker exec
sudo docker exec -it appgear-redis redis-cli

# Autenticar
AUTH redis_secure_2025_R3d1s!

# Comandos úteis:
PING                    # Test connection
KEYS *                  # Listar todas as keys (cuidado em prod!)
INFO                    # Status do Redis
DBSIZEexport                  # Número de keys
FLUSHDB                 # Limpar database atual (dev apenas!)
```

#### Comandos externos
```bash
# Ver info do servidor
sudo docker exec appgear-redis redis-cli -a redis_secure_2025_R3d1s! INFO

# Ver todas as keys
sudo docker exec appgear-redis redis-cli -a redis_secure_2025_R3d1s! KEYS '*'

# Verificar uso de memória
sudo docker exec appgear-redis redis-cli -a redis_secure_2025_R3d1s! INFO memory

# Limpar cache (dev apenas!)
sudo docker exec appgear-redis redis-cli -a redis_secure_2025_R3d1s! FLUSHDB
```

---

## 🔧 Troubleshooting

### PostgreSQL não inicia

```bash
# Ver logs
sudo docker logs appgear-postgres --tail 50

# Verificar permissões do volume
sudo ls -la volumes/postgres_data/

# Remover e recriar (PERDE DADOS!)
sudo docker-compose down
sudo docker volume rm minimal_postgres_data
sudo docker-compose up -d postgres
```

### Erro "password authentication failed"

```bash
# Verificar .env
cat .env | grep POSTGRES

# Deve ter:
# POSTGRES_USER=appgear
# POSTGRES_PASSWORD=appgear_secure_2025_P@ssw0rd
# POSTGRES_DB=appgear

# Testar conexão
sudo docker exec appgear-postgres psql -U appgear -d appgear -c "SELECT 1;"
```

### Redis "NOAUTH Authentication required"

```bash
# Sempre usar -a com senha
sudo docker exec appgear-redis redis-cli -a redis_secure_2025_R3d1s! PING

# Ou conectar e autenticar:
sudo docker exec -it appgear-redis redis-cli
AUTH redis_secure_2025_R3d1s!
PING
```

### PostgreSQL muito lento

```bash
# Ver conexões ativas
sudo docker exec appgear-postgres psql -U appgear -d appgear -c \
  "SELECT count(*) FROM pg_stat_activity;"

# Ver queries lentas (> 1s)
sudo docker exec appgear-postgres psql -U appgear -d appgear -c \
  "SELECT pid, now() - query_start as duration, query 
   FROM pg_stat_activity 
   WHERE state = 'active' 
   AND now() - query_start > interval '1 second';"

# Matar conexão específica
sudo docker exec appgear-postgres psql -U appgear -d appgear -c \
  "SELECT pg_terminate_backend(PID);"
```

---

## 📊 Uso de Schemas por Serviço

| Serviço | Schema | Propósito |
|---------|--------|-----------|
| **Flowise** | `flowise` | Workflows, chatflows, credenciais |
| **n8n** | Padrão (`public`) | Workflows, execuções, credenciais |
| **LiteLLM** | Padrão (`public`) | Cache, logs, modelos |
| **Apps** | `apps` | Futuros apps (Directus, etc) |
| **Multi-tenancy** | `public` | Tenants, workspaces |

---

## 🎯 Preparação para FASE 2

### Qdrant (Banco Vetorial)
```yaml
qdrant:
  image: qdrant/qdrant:latest
  ports:
    - "6333:6333"    # HTTP API
    - "6334:6334"    # gRPC
  volumes:
    - qdrant_data:/qdrant/storage
  environment:
    QDRANT__SERVICE__GRPC_PORT: 6334
```

**Uso:** RAG, embeddings, semantic search

### Redpanda (Event Streaming)
```yaml
redpanda:
  image: vectorized/redpanda:latest
  command:
    - redpanda start
    - --smp 1
    - --overprovisioned
  ports:
    - "9092:9092"    # Kafka API
    - "8081:8081"    # Schema Registry
  volumes:
    - redpanda_data:/var/lib/redpanda/data
```

**Uso:** Event streaming, message queue

---

## 🔒 Segurança - IMPORTANTE

### Produção (FASE 2+)
- [ ] Trocar TODAS as senhas
- [ ] Usar secrets manager (Vault)
- [ ] Habilitar SSL/TLS no PostgreSQL
- [ ] Configurar network policies
- [ ] Backup automatizado
- [ ] Disaster recovery

### Desenvolvimento (FASE 1)
- ✅ Senhas em `.env` (protegido por .gitignore)
- ✅ Volumes locais
- ⚠️ Sem backup automatizado
- ⚠️ Sem SSL/TLS

---

## 📚 Ver Também

- [module-04-v0.3.md](module-04-v0.3.md) - Documentação completa
- [module-02-phase1-addendum.md](module-02-phase1-addendum.md) - Cadeia de borda
- [module-08-phase1-addendum.md](module-08-phase1-addendum.md) - Apps Core
- [../implementation-status.md](../implementation-status.md) - Status global

---

**Versão:** 1.0  
**Data:** 27 de novembro de 2025  
**Válido para:** FASE 1 - Topologia A Minimal
