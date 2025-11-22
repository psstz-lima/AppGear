# Contrato de Arquitetura AppGear v0

Este documento define o **Contrato de Arquitetura AppGear v0**.

Ele é a **fonte da verdade arquitetural** da plataforma AppGear e estabelece as regras obrigatórias para:

- o **stack de infraestrutura** (Core e Add-ons), incluindo gestão de recursos via **Scale-to-Zero**;
- **serviços de dados, IA, automação, UI e SSO**;
- **governança** (Segurança, FinOps, Identidade, API);
- **industrialização** (CI/CD, GitOps, Service Mesh, DR);
- **funcionalidades de produto** (Suítes Factory, Brain, Operations, Guardian);
- **documentos oficiais** (0, 1, 2, 3, 4).

A AppGear é uma plataforma de **construção de ecossistemas de negócios orientada por IA**, com foco em:

- **geração AI-First** de aplicações ponta-a-ponta (Backend, Frontend, Lógica, BI, Processos);
- **modularidade inteligente**, permitindo ativar granularmente componentes das 4 Suítes;
- **provisionamento just-in-time** de pilares de negócio (ERP, E-commerce, CRM, IoT, MLOps, etc.);
- **eficiência de nuvem** via **Scale-to-Zero (KEDA)**, evitando consumo de recursos por módulos ociosos;
- **portal unificado (Backstage)** para desenvolvedores e operadores, com governança de custos (FinOps) e dependências;
- **automação de fluxos de negócio** (n8n), processos humanos (BPMN) e **agentes autônomos** (Brain);
- **isolamento de carga de trabalho** (vCluster) e segurança corporativa (Zero-Trust, WAF, Policy-as-Code);
- **extensibilidade via plugins**, geração de código nativo (Mobile/Desktop) e deploy híbrido (Cloud/Edge).

**Terminologia:**

- “AppGear” = nome de produto da plataforma.
- “Topologia A” = Docker Compose (teste/legacy).
- “Topologia B” = Kubernetes (produção/enterprise).
- “0–4” = conjunto de documentos oficiais (ver Seção 10).

---

## 1. Objetivo e escopo

Este contrato:

1. Define **princípios, restrições e decisões arquiteturais** obrigatórias da AppGear.
2. Serve como base para os demais documentos oficiais:  
   - **1 – Desenvolvimento vX**: detalhamento técnico por módulos (00 a 16).  
   - **2 – Auditoria vX**: checklist de conformidade à arquitetura.  
   - **3 – Interoperabilidade vX**: análise de dependências e integrações.  
   - **4 – Comercial vX**: posicionamento de produto e limites de oferta.
3. Abrange:  
   - **Stack Core** (infra, dados, IA, automação, UI, security, observabilidade, DR);  
   - **Stack Add-on** (componentes de negócio por Suíte);  
   - **Topologias A e B**;  
   - **modelo de Tenants, Workspaces e vClusters**;  
   - **governança de IA** (Gateway LiteLLM, RAG, Agentes);  
   - **rede, GitOps, WAF/API Gateway**;  
   - **DR, HA e FinOps**.

O que este contrato **não** faz:

- Não define versões específicas de ferramentas (K8s 1.xx, Postgres 14, etc.) – isso é papel do **1 – Desenvolvimento**.
- Não prescreve políticas comerciais detalhadas (limites de planos, preços) – isso é papel do **4 – Comercial**.
- Não é um manual de operação, mas sim o conjunto de **regras que os manuais devem respeitar**.

> **Guia para chats – Seção 1 (Objetivo e escopo)**  
> - **0 – Contrato:** usar esta seção para decidir se uma sugestão de mudança é estrutural (exige nova versão) ou operacional (pode ir para 1 – Desenvolvimento).  
> - **1 – Desenvolvimento:** garantir que cada módulo (00–16) mapeie claramente para partes deste contrato.  
> - **2 – Auditoria:** construir o checklist base a partir desta seção.  
> - **4 – Comercial:** usar esta seção para descrever “o que a AppGear é” sem entrar em detalhes de implementação.

---

## 2. Stack padrão e ambiente de execução

Dada a expansão do escopo (Business Ecosystem Generator), o stack é dividido em **Core** e **Add-ons**, com regras rígidas para evitar “shadow IT”.

**Execução (Topologia B):**  
A plataforma AppGear v0 é **Kubernetes-native**. Todos os componentes rodam em containers, orquestrados por Kubernetes, gerenciados via GitOps (Seção 5) e escalados via KEDA (Scale-to-Zero).

### Stack Core (Serviços de Infraestrutura e Governança)

- **Portal:** Backstage (Portal do Desenvolvedor / Estúdio).
- **Ingress e Gateway:**
  - Traefik (Ingress Controller / TLS).
  - Kong (API Gateway).
- **Service Mesh:** Istio (mTLS, resiliência, observabilidade de tráfego Leste-Oeste).
- **Conectividade Híbrida (Mesh VPN):**  
  - **Tailscale Kubernetes Operator** é o padrão para:
    - acesso seguro a redes legadas (data centers on-premise, outros clusters);
    - acesso administrativo ao API Server **sem IP público**.
- **Segurança:**
  - HashiCorp Vault (segredos).
  - OpenFGA (autorização fine-grained).
  - OPA (policy-as-code).
  - Falco (runtime).
  - Coraza (WAF).
  - midPoint (IGA / governança de identidade).
  - SignServer (assinatura).
  - Tika + Gotenberg (Legal AI / análise documental / PDF).
- **CI/CD & Industrialização:**
  - Argo Events, Argo Workflows, Argo CD (GitOps Nível 3).
  - LitmusChaos (Chaos Engineering).
  - Cypress (testes E2E).
  - Unleash (feature flags).
- **Escalonamento (Obrigatório):**
  - **KEDA** (Kubernetes Event-driven Autoscaling) é o padrão para gestão de Scale-to-Zero.
  - **Regra:** todo serviço **Add-on** que não for explicitamente classificado como 24/7 crítico no documento **4 – Comercial** deve possuir um `ScaledObject` KEDA ativo, permitindo Scale-to-Zero.
- **Storage (Topologia B):**
  - Ceph (Objeto, Bloco, Arquivo).
- **Isolamento:**
  - vCluster (hard multi-tenancy por Workspace).
- **FinOps:**
  - OpenCost (medição de custo).
  - Lago (billing e monetização).
- **Bancos de Dados Core:**
  - Postgres (incluindo PostGIS para geoespacial).
  - Redis.
  - Qdrant (vetores).
- **Brokers:**
  - RabbitMQ (fila / tasks).
  - Redpanda (streaming / Kafka-compatible).
- **Observabilidade:**
  - Prometheus, Loki, Grafana.
- **Identidade:**
  - SSO via Keycloak (IdP oficial).

### Stack Core (Serviços de Aplicação Base)

- **IA Generativa:**
  - Ollama.
  - Flowise (orquestração de fluxos de IA).
  - **LiteLLM (Gateway Único de IA)**.
- **Orquestração de Processos:**
  - n8n (automação).
  - BPMN (engine de processos humanos).
- **Dados e UI Base:**
  - Directus (SSoT de dados de negócio).
  - Appsmith (painéis e frontends internos).
  - Metabase (BI).
  - Componentes de colaboração (chat, docs, etc.).
- **Busca Corporativa:**
  - **Meilisearch** (busca textual corporativa).
  - Integrado à Suíte Brain (Seção 9) e aos fluxos de RAG (Qdrant).

### Stack Add-on (Pilares de Negócio por Suíte)

Organizado em **4 Suítes Modulares** (ver Seção 9):

- **Factory:** ERP, E-commerce, CRM, Atendimento, CDEs, geração de código nativo (React Native/Tauri).
- **Brain:** RAG, Agentes, AutoML, Corporate Brain, Auto Document Understanding.
- **Operations:** Digital Twins, IoT, Geo-Ops, RPA, Real-Time Action Center.
- **Guardian:** Security Suite, Legal AI, Chaos, App Store, IGA/FinOps avançado.

A inclusão de novos componentes **estruturais** ao Stack Core só pode ocorrer mediante **nova versão deste contrato**.

> **Guia para chats – Seção 2 (Stack padrão)**  
> - **1 – Desenvolvimento:** usar esta lista como stack de referência para Topologia B, incluindo Tailscale, Meilisearch, KEDA, PostGIS, CrewAI/Agentes, etc.  
> - **2 – Auditoria:** checar se:
>   - nenhum serviço Core foi “substituído” por ferramentas paralelas;
>   - Add-ons pesados têm KEDA/Scale-to-Zero configurado;
>   - Tailscale e Meilisearch foram implantados onde exigido.  
> - **3 – Interoperabilidade:** usar o Stack Core como grafo de dependências entre serviços.  
> - **4 – Comercial:** posicionar a robustez do Stack Core como argumento de venda (enterprise-ready).

---

## 2.A Topologias de Implantação

### Topologia A – Docker Compose (Teste / Legacy)

- **Objetivo:** facilitar demonstrações locais, ambientes de teste ou migrações gradativas.
- **Características:**
  - `docker-compose.yml` único ou dividido por serviços.
  - `.env` central (apenas para **testes**, nunca para produção).
- **Limitações:**
  - Não suporta Istio, vCluster, Ceph, Argo, KEDA, Tailscale de forma plena.
  - **Não suportada para produção** em clientes.

### Topologia B – Kubernetes “Business Ecosystem” (Padrão / Enterprise)

- **Objetivo:** oferecimento de **AppGear como plataforma enterprise** (multi-tenant, segura, auditável, FinOps).
- **Orquestração:** Kubernetes.
- **Gestão (Obrigatório):** GitOps com Argo (Events/Workflows/CD), em padrão App-of-Apps (ver Seção 5).
- **Rede:** Istio Service Mesh com mTLS obrigatório.
- **Isolamento:** vCluster por Workspace (hard multi-tenancy).
- **Storage:** Ceph como backend padrão.
- **Escalonamento Add-ons:** KEDA com Scale-to-Zero.
- **Conectividade Híbrida:** Tailscale (Mesh VPN).
- **IA:** Gateway único via LiteLLM.

#### Modelo de Multi-Tenancy e Recursos

- **Hierarquia oficial:**
  - **Tenant:** identificado por `tenant_id`.
  - **Workspace:** identificado por `workspace_id`, pertencente a um `tenant_id`.
  - **vCluster:** unidade de execução isolada, associada a um `workspace_id`.
- **vCluster por Workspace:**
  - Cada `workspace_id` corresponde a um vCluster dedicado, garantindo isolamento de carga (segurança + FinOps).
- **Serviços pesados multi-tenant lógico:**
  - Serviços de alto consumo (ex.: Airbyte, Jupyter corporativo, conectores específicos) podem operar como **instância única por ambiente**, com isolamento baseado em:
    - credenciais por tenant;
    - schemas de banco segregados;
    - filas/tópicos dedicados por tenant;
    - políticas de autorização (OpenFGA / Keycloak).
  - **Ponto de atenção (segurança):** esse modelo aumenta a **complexidade de isolamento**, pois múltiplos tenants compartilham o mesmo Postgres/Redis/infra. A implementação deve garantir, no mínimo:
    - fronteiras rígidas por `tenant_id` em todas as queries e pipelines;
    - segregação por schema/namespace ou equivalente;
    - controles de acesso em camada de aplicação e no gateway de dados;
    - testes automatizados de “não vazamento” (ex.: tentativas de acessar dados de outro `tenant_id`).
  - A **2 – Auditoria v0** deve conter seções específicas para validar o modelo multi-tenant lógico e garantir que dados de um `tenant_id` não vazem para outro.
- **Serviços padrão multi-tenant físico:**
  - Serviços como Directus, Appsmith, n8n, Flowise são provisionados por Workspace em vClusters distintos.
- **Escalonamento:**
  - Serviços pesados (inclusive multi-tenant lógicos) devem suportar **Scale-to-Zero via KEDA**.
  - Serviços marcados como 24/7 críticos devem estar listados explicitamente em **4 – Comercial**.

> **Guia para chats – Seção 2.A (Topologias)**  
> - **0 – Contrato:** arbitrar sempre que Topologia B é o padrão de produção.  
> - **1 – Desenvolvimento:** detalhar manifestos, Helm/Kustomize, ScaledObjects, mapeamento `tenant_id` / `workspace_id` / vCluster, bem como o design seguro de multi-tenancy lógico.  
> - **2 – Auditoria:** validar se o ambiente de cliente segue Topologia B (GitOps, Istio, vCluster, Ceph, KEDA, Tailscale) e se o multi-tenancy lógico atende os controles descritos.  
> - **4 – Comercial:** diferenciar claramente “instalação de teste (Topologia A)” de “oferta enterprise (Topologia B)”.

---

## 3. Estrutura de diretórios

A estrutura oficial de diretórios é dividida em:

1. **Instalação local (Topologia A)** – host de teste/PoC.
2. **Repositórios GitOps / código (Topologia B)**.

### 3.1. Estrutura de instalação local (Topologia A)

```text
/opt/appgear
  .env
  docker-compose.yml
  /config
  /data
  /logs
```

- `.env`: variáveis de teste (sem segredos de produção).
- `docker-compose.yml`: serviços mínimos (Traefik, Postgres, Redis, Flowise, n8n, Directus, Appsmith, Metabase, LiteLLM).
- `config`, `data`, `logs`: volumes bind para facilitar troubleshooting.

### 3.2. Estrutura de repositórios (Topologia B)

Sugestão mínima:

```text
appgear-infra-core/
  cluster/
  apps-core/
  keda/
  istio/
  tailscale/
  ceph/
  velero/
  backstage/
  .argo-apps/

appgear-suites/
  factory/
  brain/
  operations/
  guardian/

appgear-docs/
  docs/architecture/0-contrato/0-Contrato-v0.md
  docs/architecture/1-desenvolvimento-v0.md
  docs/architecture/2-auditoria-v0.md
  docs/architecture/3-interoperabilidade-v0.md
  docs/architecture/4-comercial-v0.md
```

> **Guia para chats – Seção 3 (Diretórios)**  
> - **1 – Desenvolvimento:** usar esta estrutura como referência. Em Topologia B, o foco é o layout GitOps (infra-core e suites).  
> - **2 – Auditoria:** verificar existência de repositórios separados (infra vs suites) e se o contrato está versionado em `docs/architecture/`.

---

## 4. Configuração e Gestão de Segredos

### 4.1. Princípios gerais

- **Topologia A:** `.env` é permitido apenas para testes e nunca pode ser usado com segredos de produção.
- **Topologia B:** toda gestão de segredos deve ser feita via **Vault** + K8s, com:
  - **credenciais dinâmicas** sempre que possível;
  - **injeção segura** em Pods;
  - **proibição de segredos em código, imagens, `.env` versionado, ConfigMaps ou PVCs**.

### 4.2. Fonte da verdade e injeção

- **Fonte da Verdade:** HashiCorp Vault.
- **Padrão de injeção em K8s (obrigatório):**
  - **Vault Agent Sidecar**, escrevendo segredos em volume em memória (tmpfs); ou
  - **External Secrets Operator (ESO)**, sincronizando segredos do Vault em `Secret` K8s, respeitando ciclo de vida do Pod.
- **Autenticação:**
  - Kubernetes Auth (service accounts) ou mecanismos equivalentes de identidade workload-based.
- **CDEs (VS Code Server etc.):**
  - Devem seguir o mesmo padrão de injeção via Vault (Agent ou ESO).
  - É proibido gravar `.env` sensível em diretórios persistentes de trabalho.

### 4.3. Convenções e proibições

- Convenções de nome de paths no Vault (exemplos):
  - `kv/appgear/postgres/config`
  - `kv/appgear/sso/oidc-client-secrets`
  - `database/creds/postgres-role-directus`

- **Proibições explícitas:**
  - Montar segredos em volumes persistentes duráveis (PVC/hostPath) sem driver CSI específico de segredos.
  - Versionar `.env` com segredos em qualquer repositório Git.
  - Embutir segredos em imagens (`Dockerfile` com `ENV PASSWORD=...`).
  - Usar ConfigMaps para dados sensíveis.

> **Guia para chats – Seção 4 (Segredos)**  
> - **1 – Desenvolvimento:** detalhar:
>   - integração Vault ↔ K8s (Auth, Agent, ESO);
>   - uso de credenciais dinâmicas para bancos, clouds, APIs;
>   - abordagem específica para CDEs.  
> - **2 – Auditoria:** verificar ausência de segredos em:
>   - Git, Dockerfile, ConfigMap, `.env` persistente;
>   - clusters sem Vault ou com uso errado de segredos estáticos.  
> - **4 – Comercial:** destacar a aderência a boas práticas enterprise de segredo.

---

## 5. Rede, Service Mesh e GitOps

### 5.1. Rede e Mesh (Topologia B)

- **Service Mesh (obrigatório):** Istio.
  - Todo tráfego Leste–Oeste deve ser encapsulado em mTLS.
  - Istio deve ser configurado com:
    - mTLS “strict” entre serviços Core e Add-ons;
    - políticas de retry, timeout e circuit breaking.
- **Criptografia em trânsito:** TLS na borda (Traefik) + mTLS interno (Istio).

### 5.2. GitOps Nível 3 (padrão AppGear)

- **Princípio:** o estado do cluster é controlado pelo Git.
- **Fluxo AI-First (simplificado):**
  1. Usuário configura um Ecosystem via Backstage/Flowise.
  2. n8n gera artefatos (YAML K8s, SQL, etc.) e **faz commit** no repositório do Workspace.
  3. Argo Events detecta o commit e aciona Argo Workflows.
  4. Argo Workflows executa:
     - testes de conformidade (OPA);
     - testes de UI (Cypress, quando aplicável);
     - cenários de Chaos (LitmusChaos, quando aplicável).
  5. Se aprovado, Argo CD sincroniza os manifestos (Workspace → vCluster).

### 5.3. App-of-Apps

- **Argo CD deve ser configurado em App-of-Apps**, com no mínimo:
  - 1 repositório **infra-core** (Stack Core: Istio, Tailscale, Ceph, Velero, Backstage, Vault, Keycloak, Kong, Coraza, etc.);
  - 1 repositório **suites** (Factory, Brain, Operations, Guardian).
- Serviços Core **não** podem ser definidos em repositórios de Suítes.

### 5.4. Conectividade híbrida (Mesh VPN)

- **Padrão obrigatório:** Tailscale (Malha VPN).
- **Uso:**
  - acesso a bancos de dados legados;
  - conexão entre clusters em múltiplas nuvens;
  - acesso administrativo ao API Server sem exposição pública.
- **Proibição:** é **proibido**:
  - abrir portas de banco diretamente na internet;
  - expor serviços internos fora da cadeia Traefik → Coraza → Kong → Istio (Seção 6).
- **Observação – Dependência e ambientes air-gapped:**
  - Ao tornar o Tailscale mandatório para acesso seguro ao API Server e a recursos legados, a plataforma passa a **depender** de um serviço de Mesh VPN específico.
  - Em ambientes com alta restrição de conectividade (clusters **air-gapped**, órgãos governamentais, instalações críticas), onde o uso de Tailscale **não seja permitido**, será necessário definir uma alternativa de Mesh VPN **funcionalmente equivalente** (ex.: WireGuard/ZeroTier on-prem) e:
    - documentá-la em **1 – Desenvolvimento**;
    - submetê-la ao processo de mudança descrito na Seção 11.3 para futura versão do contrato (v1 ou superior).
  - Para a **v0**, considera-se o **Tailscale** como padrão mandatório, e exceções devem ser tratadas como casos especiais, fora do escopo da v0.

> **Guia para chats – Seção 5 (Rede e GitOps)**  
> - **1 – Desenvolvimento:** detalhar Manifests/Charts de:
>   - Istio (mTLS), Argo (App-of-Apps), Tailscale (Operator);
>   - e documentar eventuais alternativas para ambientes air-gapped como implementação específica, sem alterar a v0.  
> - **2 – Auditoria:** validar:
>   - presença de Istio mTLS;
>   - fluxo GitOps completo (sem “kubectl apply” direto);
>   - uso de Tailscale para conexões híbridas, ou alternativa aprovada via processo de mudança em versões futuras.  
> - **3 – Interoperabilidade:** mapear integrações legadas (sem bancos expostos).  
> - **4 – Comercial:** comunicar GitOps + Mesh VPN como diferenciais.

---

## 6. Roteamento, API Gateway e WAF

### 6.1. Cadeia obrigatória de borda

Na Topologia B, todo tráfego HTTP/HTTPS externo deve seguir:

**Traefik → Coraza → Kong → Istio**

- **Traefik (Ingress Controller):**
  - termina TLS;
  - gerencia certificados (ex.: Let’s Encrypt);
  - roteia por host/path para o WAF (Coraza) e o API Gateway (Kong).
- **Coraza (WAF):**
  - aplica regras OWASP;
  - protege contra XSS, SQLi, LFI/RFI, etc.
- **Kong (API Gateway):**
  - controla acesso a APIs (rate-limit, auth, keys);
  - integra-se com Lago para monetização de chamadas;
  - encaminha o tráfego para serviços dentro da Mesh (Istio).
- **Istio:**
  - faz o roteamento interno, com mTLS.

É **vedado** expor serviços de negócio diretamente via Traefik (host/path) sem passar por Coraza e Kong, exceto:

- endpoints estritamente técnicos de operação (ex.: health-checks internos da malha);
- casos documentados no 1 – Desenvolvimento e aprovados via 2 – Auditoria.

### 6.2. Prefixos padrão

Os principais serviços Core devem ser expostos com prefixos convenientes (via Kong):

- `/backstage` → Backstage
- `/flowise` → Flowise
- `/n8n` → n8n
- `/directus` → Directus
- `/appsmith` → Appsmith
- `/sso` → Keycloak
- `/bi` → Metabase
- `/bpmn` → BPMN
- `/vault` → Vault
- `/kong` → Kong (UI/admin)
- `/argo` → Argo CD (UI)
- `/observability` → Grafana / Loki / Prometheus
- Add-ons: `/erp`, `/ecommerce`, `/crm`, `/chat`, etc.

> **Guia para chats – Seção 6 (Roteamento)**  
> - **1 – Desenvolvimento:** garantir implementação da cadeia:
>   - Traefik → Coraza → Kong → Istio;
>   - definir prefixos, security plugins, logging, monetização.  
> - **2 – Auditoria:** checar se **nenhum serviço de negócio** está exposto diretamente no Traefik.  
> - **3 – Interoperabilidade:** usar Kong como ponto central de integração com terceiros.  
> - **4 – Comercial:** apresentar Kong + Lago como “motor de API Economy”.

---

## 7. Serviços, Governança (Nível Duplo) e Add-ons

A governança da AppGear é pensada em dois níveis:

- **Nível Administração (7.1):** gestão de Add-ons, políticas globais, identidade, billing, DR.
- **Nível Usuário (7.2):** experiência AI-First de geração de aplicações e ecossistemas.

### 7.1. Nível Administração (Gerenciamento de Add-ons)

- Administração da plataforma (TI, SRE, FinOps).
- Responsável por:
  - Aprovar/instalar novos Add-ons no catálogo (Suítes).
  - Configurar limites de uso (quotas, Scale-to-Zero).
  - Configurar identidade (Keycloak, midPoint, OpenFGA).
  - Definir políticas de DR (Velero) e de segurança (OPA, Falco, WAF).
  - Publicar/retirar ofertas da App Store interna.

### 7.2. Nível Usuário (Provisionamento AI-First)

- Usuários de negócio, squads, parceiros.
- Utilizam o Backstage + Flowise + n8n para:
  - descrever o ecosistema desejado (objetivos de negócio, integrações);
  - gerar aplicações (APIs, UIs, workflows);
  - ativar módulos das Suítes (ERP, E-commerce, IoT, RPA, etc.).
- O AI-First Generator sempre escreve no Git; não aplica diretamente no cluster.

> **Guia para chats – Seção 7 (Governança)**  
> - **1 – Desenvolvimento:** traduzir esta separação em papéis (RBAC/ReBAC) e fluxos (Usuário vs Admin).  
> - **2 – Auditoria:** validar se:
>   - ações sensíveis estão restritas ao Nível Administração;
>   - o provisionamento AI-First respeita o fluxo GitOps.  
> - **4 – Comercial:** posicionar o “Nível Usuário” como experiência low-code/no-code AI-First.

### 7.A Arquitetura de Segurança, Identidade e Isolamento (Suíte Guardian)

Esta seção consolida as decisões da Suíte Guardian.

- **Identidade:**
  - Keycloak como IdP único.
  - midPoint como IGA (vida da identidade, governança de acessos).
- **Autorização:**
  - OpenFGA / OpenFGA-like para RBAC/ABAC/FGA.
- **Segurança em runtime:**
  - Falco monitorando eventos de kernel/container.
- **Política (Policy-as-Code):**
  - OPA (Open Policy Agent) aplicando políticas de:
    - deploy (pré-sync Argo);
    - runtime (sidecars, admission controllers).
- **Isolamento:**
  - vCluster por Workspace (hard multi-tenancy).
  - KEDA + pods stateless (onde possível) para facilitar Scale-to-Zero.
- **Compliance e assinatura:**
  - SignServer para assinatura de artefatos (pacotes, contratos).
  - Tika + Gotenberg para análises contratuais e geração documental.

> **Guia para chats – Seção 7.A (Guardian)**  
> - **1 – Desenvolvimento:** detalhar integrações:
>   - Backstage ↔ Keycloak ↔ midPoint;
>   - Argo ↔ OPA;
>   - Falco e SignServer.  
> - **2 – Auditoria:** validar:
>   - uso de Keycloak como IdP único;
>   - adesão a OPA, Falco, OpenFGA;
>   - isolamento via vCluster.

### 7.B Contratos de Dados, IA e Eventos (Suítes Brain & Operations)

- **Fonte da Verdade (negócio):**
  - Directus (SSoT de dados de domínio).
- **Fonte da Verdade (legado):**
  - Airbyte para ingestão de sistemas legados e replicação.
- **Dados geoespaciais:**
  - PostGIS para Digital Twins e Geo-Ops.
- **Busca:**
  - Meilisearch (texto) + Qdrant (vetores / embeddings).
- **Catálogo:**
  - OpenMetadata (ou equivalente).
- **Eventos:**
  - RabbitMQ para jobs/filas;
  - Redpanda para streamings event-driven.

> **Guia para chats – Seção 7.B (Dados, IA, Eventos)**  
> - **1 – Desenvolvimento:** detalhar:
>   - pipelines de ingestão (Airbyte, n8n);
>   - RAG (Meilisearch + Qdrant);
>   - fluxo de eventos (Redpanda, RabbitMQ).  
> - **2 – Auditoria:** checar uso de:
>   - LiteLLM como gateway único de LLM;
>   - trilhas de auditoria para dados sensíveis.  
> - **3 – Interoperabilidade:** mapear fluxos de dados geoespaciais, streaming e integrações com legados.

### 7.C Gestão de Evolução de Dados (Migrações)

- **Schemas relacionais:**
  - gerenciados via ferramentas de migração (Flyway/Liquibase/dbt) conforme 1 – Desenvolvimento.
- **Legacy Migration:**
  - Suíte Factory instala pipelines Airbyte + n8n para migrar bancos legados e planilhas para o modelo AppGear.

> **Guia para chats – Seção 7.C (Migrações)**  
> - **1 – Desenvolvimento:** detalhar padrões de migração, rollback e versionamento de schema.  
> - **2 – Auditoria:** validar histórico de migrações e reversibilidade.

### 7.D Auditoria e Resiliência (HA)

- **Logs de auditoria:**
  - devem incluir eventos de Vault, OPA, Falco, Keycloak, Kong.
- **Stateless por padrão:**
  - regra estendida a Add-ons onde possível para facilitar KEDA/HA.
- **Chaos Engineering:**
  - LitmusChaos como base para testes de resiliência.

> **Guia para chats – Seção 7.D (Auditoria & HA)**  
> - **1 – Desenvolvimento:** preparar cenários de Chaos e dashboards de auditoria.  
> - **2 – Auditoria:** validar existência de testes de resiliência e trilhas de auditoria.

### 7.E Segurança de Infra e Continuidade

- **DR com Velero (obrigatório):**
  - Velero é o mecanismo padrão de backup/restore de:
    - recursos K8s (manifests);
    - volumes persistentes.
  - `BackupStorageLocation` deve usar **Object Storage externo ao cluster** (S3-compatível) e fisicamente separado de Ceph.
- **Snapshots CSI:**
  - workloads stateful devem usar `VolumeSnapshots` via driver CSI integrado ao Velero;
  - evita acoplamento a um único provedor de nuvem/storage.
- **Backups de segredos e metadados:**
  - segredos: protegidos pelo Vault (incluindo exportações criptografadas para DR);
  - manifests: protegidos em Git (com backup off-cluster).
- **Criptografia:**
  - **Em trânsito:** TLS na borda, mTLS interno (Istio).
  - **Em repouso:** criptografia em Ceph/Postgres com chaves geridas pelo Vault ou HSM.

> **Guia para chats – Seção 7.E (DR & Segurança de Infra)**  
> - **1 – Desenvolvimento:** descrever:
>   - política de backup (frequência, retenção);
>   - cenários de restore em novo cluster.  
> - **2 – Auditoria:** checar:
>   - existência de backups em Object Storage externo;
>   - testes de restauração periódicos.

---

## 8. Portal Unificado (Backstage)

Esta seção substitui a antiga ideia de “Webapp PWA” como UI principal.

- **Tecnologia (obrigatória):** Backstage.
- **Função:** “Estúdio AppGear”, cockpit central.
- **Responsabilidades principais:**
  - catálogo de serviços, templates e plugins;
  - integração com Flowise/n8n para geração AI-First;
  - exibição de custos e consumo (OpenCost/Lago);
  - alertas de dependências (ex.: “recurso requer módulo Brain/Guardian”);
  - App Store interna (instalação de Add-ons).

> **Guia para chats – Seção 8 (Backstage)**  
> - **1 – Desenvolvimento:** implementar plugins para:
>   - AI Dependency Alert;
>   - painel de custos/FinOps;
>   - App Store interna.  
> - **4 – Comercial:** posicionar o Backstage como “Estúdio Inteligente” da plataforma.

---

## 9. Funcionalidades de produto (AI-First Ecosystem Generator)

A AppGear é um **AI-First Ecosystem Generator**, organizada em **4 Suítes Modulares**.

### 9.1. Regra de IA – Gateway Único (LiteLLM)

- Todo tráfego de LLM (OpenAI, Anthropic, Ollama, etc.) deve passar pelo **LiteLLM**, que é o **Gateway Único de IA** da plataforma.
- É **proibido** que serviços Core ou Add-ons:
  - instanciem SDKs diretos de provedores de LLM;
  - façam chamadas HTTP diretas a provedores de LLM;
  - ignorem o LiteLLM em qualquer fluxo de IA.
- Violações são tratadas como **quebra de contrato de arquitetura** e devem ser apontadas em **2 – Auditoria**.

### 9.2. Níveis de geração

- **Nível 1 – Fundamentos:**
  - Geração de estruturas básicas (APIs, DB, UI simples).
- **Nível 2 – Industrialização:**
  - Conecta geração à esteira GitOps, testes e observabilidade.
- **Nível 3 – Full Ecosystem por Suítes:**
  - Ativa componentes das **4 Suítes**, compondo um ecossistema completo (ERP, E-commerce, CRM, IoT, etc.).
- **Nível 4 – Deploy Híbrido:**
  - Orquestra cargas em **Edge** via KubeEdge (RPA, IoT, Digital Twins).

### 9.3. Suíte 1 – AppGear Factory (Núcleo de Construção)

- Geração de:
  - código backend;
  - frontends (incluindo PWA, Tailwind + shadcn/ui);
  - mobile (React Native);
  - desktop (Tauri).
- CDEs (VS Code Server) com integração ao Vault.
- Engenharia reversa de bancos legados (Airbyte + n8n).

### 9.4. Suíte 2 – AppGear Brain (Inteligência de Negócios)

- **Corporate Brain:** RAG-as-a-Service usando:
  - Qdrant (vetores);
  - Meilisearch (texto).
- **AI Workforce:** Agentes Autônomos (CrewAI/AutoGen) orquestrados via Flowise e LiteLLM.
- **AutoML Studio:** construção de modelos preditivos no-code.

### 9.5. Suíte 3 – AppGear Operations (Físico & Processos)

- **Digital Twins & Geo-Ops:** ThingsBoard + PostGIS.
- **RPA:** automação de sistemas sem API.
- **Real-Time Action Center:** decisões baseadas em eventos (Redpanda).
- **API Economy:** monetização de APIs (Kong + Lago).

### 9.6. Suíte 4 – AppGear Guardian (Governança & Segurança)

- **Compliance:** IGA (midPoint), governança de acessos.
- **Security Suite:** Pentest AI, Browser Isolation, monitoramento.
- **Resilience-as-a-Service:** Chaos Engineering aplicado.
- **Legal AI:** Tika + Gotenberg, geração de SBOM e revisão contratual.

> **Guia para chats – Seção 9 (Funcionalidades)**  
> - **1 – Desenvolvimento:** implementar scripts de geração (n8n/Flowise) garantindo uso exclusivo de LiteLLM como gateway de IA.  
> - **2 – Auditoria:** validar:
>   - uso de LiteLLM;
>   - segurança e isolamento dos CDEs, Agentes e fluxos RAG.  
> - **4 – Comercial:** mapear pacotes/planos baseados nas 4 Suítes e nos Níveis 1–4.

---

## 10. Documentos oficiais e versionamento

Documentos oficiais da AppGear:

- **0 – Contrato vX.md** – contrato de arquitetura (este documento, v0).
- **1 – Desenvolvimento vX.md** – implantação técnica por módulos.
- **2 – Auditoria vX.md** – parecer técnico de aderência ao contrato.
- **3 – Interoperabilidade vX.md** – parecer sobre integrações.
- **4 – Comercial vX.md** – visão de produto/planos e limites.

### 10.1. Versionamento

- Versões principais: `v0`, `v1`, `v2`, ...
- Tag Git recomendada: `contract-v0`, `contract-v1`, ...
- Esta versão é **v0**.  
  Ajustes finos decorrentes dos Módulos 00–16 foram incorporados **sem alterar o número de versão**, pois não mudam o objetivo do produto, apenas refinam a precisão técnica.

> **Guia para chats – Seção 10 (Documentos e versões)**  
> - **0 – Contrato:** manter sempre claro qual versão está vigente.  
> - **1–4:** referenciar explicitamente “0 – Contrato v0” (ou sua versão futura) em seus cabeçalhos.

---

## 11. Restrições, Flexibilidade Controlada e Alterações

### 11.1. Restrições estruturais (regras rígidas)

Regras que **não podem ser violadas** sem nova versão do contrato:

- Exposição de serviços de negócio fora da cadeia Traefik → Coraza → Kong → Istio.
- Substituição ou duplicação de componentes do Stack Core.
- Acesso direto a LLMs, ignorando o LiteLLM.
- Uso de segredos estáticos em código/imagens/Git/ConfigMaps.
- Deploy manual (fora do fluxo GitOps Nível 3) como padrão.

### 11.2. Flexibilidade controlada

Itens que podem variar com **documentação em 1 – Desenvolvimento**:

- Distribuição K8s (EKS, GKE, AKS, on-prem).
- Implementações específicas de logging/monitoramento (desde que integrem com Loki/Prometheus/Grafana).
- Detalhes de pipelines CI/CD desde que preservem GitOps Nível 3.
- Uso de ferramentas alternativas equivalentes (desde que aprovadas via processo de mudança).

### 11.3. Processo de alteração do contrato

- Qualquer alteração deve seguir:
  1. Abertura de Issue de “Proposta de alteração do 0 – Contrato”.
  2. Discussão, análise de impacto.
  3. PR com alterações no arquivo `0-Contrato-vX.md`.
  4. Aprovação por responsáveis de Arquitetura/Governança.
  5. Criação de nova tag Git e atualização da versão no cabeçalho.

### 11.4. Pontos de atenção específicos da v0

Os seguintes pontos são **atenções especiais** para implementação dos módulos e para auditorias, sem alterar as regras principais da v0:

1. **Multi-tenancy lógico (serviços pesados):**
   - O contrato permite instâncias multi-tenant lógicas (ex.: Airbyte) por razões de custo e eficiência.
   - Esse modelo **aumenta a superfície de risco** de vazamento de dados entre `tenant_id` dentro da mesma instância Postgres/Redis/infra.
   - A implementação nos módulos (especialmente 9 e 13) deve ser **rigorosa**, com:
     - fronteiras claras de dados por `tenant_id`;
     - testes automatizados específicos de “não vazamento”;
     - reforço de controles em **2 – Auditoria v0**.

2. **Dependência do Tailscale para acesso ao API Server:**
   - A v0 assume o Tailscale como **padrão mandatório** para acesso seguro ao API Server e a recursos legados.
   - Em ambientes **air-gapped** ou de segurança extrema, o uso de Tailscale poderá não ser viável:
     - nesses casos, uma solução de Mesh VPN equivalente deve ser proposta em **1 – Desenvolvimento**;
     - eventuais exceções permanentes devem ser tratadas como motivadores de uma futura **v1** (via processo de alteração da Seção 11.3).

> **Guia para chats – Seção 11 (Restrições & Pontos de Atenção)**  
> - **0 – Contrato:** usar esta seção para julgar pedidos de exceção e decidir se exigem v1 ou apenas detalhamento em 1 – Desenvolvimento.  
> - **1 – Desenvolvimento:** tratar multi-tenancy lógico e Tailscale como temas sensíveis, com documentação e testes reforçados.  
> - **2 – Auditoria:** considerar estes pontos de atenção como “itens quentes” nos checklists de v0.

---

## 12. Itens deliberadamente delegados ao 1 – Desenvolvimento

O documento **1 – Desenvolvimento v0** deve detalhar, no mínimo:

- **Arquitetura K8s e Scale-to-Zero:**
  - manifests de KEDA (`ScaledObjects`) para Add-ons;
  - configuração de pods de VS Code Server (CDEs) com Vault.
- **Rede e Mesh:**
  - configuração detalhada de Istio;
  - gateways, virtual services, policies.
- **DR e Backup:**
  - configuração de Velero e VolumeSnapshots CSI;
  - cenários de restore.
- **Backstage e plugins:**
  - App Store interna;
  - AI Dependency Alert;
  - integração com Flowise/n8n.
- **Integração de Suítes:**
  - fluxos para Factory/Brain/Operations/Guardian;
  - uso de Tailscale para integrações legadas.

> **Guia para chats – Seção 12 (Delegado ao 1 – Desenvolvimento)**  
> - **1 – Desenvolvimento:** priorizar o setup de KEDA, Tailscale, Velero e plugins críticos do Backstage.  
> - **2 – Auditoria:** incluir verificação de Scale-to-Zero, segurança dos CDEs, DR efetivo e uso correto de LiteLLM/Tailscale.

---

*Fim do Contrato de Arquitetura AppGear v0.*
