# AppGear

Este repositório centraliza a documentação oficial de arquitetura da plataforma **AppGear**, incluindo o **Contrato de Arquitetura v0** e os documentos derivados de desenvolvimento, auditoria e interoperabilidade.

A AppGear é uma plataforma de **construção de ecossistemas de negócios orientada por IA**, focada em geração **AI-First** ponta a ponta (Backend, Frontend, BI e processos), modularidade via 4 Suítes e eficiência de nuvem via **Scale-to-Zero (KEDA)**.

---

## Visão geral

O **0 – Contrato de Arquitetura** é a **fonte da verdade arquitetural** da AppGear. Ele estabelece regras obrigatórias para:

- Stack de infraestrutura **Core** e **Add-ons** (Kubernetes, GitOps, Service Mesh, Storage, DR).
- Serviços de dados, IA, automação, UI e SSO.
- Governança (Segurança, Identidade, FinOps, API).
- Industrialização (CI/CD, GitOps Nível 3, Observabilidade).
- Funcionalidades de produto organizadas em 4 Suítes:
  - **Factory**, **Brain**, **Operations**, **Guardian**.

Este README serve como porta de entrada para quem precisa **entender, evoluir ou auditar** a arquitetura da AppGear, agora acompanhado de um fluxo CI/CD com **validação automatizada por IA** documentado em `guides/ai-ci-cd-flow.md` e pelo **Procedimento Operacional – Aplicação das Melhorias no Pipeline CI/CD (v1.1)**.

## Estado atual

- Toda a documentação (Contrato, Auditoria, Interoperabilidade e módulos 00–17) está sincronizada com o retrofit v0.3 sem introduzir novas capacidades além do previsto.
- **Linha v0** permanece estável como fonte de verdade; retrofits **v0.3** dos módulos 00–17 seguem o `development/v0.3/stack-unificada-v0.3.yaml` sem adicionar novas funcionalidades.
- **Interoperabilidade** reforça a cadeia Traefik → Coraza → Kong → Istio (mTLS STRICT), LiteLLM como gateway de IA e KEDA para cargas não 24/7.
- **Pipeline**: publicações em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` com hashes SHA-256 e parecer automatizado da IA + RAPID/CCB (ver `guides/ai-ci-cd-flow.md` e `guides/integrated-report-procedure.md`).

---

## Documentos oficiais

A família de documentos é organizada em 4 blocos principais, todos em `docs/` e `development/`:

- `docs/architecture/contract/contract-v0.md` – Contrato de Arquitetura (documento de referência principal).
- `development/{v0,v0.1,v0.2}/module-XX-v*.md` – Implantação técnica por módulos (00 a 17) por linha de versão.
- `docs/architecture/audit/audit-v0.md` – Checklist de aderência ao contrato.
- `docs/architecture/interoperability/interoperability-v0.md` – Parecer sobre integrações entre serviços.

Complementos de governança e operação:

- `guides/integrated-report-procedure.md` – norma interna v1.1 que impõe validação automatizada por IA no pipeline.
- `guides/ai-ci-cd-flow.md` – fluxo operacional para aplicar o procedimento em todos os pipelines, com estrutura `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` e gate de decisão da IA.

Mapa da árvore atualizada:

```text
appgear-docs/
  docs/architecture/contract/contract-v0.md
  docs/architecture/audit/audit-v0.md
  docs/architecture/interoperability/interoperability-v0.md
  development/v0/module-00-v0.md
  development/v0.1/module-00-v0.1.md
  development/v0.2/module-00-v0.2.md
  development/v0.3/core-module-v0.3.md
```

---

## Stack padrão (resumo executivo)

O contrato define um **Stack Core** obrigatório e um conjunto de **Add-ons por Suíte**.

### Stack Core – Infraestrutura e Governança

Principais componentes (Topologia B – Kubernetes):

- **Portal & Governança**
  - Backstage (portal unificado / estúdio).
- **Rede e Malha**
  - Traefik (Ingress TLS), Coraza (WAF), Kong (API Gateway), Istio (Service Mesh com mTLS).
- **Segurança**
  - Vault (segredos), OpenFGA (autorização fina), OPA (Policy-as-Code), Falco (runtime).
- **Identidade & IGA**
  - Keycloak (SSO IdP único), midPoint (IGA).
- **Conectividade Híbrida**
  - Tailscale Kubernetes Operator (Mesh VPN).
- **Escalonamento**
  - KEDA (Scale-to-Zero obrigatório para Add-ons não 24/7).
- **Storage & Dados Core**
  - Ceph (objeto/bloco/arquivo), Postgres/PostGIS, Redis, Qdrant.
- **Mensageria**
  - RabbitMQ (fila), Redpanda (streaming).
- **Observabilidade & FinOps**
  - Prometheus, Loki, Grafana, OpenCost, Lago.

### Stack Core – Serviços de Aplicação Base

- **IA Generativa**
  - Ollama, Flowise, **LiteLLM como gateway único de IA**.
- **Automação e Processos**
  - n8n (automação), engine BPMN (processos humanos).
- **Dados e UI Base**
  - Directus (SSoT de dados), Appsmith (frontends internos), Metabase (BI).
- **Busca Corporativa**
  - Meilisearch (texto), integrado a Qdrant (vetores) e à Suíte Brain.

### Stack Add-on – Suítes de Negócio

- **Suíte 1 – Factory**
  - ERP, E-commerce, CRM, Atendimento, CDEs (VS Code Server), geração de apps nativos (React Native/Tauri).
- **Suíte 2 – Brain**
  - RAG, Agentes (AI Workforce), AutoML Studio, Corporate Brain.
- **Suíte 3 – Operations**
  - Digital Twins & Geo-Ops (ThingsBoard + PostGIS), RPA, Real-Time Action Center, API Economy (Kong + Lago).
- **Suíte 4 – Guardian**
  - Security Suite (Pentest AI, Browser Isolation), Resilience (Chaos), Legal AI (Tika + Gotenberg, SBOM), governance avançada de IGA/FinOps.

---

## Topologias de implantação

O contrato define duas topologias oficiais:

### Topologia A – Docker Compose (Teste / Legacy)

- Objetivo: demos locais, PoC e ambientes de teste.
- Características:
  - `docker-compose.yml` único ou segmentado.
  - `.env` central apenas para **testes**.
- Limitações:
  - Não suporta plenamente Istio, vCluster, Ceph, Argo, KEDA, Tailscale.
  - **Não é suportada para produção em clientes.**

### Topologia B – Kubernetes “Business Ecosystem” (Padrão / Enterprise)

- Objetivo: entrega enterprise multi-tenant, segura, auditável e FinOps.
- Pilares:
  - Kubernetes + GitOps via Argo (Events/Workflows/CD, App-of-Apps).
  - Istio Service Mesh com mTLS obrigatório.
  - **vCluster por Workspace** (hard multi-tenancy).
  - Ceph como backend de storage.
  - KEDA para Scale-to-Zero dos Add-ons.
  - Tailscale para conectividade híbrida.
  - LiteLLM como gateway único de modelos de IA.

#### Modelo de multi-tenancy

- **Hierarquia oficial:**
  - `tenant_id` → agrupa Workspaces.
  - `workspace_id` → unidade de produto/projeto.
  - `vCluster` → unidade de execução isolada associada a um `workspace_id`.
- Serviços pesados podem operar em modo **multi-tenant lógico** (por ambiente), desde que haja:
  - fronteiras rígidas por `tenant_id` em queries/pipelines;
  - segregação por schema/namespace;
  - controles de autorização em camada de aplicação (Keycloak/OpenFGA);
  - testes de não vazamento entre tenants.

---

## Estrutura de repositórios (recomendação)

O contrato sugere a seguinte organização mínima de repositórios Git para Topologia B:

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
  ```

Este repositório (onde este README reside) normalmente corresponde ao **`appgear-docs`** ou a um monorepo equivalente, contendo a estrutura raiz de pastas.

---

## Como navegar pela documentação

Sugestão de leitura/uso:

1. **Comece em `0-Contrato`**
   Entenda o produto (Business Ecosystem Generator), as Suítes, o Stack Core/Add-on, Topologias A/B, multi-tenancy e restrições estruturais.

2. **Vá para `1-Desenvolvimento`**
   Veja como o contrato é implementado em **módulos 00–17** (GitOps, Service Mesh, Storage, Segurança, Suítes etc).

3. **Use `2-Auditoria`**
   Para validar se um ambiente ou implantação está aderente ao contrato (checklist técnico).

4. **Consulte `3-Interoperabilidade`**
   Quando precisar entender integrações entre serviços (por exemplo, Backstage ↔ Flowise ↔ N8n ↔ Suítes).

---

## Como propor mudanças na arquitetura

Alterações na arquitetura seguem um fluxo formal:

1. Abrir uma **Issue** do tipo “Proposta de alteração do 0 – Contrato”.
2. Discutir impactos técnicos, de produto e de governança.
3. Abrir um **Pull Request** alterando `0-Contrato-vX.md`.
4. Obter aprovação das pessoas responsáveis por Arquitetura/Governança.
5. Criar nova **tag Git** (`contract-v1`, `contract-v2`, …) e atualizar a versão no cabeçalho do arquivo.

Enquanto isso não ocorre, **a versão `v0` permanece como referência obrigatória**.

---

## Versionamento

- Versões principais: `v0`, `v1`, `v2`, ...  
- Tags recomendadas no Git: `contract-v0`, `contract-v1`, ...  
- Este repositório deve deixar claro, no README e no cabeçalho do contrato, **qual versão está vigente**.

---

## Público-alvo

Este repositório é direcionado a:

- Arquitetos de software e de plataforma.
- Engenheiros de infraestrutura / SRE / DevOps.
- Times de produto responsáveis por AppGear.
- Auditores técnicos e consultores de segurança.
- Parceiros e integradores que precisam aderir ao contrato da plataforma.

---

> Em caso de dúvida de design ou decisão arquitetural, consulte sempre primeiro o **0 – Contrato** em sua versão vigente antes de alterar código ou manifests.
