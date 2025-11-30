# 🔒 Guia de Segurança - AppGear

**Última Atualização:** 29 de novembro de 2025

---

## 📋 Índice

- [Política de Segurança](#-política-de-segurança)
- [Versões Suportadas](#-versões-suportadas)
- [Reporte de Vulnerabilidades](#-reporte-de-vulnerabilidades)
- [Práticas de Segurança](#-práticas-de-segurança)
- [Configurações de Segurança](#-configurações-de-segurança)
- [Autenticação e Autorização](#-autenticação-e-autorização)
- [Segurança dos Dados](#-segurança-dos-dados)
- [Segurança de Infraestrutura](#-segurança-de-infraestrutura)
- [Conformidade](#-conformidade)

---

## 🛡️ Política de Segurança

A segurança é uma prioridade máxima no AppGear. Este documento descreve nossas práticas de segurança, como reportar vulnerabilidades e as medidas implementadas para proteger a plataforma e seus usuários.

### Princípios de Segurança

1. **Defesa em Profundidade**: Múltiplas camadas de proteção
2. **Princípio do Menor Privilégio**: Acesso mínimo necessário
3. **Segurança por Design**: Segurança integrada desde o início
4. **Transparência Responsável**: Comunicação clara sobre questões de segurança

---

## 🔖 Versões Suportadas

| Versão | Topologia | Suporte de Segurança |
|--------|-----------|---------------------|
| FASE 2 | Standard (K8s) | ✅ Suporte Ativo |
| FASE 2 | Minimal (Compose) | ✅ Suporte Ativo |
| FASE 1 | Legacy | ⚠️ Apenas Crítico |

> **Nota:** Recomendamos sempre utilizar as versões mais recentes disponíveis.

---

## 🚨 Reporte de Vulnerabilidades

### Como Reportar

Se você descobrir uma vulnerabilidade de segurança no AppGear, por favor, **NÃO** abra uma issue pública. Em vez disso:

1. **Envie um email para:** security@appgear.io
2. **Inclua no email:**
   - Descrição detalhada da vulnerabilidade
   - Passos para reproduzir o problema
   - Impacto potencial
   - Versão afetada (Minimal/Standard)
   - Sugestões de mitigação (se houver)

### O que Esperar

- ✅ **Confirmação de recebimento:** Dentro de 24 horas
- 🔍 **Análise inicial:** Dentro de 72 horas
- 📋 **Plano de ação:** Dentro de 7 dias
- 🔧 **Resolução:** Conforme severidade (crítico: 7-14 dias)

### Política de Divulgação Responsável

- Pedimos um período de **90 dias** antes de divulgação pública
- Você será creditado pela descoberta (se desejar)
- Manteremos você informado sobre o progresso da correção

---

## 🔐 Práticas de Segurança

### Para Desenvolvedores

#### 1. Gerenciamento de Secrets

**❌ NUNCA faça isso:**
```bash
# NÃO commitar secrets no repositório
export API_KEY="sk-1234567890abcdef"
git add .env
```

**✅ SEMPRE faça isso:**
```bash
# Use o diretório .secrets/ (já está no .gitignore)
cp .env.example .secrets/.env
# Edite .secrets/.env com suas credenciais
```

#### 2. Estrutura de Secrets

```
.secrets/
├── .env                    # Credenciais principais
├── api-keys/              # Chaves de API
│   ├── groq.key
│   └── openai.key
└── certificates/          # Certificados SSL/TLS
    ├── tls.crt
    └── tls.key
```

#### 3. Validação de Inputs

```python
# Sempre valide e sanitize inputs do usuário
from pydantic import BaseModel, validator

class WorkflowInput(BaseModel):
    name: str
    
    @validator('name')
    def sanitize_name(cls, v):
        # Remove caracteres perigosos
        return re.sub(r'[^\w\s-]', '', v)
```

#### 4. Logs Seguros

```python
# ❌ NÃO logue informações sensíveis
logger.info(f"API Key: {api_key}")

# ✅ Mascare dados sensíveis
logger.info(f"API Key: {api_key[:8]}***")
```

---

## ⚙️ Configurações de Segurança

### Topologia Minimal (Docker Compose)

#### Variáveis de Ambiente Obrigatórias

```bash
# .secrets/.env

# PostgreSQL
POSTGRES_PASSWORD=<senha-forte-min-16-chars>
POSTGRES_DB=appgear_db
POSTGRES_USER=appgear_user

# Redis
REDIS_PASSWORD=<senha-forte-min-16-chars>

# Flowise
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=<senha-forte-min-16-chars>

# n8n
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<senha-forte-min-16-chars>

# LiteLLM
LITELLM_MASTER_KEY=<chave-mestra-min-32-chars>
```

#### Fortalecimento de Senhas

```bash
# Gere senhas fortes usando:
openssl rand -base64 32

# Para chaves mestras:
openssl rand -hex 48
```

### Topologia Standard (Kubernetes)

#### Secrets do Kubernetes

```bash
# Criar secrets
kubectl create secret generic postgres-secret \
  --from-literal=password=$(openssl rand -base64 32) \
  -n appgear

kubectl create secret generic redis-secret \
  --from-literal=password=$(openssl rand -base64 32) \
  -n appgear

kubectl create secret generic litellm-secret \
  --from-literal=master-key=$(openssl rand -hex 48) \
  -n appgear
```

#### RBAC (Role-Based Access Control)

```yaml
# Exemplo: gitops/base/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: appgear-reader
  namespace: appgear
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list"]
```

#### Network Policies

```yaml
# Isole os serviços internos
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-isolation
  namespace: appgear
spec:
  podSelector:
    matchLabels:
      app: postgresql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: flowise
    - podSelector:
        matchLabels:
          app: n8n
```

---

## 🔑 Autenticação e Autorização

### Flowise

```bash
# Habilitar autenticação
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=<senha-forte>
FLOWISE_SECRETKEY_OVERWRITE=<chave-secreta-32-chars>
```

### n8n

```bash
# Basic Auth (desenvolvimento)
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<senha-forte>

# LDAP/OAuth (produção - Fase 3+)
N8N_AUTH_MODE=ldap
```

### LiteLLM

```bash
# Master Key para administração
LITELLM_MASTER_KEY=sk-<chave-mestra>

# API Keys por usuário/serviço
curl -X POST http://localhost:4000/key/generate \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -d '{"team_id": "team1", "max_budget": 100}'
```

---

## 💾 Segurança dos Dados

### Criptografia em Repouso

#### PostgreSQL
```sql
-- Habilitar criptografia de dados sensíveis
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Exemplo: criptografar API keys
CREATE TABLE api_credentials (
    id SERIAL PRIMARY KEY,
    service VARCHAR(100),
    encrypted_key BYTEA
);

INSERT INTO api_credentials (service, encrypted_key)
VALUES ('openai', pgp_sym_encrypt('sk-actual-key', 'encryption-password'));
```

### Criptografia em Trânsito

#### TLS/SSL (Fase 3+)

```yaml
# Ingress com TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: appgear-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - appgear.io
    secretName: appgear-tls
```

### Backup Seguro

```bash
# Backup criptografado do PostgreSQL
./scripts/backup/postgres-backup.sh --encrypt

# Armazenamento:
# - Local: .secrets/backups/ (criptografado)
# - Cloud: S3 com criptografia server-side (Fase 4)
```

### Retenção de Dados

| Tipo de Dado | Retenção | Backup |
|--------------|----------|--------|
| Workflows | Permanente | Diário |
| Logs de Execução | 90 dias | Semanal |
| Métricas | 30 dias | Mensal |
| Logs de Auditoria | 1 ano | Diário |

---

## 🏗️ Segurança de Infraestrutura

### Hardening do Docker

```dockerfile
# Use usuários não-root
FROM node:18-alpine
RUN addgroup -g 1001 appgear && \
    adduser -D -u 1001 -G appgear appgear
USER appgear

# Scan de vulnerabilidades
RUN apk add --no-cache dumb-init
```

```bash
# Scan de imagens
docker scan appgear/flowise:latest
trivy image appgear/flowise:latest
```

### Hardening do Kubernetes

```bash
# 1. Pod Security Standards
kubectl label namespace appgear \
  pod-security.kubernetes.io/enforce=restricted

# 2. Limites de recursos
kubectl set resources deployment flowise \
  --limits=cpu=2,memory=4Gi \
  --requests=cpu=500m,memory=1Gi \
  -n appgear

# 3. Security Context
```

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
```

### Firewall e Rede

#### Minimal (iptables)
```bash
# Permitir apenas conexões locais
sudo iptables -A INPUT -p tcp --dport 3000 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3000 -j DROP
```

#### Standard (Network Policies)
```yaml
# Já implementado em gitops/base/
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
# ... (ver acima)
```

---

## 📊 Monitoramento de Segurança

### Logs de Auditoria

```bash
# Kubernetes Audit Logs
kubectl get events -n appgear --sort-by='.lastTimestamp'

# Application Logs
kubectl logs -f deployment/flowise -n appgear | grep "authentication\|authorization\|error"
```

### Alertas (Prometheus)

```yaml
# gitops/observability/prometheus-alerts.yaml
groups:
- name: security
  rules:
  - alert: TooManyFailedLogins
    expr: rate(failed_login_attempts[5m]) > 10
    annotations:
      summary: "Possível ataque de força bruta"
      
  - alert: UnauthorizedAccess
    expr: rate(http_requests_total{code="403"}[5m]) > 5
    annotations:
      summary: "Múltiplas tentativas de acesso não autorizado"
```

### Auditoria Regular

- 🔍 **Semanal:** Review de logs de acesso
- 📋 **Mensal:** Auditoria de permissões e secrets
- 🔐 **Trimestral:** Rotação de credenciais
- 🛡️ **Anual:** Penetration testing (Fase 3+)

---

## ✅ Checklist de Segurança

### Antes do Deployment

- [ ] Todas as senhas são fortes (min. 16 caracteres)
- [ ] Secrets não estão no código fonte
- [ ] Variáveis de ambiente configuradas
- [ ] RBAC configurado (K8s)
- [ ] Network policies aplicadas (K8s)
- [ ] Images escaneadas por vulnerabilidades
- [ ] Backups configurados
- [ ] Monitoramento ativo

### Manutenção Regular

- [ ] Atualizar dependências mensalmente
- [ ] Rodar scans de segurança semanalmente
- [ ] Revisar logs de auditoria semanalmente
- [ ] Rotacionar secrets trimestralmente
- [ ] Testar backups mensalmente
- [ ] Revisar acessos mensalmente

---

## 📚 Conformidade

### Padrões Seguidos

- ✅ **OWASP Top 10**: Proteção contra vulnerabilidades web comuns
- ✅ **CIS Kubernetes Benchmark**: Para topologia Standard
- ✅ **Docker Bench Security**: Para topologia Minimal
- ⏳ **SOC 2** (Planejado para Fase 4)
- ⏳ **ISO 27001** (Planejado para Fase 4)

### LGPD (Lei Geral de Proteção de Dados)

- 🔐 Criptografia de dados pessoais
- 🗑️ Direito ao esquecimento (hard delete)
- 📋 Registro de processamento de dados
- 🔒 Controle de acesso granular
- 📊 Auditoria de operações

---

## 🆘 Suporte de Segurança

### Contatos

- **Vulnerabilidades:** security@appgear.io
- **Questões Gerais:** contato@appgear.io
- **Emergências:** security-emergency@appgear.io (24/7 - Fase 3+)

### Recursos Adicionais

- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)

---

## 🔄 Atualizações deste Documento

Este documento é revisado e atualizado regularmente conforme:
- Novas vulnerabilidades são descobertas
- Novos recursos de segurança são implementados
- Melhores práticas da indústria evoluem
- Feedback da comunidade é recebido

**Histórico de Versões:**
- v1.0 (29/11/2025) - Versão inicial (FASE 2)

---

**Desenvolvido com 🔒 e ❤️ - Segurança é nossa prioridade**

