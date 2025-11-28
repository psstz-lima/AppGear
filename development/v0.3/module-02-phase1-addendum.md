# M02 Cadeia de Borda - FASE 1 Addendum

**Módulo:** M02 - Cadeia de Borda (Traefik, Coraza, Kong, Istio)  
**Documentação Completa:** [module-02-v0.3.md](module-02-v0.3.md)  
**Este Addendum:** Instruções específicas para **FASE 1 - Topologia A Minimal** (Docker Compose)

---

## ⚠️ Importante

A documentação principal (module-02-v0.3.md) descreve a cadeia **COMPLETA**:  
**Traefik → Coraza (WAF) → Kong → Istio**

Na FASE 1, implementamos apenas:  
**Traefik → Kong**

---

## 🎯 O que está implementado na FASE 1

| Componente | Status | Versão | Função |
|------------|--------|--------|--------|
| **Traefik** | ✅ Implementado | 2.10 | Reverse proxy / Ingress |
| **Kong** | ✅ Implementado | 3.4 | API Gateway (DB-less) |
| **Coraza WAF** | ❌ FASE 2 | - | Planejado |
| **Istio Service Mesh** | ❌ FASE 3 | - | Kubernetes apenas |

---

## 📁 Configuração

### docker-compose.yml

#### Traefik
```yaml
traefik:
  image: traefik:v2.10
  container_name: appgear-traefik
  ports:
    - "80:80"       # HTTP
    - "443:443"     # HTTPS
    - "8080:8080"   # Dashboard
  command:
    - "--api.insecure=true"
    - "--providers.docker=true"
    - "--providers.docker.exposedbydefault=false"
    - "--entrypoints.web.address=:80"
    - "--entrypoints.websecure.address=:443"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
```

#### Kong
```yaml
kong:
  image: kong:3.4
  container_name: appgear-kong
  environment:
    KONG_DATABASE: "off"
    KONG_DECLARATIVE_CONFIG: /kong/declarative/kong.yml
    KONG_PROXY_ACCESS_LOG: /dev/stdout
    KONG_ADMIN_ACCESS_LOG: /dev/stdout
    KONG_PROXY_ERROR_LOG: /dev/stderr
    KONG_ADMIN_ERROR_LOG: /dev/stderr
    KONG_ADMIN_LISTEN: "0.0.0.0:8001"
  ports:
    - "8000:8000"  # Proxy
    - "8001:8001"  # Admin API
  volumes:
    - ./config/kong.yml:/kong/declarative/kong.yml
```

### kong.yml
```yaml
_format_version: "3.0"

services:
  - name: litellm-service
    url: http://litellm:4000
    routes:
      - name: litellm-route
        paths:
          - /litellm

  - name: flowise-service
    url: http://appgear-flowise:3000
    routes:
      - name: flowise-route
        paths:
          - /flowise

  - name: n8n-service
    url: http://n8n:5678
    routes:
      - name: n8n-route
        paths:
          - /n8n
```

---

## 🚀 Comandos Práticos

### Gerenciar Traefik

```bash
# Ver dashboard
xdg-open http://localhost:8080  # Linux
open http://localhost:8080       # macOS

# Ver logs
sudo docker logs appgear-traefik -f

# Reiniciar
sudo docker-compose restart traefik

# Ver rotas descobertas
curl http://localhost:8080/api/http/routers
```

### Gerenciar Kong

```bash
# Ver configuração
curl http://localhost:8001

# Listar serviços
curl http://localhost:8001/services

# Listar rotas
curl http://localhost:8001/routes

# Health check
curl http://localhost:8001/status

# Recarregar configuração (DB-less)
sudo docker-compose restart kong
```

### Testar Roteamento

```bash
# Via Traefik (porta 80)
curl http://localhost/flowise
curl http://localhost/n8n
curl http://localhost/litellm

# Via Kong direto (porta 8000)
curl http://localhost:8000/flowise
curl http://localhost:8000/n8n
curl http://localhost:8000/litellm
```

---

## 🔧 Troubleshooting

### Porta 80 em uso

```bash
# Verificar processo
sudo ss -tlnp | grep :80

# Parar Apache2
sudo systemctl stop apache2
sudo systemctl disable apache2

# Ou matar processo
sudo fuser -k 80/tcp
```

### Traefik não encontra serviços

```bash
# Verificar labels dos containers
sudo docker inspect appgear-flowise | grep -A 5 traefik

# Deve ter:
# "traefik.enable": "true"
# "traefik.http.routers.flowise.rule": "PathPrefix(`/flowise`)"

# Verificar rede
sudo docker network inspect appgear-net-core
```

### Kong não roteia corretamente

```bash
# Verificar se kong.yml está montado
sudo docker exec appgear-kong cat /kong/declarative/kong.yml

# Ver logs do Kong
sudo docker logs appgear-kong --tail 50

# Testar conectividade interna
sudo docker exec appgear-kong curl http://n8n:5678
sudo docker exec appgear-kong curl http://appgear-flowise:3000
```

---

## 📊 Arquitetura Atual vs Planejada

### FASE 1 (Atual)
```
Cliente
   │
   ▼
Traefik (porta 80/443)
   │
   ▼
Kong (porta 8000)
   │
   ├─► Flowise (3000)
   ├─► n8n (5678)
   └─► LiteLLM (4000)
```

### FASE 2 (Planejado)
```
Cliente
   │
   ▼
Traefik (TLS termination)
   │
   ▼
Coraza WAF
   │
   ▼
Kong (API Gateway)
   │
   ├─► Flowise
   ├─► n8n
   ├─► Directus
   └─► Appsmith
```

### FASE 3 (Futuro - Kubernetes)
```
Cliente
   │
   ▼
Traefik (TLS passthrough)
   │
   ▼
Coraza WAF
   │
   ▼
Kong Ingress Controller
   │
   ▼
Istio IngressGateway
   │
   ▼
Service Mesh (mTLS STRICT)
   │
   └─► Serviços
```

---

## 🎯 Limitações da FASE 1

O que **NÃO** temos (vs documentação completa):

### Segurança
- ❌ WAF (Coraza) - Toda requisição vai direto
- ❌ mTLS - Sem criptografia entre serviços
- ❌ Rate limiting avançado - Kong basic apenas
- ❌ CSRF protection - Não implementado

### Escalabilidade
- ❌ Horizontal Pod Autoscaling - Docker Compose não escala
- ❌ Health probes complexos - Básicos apenas
- ❌ Circuit breakers - Sem Istio

### Observabilidade
- ❌ Distributed tracing - Sem Jaeger/Zipkin
- ❌ Métricas avançadas - Sem Prometheus
- ❌ Service graph - Sem Kiali

**⚠️ Para produção, use FASE 2+**

---

## 📚 Ver Também

- [module-02-v0.3.md](module-02-v0.3.md) - Documentação completa
- [module-04-phase1-addendum.md](module-04-phase1-addendum.md) - Bancos de dados
- [module-08-phase1-addendum.md](module-08-phase1-addendum.md) - Apps Core
- [../implementation-status.md](../implementation-status.md) - Status global

---

**Versão:** 1.0  
**Data:** 27 de novembro de 2025  
**Válido para:** FASE 1 - Topologia A Minimal
