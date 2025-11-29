# Plano de Implementação - FASE 2: Topologia A Standard

**Objetivo:** Migrar a stack AppGear de Docker Compose (Minimal) para Kubernetes (Standard), mantendo compatibilidade e adicionando camadas de segurança e observabilidade.

---

## 📋 Visão Geral

### Entregas Principais
1. Cluster K3s local funcional
2. Todos os 7 serviços rodando em Kubernetes
3. Coraza WAF implementado
4. Observabilidade básica (Prometheus + Grafana)
5. Scripts de gerenciamento adaptados

### Duração Estimada
- **Preparação:** 1 dia
- **Conversão:** 3-4 dias
- **Segurança/Obs:** 2 dias
- **Total:** ~1 semana

---

## 🎯 Fase 2.1: Preparação do Ambiente (Dia 1)

### Tarefas

#### 1. Instalar K3s
```bash
curl -sfL https://get.k3s.io | sh -
```
- Verificar instalação: `kubectl get nodes`
- Configurar kubeconfig: `~/.kube/config`

#### 2. Criar Estrutura de Diretórios
```
deployments/topology-a/standard/
├── k8s/
│   ├── 00-namespaces/
│   ├── 01-storage/
│   ├── 02-databases/
│   ├── 03-gateways/
│   ├── 04-ai/
│   └── 05-apps/
└── scripts/
    ├── setup-k3s.sh
    ├── deploy-all.sh
    └── cleanup.sh
```

#### 3. Preparar Secrets
- Migrar `.env` para Kubernetes Secrets
- Criar ConfigMaps para configurações

---

## 🔧 Fase 2.2: Conversão de Workloads (Dias 2-5)

### Ordem de Deploy (Dependências)

#### Dia 2: Infraestrutura Base

**PostgreSQL (StatefulSet)**
- Usar imagem `postgres:16-alpine`
- PersistentVolumeClaim 10Gi
- Serviço headless para StatefulSet
- Inicializar com schemas (Flowise, n8n)

**Redis (StatefulSet)**
- Usar imagem `redis:7-alpine`
- PVC 5Gi
- Configurar senha via Secret

**Testes:**
- Conectividade entre pods
- Persistência após restart

---

#### Dia 3: Gateways

**Traefik**
- Usar Helm Chart oficial
- Configurar como IngressController
- Habilitar dashboard (porta 8080)

**Kong**
- Usar Kong Ingress Controller
- Configurar admin API (porta 8001)
- Integrar com PostgreSQL

**Testes:**
- Ingress funcionando
- Roteamento HTTP básico

---

#### Dia 4: AI Gateway

**LiteLLM**
- Deployment com 2 réplicas
- ConfigMap para `litellm-config.yaml`
- Secret para API keys (Groq)
- Service ClusterIP

**Testes:**
- Inferência via Groq
- Load balancing entre réplicas

---

#### Dia 5: Aplicações

**Flowise**
- Deployment
- PVC para `/root/.flowise`
- Conectar ao PostgreSQL
- Ingress via Kong

**n8n**
- Deployment
- PVC para `/home/node/.n8n`
- Conectar ao PostgreSQL
- Ingress via Kong

**Testes E2E:**
- Chat no Flowise funcionando
- n8n acessível
- Integração LiteLLM → Flowise

---

## 🔒 Fase 2.3: Segurança (Dia 6)

### Coraza WAF

**Implementação:**
1. Deploy do Coraza como middleware do Traefik
2. Configurar regras OWASP Core Rule Set
3. Posicionar na cadeia: `Traefik → Coraza → Kong`

**Validação:**
- Testar bloqueio de SQL injection
- Testar bypass (deve falhar)

### Cert-Manager

**Implementação:**
1. Instalar via Helm
2. Configurar ClusterIssuer (Let's Encrypt staging)
3. Anotar Ingresses para auto-TLS

---

## 📊 Fase 2.4: Observabilidade (Dia 7)

### kube-prometheus-stack

**Deploy via Helm:**
```bash
helm install prometheus prometheus-community/kube-prometheus-stack
```

**Componentes:**
- Prometheus (métricas)
- Grafana (dashboards)
- AlertManager (alertas)

**Dashboards Iniciais:**
1. Overview do cluster
2. Uso de recursos por pod
3. Latência do LiteLLM

### Loki (Logs)

**Deploy:**
```bash
helm install loki grafana/loki-stack
```

**Integração:**
- Configurar como datasource no Grafana
- Criar queries básicas

---

## 🛠️ Fase 2.5: Scripts e Automação

### Scripts Necessários

#### `setup-k3s-a-standard.sh`
- Instala K3s
- Configura kubectl
- Instala Helm
- Cria namespaces

#### `deploy-stack-a-standard.sh`
- Aplica todos os YAMLs em ordem
- Aguarda cada serviço ficar ready
- Valida conectividade

#### `test-e2e-a-standard.sh`
- Testa inferência LiteLLM
- Testa Flowise API
- Testa n8n webhook

#### `cleanup-stack-a-standard.sh`
- Remove todos os recursos
- Mantém PVCs (opcional)

---

## ✅ Critérios de Aceitação

### Funcionalidade
- [ ] Todos os 7 serviços rodando
- [ ] Chat funcionando via Flowise
- [ ] Logs centralizados no Loki
- [ ] Métricas no Prometheus

### Segurança
- [ ] Coraza WAF bloqueando ataques
- [ ] Secrets não expostos em YAMLs
- [ ] TLS funcionando nos Ingresses

### Operação
- [ ] Scripts de deploy automatizados
- [ ] Testes E2E passando
- [ ] Documentação atualizada

---

## 🚨 Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| K3s consumir muito recurso | Alto | Limitar memória/CPU via cgroups |
| Conflito de portas com Minimal | Médio | Usar NodePort ranges diferentes |
| Dados perdidos na migração | Alto | Backup antes de iniciar |
| Coraza bloquear tráfego legítimo | Médio | Modo detecção primeiro |

---

## 📌 Próximos Passos Imediatos

1. Criar script `setup-k3s-a-standard.sh`
2. Criar estrutura de diretórios
3. Converter `docker-compose.yml` → K8s YAMLs (PostgreSQL primeiro)

---

**Versão:** 1.0  
**Data:** 28 de novembro de 2025  
**Autor:** Antigravity AI
