# Contrato de Arquitetura AppGear

Versão: v0

Este documento define o **Contrato de Arquitetura AppGear**.

Ele é a **fonte da verdade arquitetural** da plataforma AppGear e estabelece as regras obrigatórias para:

* o **stack de infraestrutura** (Core e Add-ons), incluindo gestão de recursos via **Scale-to-Zero**;
* **serviços de dados, IA, automação, UI e SSO**;
* **governança** (Segurança, FinOps, Identidade, API);
* **industrialização** (CI/CD, GitOps, Service Mesh, DR);
* **funcionalidades de produto** (Suítes Factory, Brain, Operations, Guardian);
* **documentos oficiais** (0, 1, 2, 3, 4).

A AppGear é uma plataforma de **construção de ecossistemas de negócios orientada por IA**, com foco em:

* **geração AI-First** de aplicações ponta-a-ponta (Backend, Frontend, Lógica, BI, Processos);
* **modularidade inteligente**, permitindo ativar granularmente componentes das 4 Suítes;
* **provisionamento just-in-time** de pilares de negócio (ERP, E-commerce, CRM, IoT, MLOps, etc.);
* **eficiência de nuvem** via **Scale-to-Zero (KEDA)**, evitando consumo de recursos por módulos ociosos;
* **portal unificado (Backstage)** para desenvolvedores e operadores, com governança de custos (FinOps) e dependências;
* **automação de fluxos de negócio** (n8n), processos humanos (BPMN) e **agentes autônomos** (Brain);
* **isolamento de carga de trabalho** (vCluster) e segurança corporativa (Zero-Trust, WAF, Policy-as-Code);
* **extensibilidade via plugins**, geração de código nativo (Mobile/Desktop) e deploy híbrido (Cloud/Edge).

**Terminologia:**

* “AppGear” = nome de produto da plataforma.
* “Topologia A” = Docker Compose (teste/legacy).
* “Topologia B” = Kubernetes (produção/enterprise).
* “0–4” = conjunto de documentos oficiais (ver Seção 10).
* “appgear-” = prefixo oficial para repositórios (ex.: `appgear-gitops-core`),
  `/opt/appgear` = diretório base padrão, e `appgear-net-core` = rede Docker de referência para Topologia A.

## Estado atual da plataforma

- Este contrato incorpora as correções e retrofits v0.3 nos módulos 00–17, mantendo a linha v0 como fonte de verdade funcional.
- **Linha v0** permanece como baseline estável e referência contratual, enquanto as revisões v0.1/v0.3 seguem em retrofit documentado em `development/v0.3/stack-unificada-v0.3.yaml`.
- **Interoperabilidade e borda**: cadeia Traefik → Coraza → Kong → Istio com mTLS STRICT continua obrigatória para todos os serviços Core e Suítes.
- **Governança de pipeline**: artefatos padronizados em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` com hashes SHA-256 e parecer automatizado da IA + RAPID/CCB conforme `guides/ai-ci-cd-flow.md` e `guides/integrated-report-procedure.md`.
- **FinOps e multi-tenancy**: rótulos `appgear.io/*` e SBOMs rastreáveis são pré-condição de entrega, preservando isolamento por tenant/workspace em Topologia B.

---

## 1. Objetivo e escopo

Este contrato:

1. Define **princípios, restrições e decisões arquiteturais** obrigatórias da AppGear.
2. Serve como base para os demais documentos oficiais:
   * **1 – Desenvolvimento vX**: detalhamento técnico por módulos (00 a 16).
   * **2 – Auditoria vX**: checklist de conformidade à arquitetura.
   * **3 – Interoperabilidade vX**: análise de dependências e integrações.
   * **4 – Comercial vX**: posicionamento de produto e limites de oferta.
3. Abrange:
   * **Stack Core** (infra, dados, IA, automação, UI, security, observabilidade, DR);
   * **Stack Add-on** (componentes de negócio por Suíte);
   * **Topologias A e B**;
   * **modelo de Tenants, Workspaces e vClusters**;
   * **governança de IA** (Gateway LiteLLM, RAG, Agentes);
   * **rede, GitOps, WAF/API Gateway**;
   * **DR, HA e FinOps**.

O que este contrato **não** faz:

* Não define versões específicas de ferramentas (K8s 1.xx, Postgres 14, etc.) – isso é papel do **1 – Desenvolvimento**.
* Não prescreve políticas comerciais detalhadas (limites de planos, preços) – isso é papel do **4 – Comercial**.
* Não é um manual de operação, mas sim o conjunto de **regras que os manuais devem respeitar**.

> **Guia para chats – Seção 1 (Objetivo e escopo)**  
> * **0 – Contrato:** usar esta seção para decidir se uma sugestão de mudança é estrutural (exige nova versão) ou operacional (pode ir para 1 – Desenvolvimento).  
> * **1 – Desenvolvimento:** garantir que cada módulo (00–16) mapeie claramente para partes deste contrato.  
> * **2 – Auditoria:** construir o checklist base a partir desta seção.  
> * **4 – Comercial:** usar esta seção para descrever “o que a AppGear é” sem entrar em detalhes de implementação.

---

## 2. Stack padrão e ambiente de execução

Dada a expansão do escopo (Business Ecosystem Generator), o stack é dividido em **Core** e **Add-ons**, com regras rígidas para evitar “shadow IT”.

**Execução (Topologia B):**  
A plataforma AppGear v0 é **Kubernetes-native**. Todos os componentes rodam em containers, orquestrados por Kubernetes, gerenciados via GitOps (Seção 5) e escalados via KEDA (Scale-to-Zero).

### Stack Core (Infraestrutura Obrigatória)

Inclui, no mínimo:

* **Rede e Borda:**
  * Traefik (ingress controller de borda).
  * Coraza (WAF).
  * Kong (API Gateway).
  * Istio (Service Mesh com mTLS obrigatório).
  * Tailscale (Mesh VPN para conectividade híbrida).
* **Segurança, Identidade e Segredos:**
  * Vault (SSoT de segredos).
  * OPA/Kyverno/Conftest (Policy-as-Code).
  * Falco (deteção de ameaças).
  * Keycloak (IdP).
* **Dados e Storage:**
  * Ceph (Storage distribuído).
  * Postgres, Redis, Qdrant, Redpanda, Meilisearch, PostGIS (componentes de dados).
* **Observabilidade e FinOps:**
  * Prometheus, Loki, Grafana.
  * OpenCost + Lago (FinOps e billing).
* **IA e Automação:**
  * LiteLLM (Gateway Único de IA).
  * Flowise, n8n, Tika, Gotenberg, CrewAI/Agentes.
* **Portal & Orquestração:**
  * Backstage (portal unificado).
  * Argo (Events, Workflows, CD) em modelo App-of-Apps.
  * KEDA (Scale-to-Zero).
  * Velero (DR).

### Stack Add-on (Pilares de Negócio por Suíte)

Organizado em **4 Suítes Modulares** (ver Seção 9):

* **Factory:** ERP, E-commerce, CRM, Atendimento, CDEs, geração de código nativo (React Native/Tauri).
* **Brain:** RAG, Corporate Brain, AI Workforce, AutoML, Auto Document Understanding.
* **Operations:** Digital Twins, IoT, Geo-Ops, RPA, Real-Time Action Center.
* **Guardian:** Security Suite, Legal AI, Chaos, App Store, IGA/FinOps avançado.

A inclusão de novos componentes **estruturais** ao Stack Core só pode ocorrer mediante **nova versão deste contrato**.

> **Guia para chats – Seção 2 (Stack padrão)**  
> * **1 – Desenvolvimento:** usar esta lista como stack de referência para Topologia B, incluindo Tailscale, Meilisearch, KEDA, PostGIS, CrewAI/Agentes, etc.  
> * **2 – Auditoria:** checar se:
>   * nenhum serviço Core foi “substituído” por ferramentas paralelas;
>   * Add-ons pesados têm KEDA/Scale-to-Zero configurado;
>   * Tailscale e Meilisearch foram implantados onde exigido.  
> * **3 – Interoperabilidade:** usar o Stack Core como grafo de dependências entre serviços.  
> * **4 – Comercial:** posicionar a robustez do Stack Core como argumento de venda (enterprise-ready).

---

## 2.1 Topologias de Implantação

### Topologia A – Docker Compose (Teste / Legacy)

* **Objetivo:** facilitar demonstrações locais, ambientes de teste ou migrações gradativas.
* **Características:**
  * `docker-compose.yml` único ou dividido por serviços.
  * `.env` central (apenas para **testes**, nunca para produção).
* **Limitações:**
  * Não suporta Istio, vCluster, Ceph, Argo, KEDA, Tailscale de forma plena.
  * **Não suportada para produção** em clientes.

### Topologia B – Kubernetes “Business Ecosystem” (Padrão / Enterprise)

* **Objetivo:** oferecimento de **AppGear como plataforma enterprise** (multi-tenant, segura, auditável, FinOps).
* **Orquestração:** Kubernetes.
* **Gestão (Obrigatório):** GitOps com Argo (Events/Workflows/CD), em padrão App-of-Apps (ver Seção 5).
* **Rede:** Istio Service Mesh com mTLS obrigatório.
* **Isolamento:** vCluster por Workspace (hard multi-tenancy).
* **Storage:** Ceph como backend padrão.
* **Escalonamento Add-ons:** KEDA com Scale-to-Zero.
* **Conectividade Híbrida:** Tailscale (Mesh VPN).
* **IA:** Gateway único via LiteLLM.

#### Modelo de Multi-Tenancy e Recursos

* **Hierarquia oficial:**
  * **Tenant:** identificado por `tenant_id`.
  * **Workspace:** identificado por `workspace_id`, pertencente a um `tenant_id`.
  * **vCluster:** unidade de execução isolada, associada a um `workspace_id`.
* **vCluster por Workspace:**
  * Cada `workspace_id` corresponde a um vCluster dedicado, garantindo isolamento de carga (segurança + FinOps).

> **Guia para chats – Seção 2.1 (Topologias)**  
> * **0 – Contrato:** arbitrar sempre que Topologia B é o padrão de produção.  
> * **1 – Desenvolvimento:** detalhar manifestos, Helm/Kustomize, ScaledObjects, mapeamento `tenant_id` / `workspace_id` / vCluster, bem como o design seguro de multi-tenancy lógico.  
> * **2 – Auditoria:** validar se o ambiente de cliente segue Topologia B (GitOps, Istio, vCluster, Ceph, KEDA, Tailscale) e se o multi-tenancy lógico atende os controles descritos.  
> * **4 – Comercial:** diferenciar claramente “instalação de teste (Topologia A)” de “oferta enterprise (Topologia B)”.

---

## 3. Estrutura de diretórios

A estrutura oficial de diretórios é dividida em:

1. **Instalação local (Topologia A)** – host de teste/PoC.
2. **Repositórios GitOps / código (Topologia B)**.

> **Nota:** a atualização abaixo reflete apenas a **organização dos diretórios**. Todo o restante deste contrato permanece inalterado nesta versão v0.

### 3.1. Estrutura de instalação local (Topologia A)

```text
/opt/appgear
  .env
  docker-compose.yml
  /config
  /data
  /logs
````

* `.env`: variáveis de teste (sem segredos de produção).
* `docker-compose.yml`: serviços mínimos (Traefik, Postgres, Redis, Flowise, n8n, Directus, Appsmith, Metabase, LiteLLM).
* `config`, `data`, `logs`: volumes bind para facilitar troubleshooting.

### 3.2. Estrutura de repositórios (Topologia B)

Estrutura de referência na raiz do repositório AppGear:

```text
docs/
  architecture/contract/contract-v0.md
  architecture/audit/audit-v0.md
  architecture/interoperability/interoperability-v0.md

development/
  v0/module-00-v0.md ... module-17-v0.md
  v0.1/module-00-v0.1.md ...
  v0.2/module-00-v0.2.md ...
  v0.3/core-module-v0.3.md

reports/
  review/review-v0.md
  review/supporting-docs/
    coordination-review.md
    review-engine.md
    audit-engine.md
    interoperability-engine.md
  interoperability/interoperability-report-v0.1.md
```

> **Guia para chats – Seção 3 (Diretórios)**
>
> * **1 – Desenvolvimento:** usar esta estrutura como referência para localizar rapidamente os módulos versionados (contrato, auditoria, interoperabilidade e desenvolvimento).
> * **2 – Auditoria:** verificar se os documentos oficiais estão versionados nos diretórios `docs/` e se os módulos técnicos estão em `development/`.

---

## 4. Configuração e Gestão de Segredos

### 4.1. Princípios gerais

* **Topologia A:** `.env` é permitido apenas para testes e nunca pode ser usado com segredos de produção.
* **Topologia B:** toda gestão de segredos deve ser feita via **Vault** + K8s, com:

  * **credenciais dinâmicas** sempre que possível;
  * **injeção segura** em Pods;
  * **proibição de segredos em código, imagens, `.env` versionado, ConfigMaps ou PVCs**.

### 4.2. Fonte da verdade e injeção

* Vault é a **fonte única de verdade** (`kv/appgear/...`, `database/creds/...`).
* Integração com Kubernetes via:

  * Auth Method (Kubernetes Auth);
  * Vault Agent Injector ou External Secrets Operator.
* Segredos nunca devem ser codificados diretamente em manifests ou arquivos de configuração locais.

> **Guia para chats – Seção 4 (Segredos)**
>
> * **1 – Desenvolvimento:** detalhar:
>
>   * integração Vault ↔ K8s (Auth, Agent, ESO);
>   * uso de credenciais dinâmicas para bancos, clouds, APIs;
>   * abordagem específica para CDEs.
> * **2 – Auditoria:** verificar ausência de segredos em:
>
>   * Git, Dockerfile, ConfigMap, `.env` persistente;
>   * clusters sem Vault ou com uso errado de segredos estáticos.
> * **4 – Comercial:** destacar a aderência a boas práticas enterprise de segredo.

---

## 5. Rede, Service Mesh e GitOps

### 5.1. Rede e Mesh (Topologia B)

* **Service Mesh (obrigatório):** Istio.

  * Todo tráfego Leste–Oeste deve ser encapsulado em mTLS.
  * Istio deve ser configurado com:

    * mTLS “strict” entre serviços Core e Add-ons;
    * políticas de retry, timeout e circuit breaking.
* **Criptografia em trânsito:** TLS na borda (Traefik) + mTLS interno (Istio).

### 5.2. GitOps Nível 3 (padrão AppGear)

* **Princípio:** o estado do cluster é controlado pelo Git.
* **Fluxo AI-First (simplificado):**

  1. Usuário configura um Ecosystem via Backstage/Flowise.
  2. n8n gera artefatos (YAML K8s, SQL, etc.) e **faz commit** no repositório do Workspace.
  3. Argo Events detecta o commit e aciona Argo Workflows.
  4. Argo Workflows executa:

     * testes de conformidade (OPA);
     * testes de UI (Cypress, quando aplicável);
     * cenários de Chaos (LitmusChaos, quando aplicável).
  5. Se aprovado, Argo CD sincroniza os manifestos (Workspace → vCluster).

### 5.3. App-of-Apps → ApplicationSet (list-generator)

* **App-of-Apps permanece apenas como bootstrap** (instalação do Argo CD + root apps mínimos) e **todo o ciclo GitOps passa a usar ApplicationSets com list-generator** para Core, Suítes e Workspaces/vClusters.

  * 1 repositório **infra-core** (Stack Core: Istio, Tailscale, Ceph, Velero, Backstage, Vault, Keycloak, Kong, Coraza, etc.) referenciado por **ApplicationSet** com lista de clusters/ambientes Core.
  * 1 repositório **suites** (Factory, Brain, Operations, Guardian) referenciado por **ApplicationSet** com lista de clusters/ambientes Core.
  * 1 repositório **workspaces** com **ApplicationSet (list-generator)** que gera um `Application` por `workspace_id`/`vcluster_id`, usando labels obrigatórias (`appgear.io/tenant`, `appgear.io/workspace`, `appgear.io/vcluster`, `appgear.io/env`).
* Serviços Core **não** podem ser definidos em repositórios de Suítes; o ApplicationSet apenas agrupa os manifestos em repositórios distintos.
* Benefício: **gestão dinâmica de workspaces/vClusters** (acréscimo/remoção por PR na lista), eliminando drift e evitando `Application` manual no App-of-Apps.

### 5.4. Conectividade híbrida (Mesh VPN)

* **Padrão obrigatório:** Tailscale (Malha VPN).
* **Uso:**

  * acesso a bancos de dados legados;
  * conexão entre clusters em múltiplas nuvens;
  * acesso administrativo ao API Server sem exposição pública.
* **Proibição:** é **proibido**:

  * abrir portas de banco diretamente na internet;
  * expor serviços internos fora da cadeia Traefik → Coraza → Kong → Istio (Seção 6).
* **Observação – Dependência e ambientes air-gapped:**

  * Ao tornar o Tailscale mandatório para acesso seguro ao API Server e a recursos legados, a plataforma passa a **depender** de um serviço de Mesh VPN específico.

> **Guia para chats – Seção 5 (Rede, Mesh e GitOps)**
>
> * **1 – Desenvolvimento:**
>
>   * detalhar configuração do Istio (Gateways, VirtualServices, DestinationRules, Policies);
>   * descrever Argo CD em modelo App-of-Apps e Argo Workflows/Events para pipelines AI-First;
>   * especificar uso de Tailscale para clusters distribuídos.
> * **2 – Auditoria:**
>
>   * checar se há bypass da cadeia Traefik → Coraza → Kong → Istio;
>   * verificar se GitOps é de fato a “fonte de verdade” (dif entre Git e cluster).
> * **4 – Comercial:** explicar o ganho de governança (GitOps + Mesh VPN + Service Mesh) em relação a stacks ad-hoc.

---

## 6. Cadeia de Borda e Exposição de Serviços

(Seção resumida, mantendo alinhamento com Módulo 02)

* Cadeia de borda obrigatória:

  * **Traefik → Coraza (WAF) → Kong (API Gateway) → Istio → Serviços**.
* É **proibido**:

  * criar IngressRoute direto no Traefik para serviços internos;
  * expor serviços de negócio via `LoadBalancer`/`NodePort` ignorando a cadeia;
  * configurar upstreams ad-hoc que bypassam Kong/Istio.
* Toda exposição pública deve ser:

  * ancorada em hostnames e rotas declaradas em manifests versionados;
  * protegida por WAF, autenticação, autorização e observabilidade.

> **Guia para chats – Seção 6 (Cadeia de Borda)**
>
> * **1 – Desenvolvimento:** documentar:
>
>   * como cada suíte/serviço entra na cadeia (hostnames, paths, autenticação);
>   * padrões de roteamento (prefixos, headers, roteamento condicional).
> * **2 – Auditoria:** procurar:
>
>   * Ingress/IngressRoute não registrados em repositórios Git autorizados;
>   * exposições diretas de serviços Core/Apps na borda.
> * **4 – Comercial:** utilizar a cadeia de borda como argumento de segurança enterprise.

---

## 7. DR, Segurança de Infra e Continuidade

### 7.E Segurança de Infra e Continuidade

* **DR com Velero (obrigatório):**

  * Velero é o mecanismo padrão de backup/restore de:

    * recursos K8s (manifests);
    * volumes persistentes.
  * `BackupStorageLocation` deve usar **Object Storage externo ao cluster** (S3-compatível) e fisicamente separado de Ceph.
* **Snapshots CSI:**

  * workloads stateful devem usar `VolumeSnapshots` via driver CSI integrado ao Velero;
  * evita acoplamento a um único provedor de nuvem/storage.
* **Backups de segredos e metadados:**

  * segredos: protegidos pelo Vault (incluindo exportações criptografadas para DR);
  * manifests: protegidos em Git (com backup off-cluster).
* **Criptografia:**

  * **Em trânsito:** TLS na borda, mTLS interno (Istio).
  * **Em repouso:** criptografia em Ceph/Postgres com chaves geridas pelo Vault ou HSM.

> **Guia para chats – Seção 7.E (DR & Segurança de Infra)**
>
> * **1 – Desenvolvimento:** descrever:
>
>   * política de backup (frequência, retenção);
>   * cenários de restore em novo cluster.
> * **2 – Auditoria:** checar:
>
>   * existência de backups em Object Storage externo;
>   * testes de restauração periódicos.

---

## 8. Portal Unificado (Backstage)

Esta seção substitui a antiga ideia de uma PWA genérica como UI principal, reafirmando o Backstage como portal oficial da AppGear.

* **Tecnologia (obrigatória):** Backstage.
* **Função:** “Estúdio AppGear”, cockpit central.
* **Responsabilidades principais:**

  * catálogo de serviços, templates e plugins;
  * integração com Flowise/n8n para geração AI-First;
  * exibição de custos e consumo (OpenCost/Lago);
  * alertas de dependências (ex.: “recurso requer módulo Brain/Guardian”);
  * App Store interna (instalação de Add-ons).

> **Guia para chats – Seção 8 (Backstage)**
>
> * **1 – Desenvolvimento:** implementar plugins para:
>
>   * AI Dependency Alert;
>   * painel de custos/FinOps;
>   * App Store interna.
> * **4 – Comercial:** posicionar o Backstage como “Estúdio Inteligente” da plataforma.

---

## 9. Funcionalidades de produto (AI-First Ecosystem Generator)

A AppGear é um **AI-First Ecosystem Generator**, organizada em **4 Suítes Modulares**.

### 9.1. Regra de IA – Gateway Único (LiteLLM)

* Todo tráfego de LLM (OpenAI, Anthropic, Ollama, etc.) deve passar pelo **LiteLLM**, que é o **Gateway Único de IA** da plataforma.

* É **proibido** que serviços Core ou Add-ons:

  * instanciem SDKs diretos de provedores de LLM (por exemplo, `import openai` em Python, clientes nativos da Anthropic, etc.);
  * façam chamadas HTTP diretas para endpoints públicos de provedores de LLM (ex.: `https://api.openai.com/v1/...`);
  * gerenciem chaves de API de LLM fora do escopo controlado pelo LiteLLM (chaves soltas em `.env`, Secrets manuais, etc.);
  * ignorem o LiteLLM em qualquer fluxo de IA (runtime ou pipelines gerados).

* **Impacto em código gerado por IA (AppGear como gerador):**

  * Qualquer código gerado pela AppGear que:

    * faça `import openai` (ou equivalente para outro provedor);
    * configure diretamente `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` ou chaves similares;
    * chame diretamente os endpoints dos provedores de LLM,
      é considerado **não conforme** com este contrato.
  * A geração de código deve sempre:

    * usar o **endpoint interno do LiteLLM** (ex.: `LITELLM_BASE_URL`, `LITELLM_API_KEY` ou variáveis equivalentes);
    * tratar o LiteLLM como **única dependência** para acesso a modelos de linguagem, embeddings, chat, etc.

* **Motivações (FinOps, Segurança e Auditoria):**

  * Centralizar no LiteLLM:

    * o **controle de custos** (billing consolidado por tenant/workspace/suite);
    * a **lista de modelos autorizados** (whitelist corporativa);
    * logs de prompts/respostas para fins de **auditoria e conformidade** (LGPD, políticas internas);
    * políticas de uso (limites, quotas, fallback entre provedores).
  * Evitar:

    * chaves de provedores espalhadas em múltiplos serviços, repositórios ou `.env`;
    * políticas de segurança e limites de uso divergentes;
    * observabilidade fragmentada de uso de IA.

* Violações a esta regra são tratadas como **quebra de contrato de arquitetura** e devem ser apontadas em **2 – Auditoria**, com plano explícito de correção (refactor para uso de LiteLLM).

### 9.2. Níveis de geração

* **Nível 1 – Fundamentos:**

  * Geração de estruturas básicas (APIs, DB, UI simples).
* **Nível 2 – Industrialização:**

  * Conecta geração à esteira GitOps, testes e observabilidade.
* **Nível 3 – Full Ecosystem por Suítes:**

  * Ativa componentes das **4 Suítes**, compondo um ecossistema completo (ERP, E-commerce, CRM, IoT, etc.).
* **Nível 4 – Deploy Híbrido:**

  * Orquestra cargas em **Edge** via KubeEdge (RPA, IoT, Digital Twins).

### 9.3. Suíte 1 – AppGear Factory (Núcleo de Construção)

* Geração de:

  * código backend;
  * frontends (incluindo PWA, Tailwind + shadcn/ui);
  * mobile (React Native);
  * desktop (Tauri).
* CDEs (VS Code Server) com integração ao Vault.
* Engenharia reversa de bancos legados (Airbyte + n8n).

### 9.4. Suíte 2 – AppGear Brain (Inteligência de Negócios)

* **Corporate Brain:** RAG-as-a-Service usando:

  * Qdrant (vetores);
  * Meilisearch (texto).
* **AI Workforce:** Agentes Autônomos (CrewAI/AutoGen) orquestrados via Flowise e LiteLLM.
* **AutoML Studio:** construção de modelos preditivos no-code.

### 9.5. Suíte 3 – AppGear Operations (Físico & Processos)

* **Digital Twins & Geo-Ops:** ThingsBoard + PostGIS.
* **RPA:** automação de sistemas sem API.
* **Real-Time Action Center:** decisões baseadas em eventos (Redpanda).
* **API Economy:** monetização de APIs (Kong + Lago).

### 9.6. Suíte 4 – AppGear Guardian (Governança & Segurança)

* **Compliance:** IGA (midPoint), governança de acessos.
* **Security Suite:** Pentest AI, Browser Isolation, monitoramento.
* **Resilience-as-a-Service:** Chaos Engineering aplicado.
* **Legal AI:** Tika + Gotenberg, geração de SBOM e revisão contratual.

> **Guia para chats – Seção 9 (Funcionalidades)**
>
> * **1 – Desenvolvimento:** implementar scripts de geração (n8n/Flowise) garantindo uso exclusivo de LiteLLM como gateway de IA, inclusive para **código gerado** (sem `import openai` direto, sempre apontando para o endpoint do LiteLLM).
> * **2 – Auditoria:** validar:
>
>   * uso de LiteLLM em todos os fluxos de IA (serviços e código gerado);
>   * segurança e isolamento dos CDEs, Agentes e fluxos RAG.
> * **4 – Comercial:** mapear pacotes/planos baseados nas 4 Suítes e nos Níveis 1–4.

---

## 10. Documentos oficiais e versionamento

Documentos oficiais da AppGear:

* **0 – Contrato v0** (este documento).
* **1 – Desenvolvimento v0.x** (módulos técnicos M00–M17).
* **2 – Auditoria v0** (checklist de conformidade).
* **3 – Interoperabilidade v0** (fluxos e integrações).
* **4 – Comercial v0** (escopo de oferta e limites).

Regras de versionamento:

* Alterações **estruturais** (ex.: inclusão de novo componente Core, mudança de topologia, mudança no papel do LiteLLM) exigem **nova versão do Contrato (v1, v2...)**.
* Mudanças **operacionais ou exemplificativas** devem ser refletidas em:

  * 1 – Desenvolvimento;
  * 2 – Auditoria;
  * 3 – Interoperabilidade;
  * 4 – Comercial.

> **Guia para chats – Seção 10 (Documentos e versionamento)**
>
> * **0 – Contrato:** usar esta seção para decidir quando uma mudança de arquitetura exige v1.
> * **1 – Desenvolvimento / 2 – Auditoria / 3 – Interoperabilidade / 4 – Comercial:** manter alinhamento de versões com o Contrato.

---

## 11. Restrições & Pontos de Atenção

(Resumo dos principais riscos arquiteturais)

* Uso de Topologia A em produção.
* Bypass da cadeia Traefik → Coraza → Kong → Istio.
* Chamadas diretas a provedores de LLM, ignorando LiteLLM.
* Falta de multi-tenancy lógico (`tenant_id`, `workspace_id`) em serviços compartilhados.
* Falta de DR (Velero) ou de testes de restore.
* Falta de labels `appgear.io/*` em workloads core.

> **Guia para chats – Seção 11 (Restrições & Pontos de Atenção)**
>
> * **0 – Contrato:** usar esta seção para julgar pedidos de exceção e decidir se exigem v1 ou apenas detalhamento em 1 – Desenvolvimento.
> * **1 – Desenvolvimento:** tratar multi-tenancy lógico, LiteLLM e Tailscale como temas sensíveis, com documentação e testes reforçados.
> * **2 – Auditoria:** considerar estes pontos de atenção como “itens quentes” nos checklists de v0.

---

## 12. Itens deliberadamente delegados ao 1 – Desenvolvimento

O documento **1 – Desenvolvimento v0** deve detalhar, no mínimo:

* **Arquitetura K8s e Scale-to-Zero:**

  * manifests de KEDA (`ScaledObjects`) para Add-ons;
  * **Scale-to-Zero como padrão** para workloads core e add-ons pesados (Keycloak/midPoint, gateways Ceph, ingress/sidecars Istio, ELK/Loki), com `minReplicaCount: 0`, `pollingInterval` otimizado para dev/pequeno porte e `cooldownPeriod` curto documentado;
  * triggers oficiais (HTTP, fila, métricas de uso) configurados como valores **default** em `values.yaml`/`kustomization.yaml`, evitando flags opcionais que desativem o KEDA;
  * configuração de pods de VS Code Server (CDEs) com Vault.
* **Rede e Mesh:**

  * configuração detalhada de Istio;
  * gateways, virtual services, policies.
* **DR e Backup:**

  * configuração de Velero e VolumeSnapshots CSI;
  * cenários de restore.
* **Backstage e plugins:**

  * App Store interna;
  * AI Dependency Alert;
  * integração com Flowise/n8n.
* **Integração de Suítes:**

  * fluxos para Factory/Brain/Operations/Guardian;
  * uso de Tailscale para integrações legadas.

> **Guia para chats – Seção 12 (Delegado ao 1 – Desenvolvimento)**
>
> * **1 – Desenvolvimento:** priorizar o setup de KEDA, Tailscale, Velero e plugins críticos do Backstage.
> * **2 – Auditoria:** incluir verificação de Scale-to-Zero, segurança dos CDEs, DR efetivo e uso correto de LiteLLM/Tailscale.

---

**Fim do Contrato de Arquitetura AppGear.**
