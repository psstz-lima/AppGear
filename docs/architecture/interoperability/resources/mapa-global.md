# Mapa global de interoperabilidade AppGear

> [!IMPORTANT]
> **MAPA GLOBAL CORE x SUÍTES – REFERÊNCIA OPERACIONAL**
>
> Este arquivo descreve, em alto nível, **quais componentes da AppGear existem no Stack Core e nas Suítes**, e **como eles se relacionam**.
> Ele complementa:
>
> * `docs/architecture/contract/contract-v0.md`
> * `docs/architecture/audit/audit-v0.md`
> * `docs/architecture/interoperability/interoperability-v0.md`

---

## 1. Visão geral

A AppGear é organizada em:

* **Stack Core** – serviços estruturais de rede, segurança, dados, IA, automação, observabilidade, FinOps e DR;
* **Suítes** – blocos funcionais de alto nível:

  * **Factory** – Integrações, CDEs, pipelines de dados e sistemas de negócio;
  * **Brain** – RAG, Corporate Brain, AI Workforce, AutoML;
  * **Operations** – IoT, Digital Twins, RPA, Edge/KubeEdge, orquestração operacional;
  * **Guardian** – Segurança avançada, Legal AI, Chaos, Governança da App Store.

Este mapa não é normativo por si só, mas **torna visível o “quem conversa com quem”**.

---

## 2. Stack Core

### 2.1. Portal e experiência de desenvolvimento

* **Backstage (Portal / Dev Experience)**

  * Função:

    * Portal unificado da AppGear (catálogo de serviços, templates, documentação, automações);
    * Ponto de entrada para:

      * criação de novos workspaces/tenants;
      * geração de pipelines AI-first (n8n/Flowise);
      * acesso a documentação e dashboards.
  * Comunica-se com:

    * Argo (via APIs GitOps);
    * n8n / BPMN;
    * serviços de autenticação (Keycloak);
    * serviços de descoberta e catálogo (internos).

---

### 2.2. Rede e borda

* **Traefik (Ingress de borda)**

  * Ponto de entrada HTTP(S)/TLS externo;
  * Terminação ou passthrough TLS (conforme contrato);
  * Faz roteamento inicial por host/prefixo.

* **Coraza (WAF)**

  * Proteção contra ataques web (OWASP, regras customizadas);
  * Inserido logo após Traefik na cadeia de borda.

* **Kong (API Gateway)**

  * Exposição de APIs públicas e internas;
  * Controle de rate-limit, autenticação, plugins de segurança;
  * Centraliza entradas HTTP que atingem a malha.

* **Istio (Service Mesh)**

  * Malha de serviços com mTLS STRICT nos namespaces AppGear;
  * Controla roteamento L4/L7, políticas de tráfego, observabilidade profunda;
  * Recebe tráfego do Kong via Istio IngressGateway.

* **Tailscale (Mesh VPN)**

  * Conectividade segura entre clusters, on-prem e edge;
  * Usado para conexões administrativas ou integrações privadas.

**Cadeia oficial de borda (simplificada):**

Traefik → Coraza (WAF) → Kong → Istio IngressGateway → Serviços na malha

---

### 2.3. Segurança, identidade e segredos

* **Keycloak (SSO / IdP)**

  * Autenticação de usuários e serviços;
  * Gestão de clientes (apps), realms, roles.

* **OpenFGA / OPA / Kyverno / Conftest (Autorização / Policy-as-Code)**

  * Definição de políticas de autorização (ABAC/RBAC) e políticas de cluster;
  * Validam manifests e requests com base em regras.

* **Vault (Gestão de segredos)**

  * Fonte única de segredos da plataforma;
  * Integrado a ExternalSecrets/Secrets Store no cluster.

* **Falco (Detecção de ameaças)**

  * Monitora comportamento do kernel/containers para identificar comportamentos suspeitos.

---

### 2.4. Dados, storage e mensageria

* **Ceph (Storage distribuído)**

  * Armazenamento de blocos, objetos e arquivos;
  * Base para volumes persistentes.

* **Postgres / PostGIS**

  * Bancos relacionais principais da plataforma;
  * Uso por serviços Core e Suítes (com schemas isolados).

* **Redis**

  * Cache distribuído;
  * Filas simples e locks.

* **Qdrant**

  * Vetor store para RAG/AI;
  * Usado como repositório de embeddings.

* **Redpanda / RabbitMQ**

  * Redpanda: streaming de eventos de alta performance (Kafka-compatible);
  * RabbitMQ: filas de mensagens clássicas (work queues, RPC assíncrona).

* **Meilisearch**

  * Motor de busca textual.

---

### 2.5. Observabilidade e FinOps

* **Prometheus**

  * Coleta de métricas dos serviços.

* **Loki**

  * Coleta de logs centralizados.

* **Grafana**

  * Dashboards para métricas, logs, traces.

* **OpenCost / Lago**

  * FinOps e billing: custo por namespace, tenant, workspace, serviço.

---

### 2.6. IA, automação e documentos

* **Ollama**

  * Runtime local de modelos open-source (LLMs).

* **LiteLLM**

  * Gateway único de IA;
  * Faz proxy/unificação para provedores externos e runtimes locais (Ollama);
  * Exposição via API única para toda a plataforma (Core + Suítes).

* **Flowise**

  * Orquestração de fluxos de IA (chatflows, RAG flows).

* **n8n / BPMN / Argo Workflows**

  * n8n: automação no-code/low-code (HTTP, eventos, filas, integrações SaaS);
  * Engine BPMN (quando presente): orquestração de processos de negócio;
  * Argo Workflows: jobs e pipelines no cluster.

* **Tika / Gotenberg / SignServer**

  * Tika: extração de texto/metadata de documentos;
  * Gotenberg: conversão e manipulação de PDFs/documents;
  * SignServer (ou similar): assinatura/validação de documentos.

---

### 2.7. DR e continuidade

* **Velero**

  * Backup/restore de volumes e recursos Kubernetes;
  * Parte central da estratégia de DR da plataforma.

---

## 3. Suítes AppGear

### 3.1. Suite Factory

Foco: **integrações, dados e pilares de negócio** (ERP, E-commerce, CRM, BI, etc.).

* Componentes típicos:

  * CDEs (Customer Data Environments)
  * Airbyte / replicadores de dados
  * Conectores ERP / E-commerce / CRM
  * Ferramentas de ETL/ELT

* Depende de:

  * Core de dados (Postgres, Ceph, Redis);
  * Mensageria (Redpanda/RabbitMQ);
  * IA (LiteLLM, Flowise) para enriquecimento e automações;
  * Observabilidade/FinOps.

---

### 3.2. Suite Brain

Foco: **capabilidades de IA, RAG e automação cognitiva**.

* Componentes típicos:

  * Corporate Brain / Domain Brains;
  * Pipelines RAG (indexação + consulta);
  * AI Workforce / agentes;
  * AutoML / experimento de modelos.

* Depende de:

  * LiteLLM (gateway único de IA);
  * Qdrant (vetores);
  * Ceph / Postgres (conteúdo e metadata);
  * Flowise / n8n (orquestração de fluxos);
  * Observabilidade (métricas de uso de IA).

---

### 3.3. Suite Operations

Foco: **execução operacional, IoT, edge e automação de processos**.

* Componentes típicos:

  * IoT Hub / Gateways;
  * KubeEdge / runtimes Edge;
  * RPA / automação de tarefas;
  * Digital Twins;
  * Action Center / orquestração operacional.

* Depende de:

  * Stack de rede (Tailscale, Istio);
  * Mensageria (Redpanda/RabbitMQ);
  * Storage (Ceph);
  * IA (LiteLLM, Flowise) para decisões automáticas.

---

### 3.4. Suite Guardian

Foco: **segurança, conformidade, legal e governança**.

* Componentes típicos:

  * Security Suite (monitoramento, políticas, incident response);
  * Legal AI (análise de contratos/documentos);
  * Chaos / resiliency testing;
  * Governança da App Store / catálogos.

* Depende de:

  * Stack de segurança (Keycloak, Vault, OpenFGA, OPA, Falco, Coraza);
  * Tika / Gotenberg / SignServer (manipulação e assinatura de documentos);
  * Observabilidade;
  * FinOps (para rastrear custo de workloads de segurança/teste).

---

## 4. Mapa Core ↔ Suítes (visão resumida)

### 4.1. Core que serve todas as Suítes

* **LiteLLM**

  * Servido por: Stack Core (IA)
  * Consumido por: Brain, Factory, Operations, Guardian

* **Vault**

  * Servido por: Stack Core
  * Consumido por: todos os serviços que precisam de segredos (Core + Suítes)

* **Keycloak**

  * Servido por: Stack Core
  * Consumido por: Backstage, portais, APIs, apps de Suítes

* **Istio / Kong / Traefik / Coraza**

  * Servido por: Stack Core
  * Consumido por: todos os serviços HTTP expostos e internos

* **Ceph / Postgres / Redis / Qdrant / Redpanda / RabbitMQ**

  * Servidos por: Stack Core
  * Consumidos por: módulos e Suítes conforme uso definido em `modulos.yaml`

* **Prometheus / Loki / Grafana / OpenCost / Lago**

  * Servidos por: Stack Core
  * Consumidos por: qualquer equipe que monitora/observa o ambiente AppGear

---

### 4.2. Exemplos de fluxos entre Suítes e Core

* **Factory → Core**

  * CDEs escrevendo em Postgres/Ceph;
  * pipelines publicando eventos em Redpanda;
  * consultas a APIs de IAM (Keycloak) para contexto de usuário.

* **Brain → Core**

  * pipelines RAG armazenando embeddings em Qdrant;
  * uso intensivo de LiteLLM;
  * dashboards de uso de IA em Grafana/OpenCost.

* **Operations → Core**

  * telemetria IoT em Redpanda;
  * estado de dispositivos em Postgres/Redis;
  * orquestrações em n8n/Argo.

* **Guardian → Core**

  * ingestão de logs/alertas via Loki/Prometheus;
  * verificação de políticas (OPA/OpenFGA);
  * uso de Tika/Gotenberg/SignServer para documentos.

---

## 5. Como manter este mapa

* Sempre que um **novo componente Core** ou **nova Suite** for adicionada:

  * incluir na seção apropriada (Stack Core ou Suítes);
  * atualizar a seção 4 (Core ↔ Suítes), indicando quem consome o quê.

* Sempre que um serviço for **descontinuado ou substituído**:

  * refletir aqui a mudança;
  * manter o histórico no `git` (não é necessário criar arquivo `-old` para este mapa).

* Este arquivo deve seguir as decisões estruturais do:

  * `contract-v0.md`;
  * `audit-v0.md`;
  * `interoperability-v0.md`.

Se o mapa divergir desses documentos, **estes documentos normativos prevalecem**.
