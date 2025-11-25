# Diretriz de Interoperabilidade AppGear

> [!IMPORTANT]
> **DIRETRIZ OFICIAL DE INTEROPERABILIDADE DA APPGEAR – FONTE NORMATIVA ÚNICA**  
>  
> Este documento define **como os módulos, serviços Core e Suítes da AppGear se integram** em qualquer implantação da plataforma:  
> - adoção obrigatória do **Stack Core** e das **Suítes** (Factory, Brain, Operations, Guardian) definidos no Contrato v0;  
> - uso da cadeia de borda oficial **Traefik → Coraza (WAF) → Kong → Istio (mTLS STRICT)** para expor serviços;  
> - uso de **LiteLLM como gateway único de IA**, proibindo chamadas diretas a provedores de LLM;  
> - tratamento explícito de **Topologia A** (Docker / PoC) e **Topologia B** (Kubernetes / produção);  
> - respeito ao modelo de **multi-tenancy** (tenant, workspace, vCluster) em todas as integrações.  

Versão normativa: v0  
Linha de revisão ativa: v0.3  

---

## 1. O que é

A Diretriz de Interoperabilidade AppGear define **como os componentes da plataforma conversam entre si**:

- serviços do **Stack Core** (rede, segurança, dados, IA, automação, observabilidade, DR);
- **Suítes** (Factory, Brain, Operations, Guardian);
- **módulos 00–17** de Desenvolvimento (v0/v0.3);
- ambientes em **Topologia A** (Docker / PoC / Dev) e **Topologia B** (Kubernetes / Enterprise).

Ela funciona como um documento **horizontal**, que:

- descreve o **mapa global de integrações** (Core ↔ Suítes ↔ módulos ↔ ambientes);
- estabelece **padrões de documentação** (mapa-global, modulos.yaml, fluxos-ai-first);
- define a **cadeia oficial de borda** e o uso de LiteLLM, Vault, vClusters, etc.;
- serve de base para a **Diretriz de Auditoria** verificar integrações e detectar Shadow IT.

### 1.1. Atualização v0.3 (consolidação)

Na linha v0.3 foram consolidadas as seguintes decisões:

- **Premissas compartilhadas**: centralizadas em `development/v0.3/core-module-v0.3.md`.  
  Todos os módulos v0.x devem referenciar esse arquivo e remover textos duplicados.
- **Pipeline oficial de borda**:

  ```text
  [Traefik (TLS passthrough SNI)] -> [Coraza WAF] -> [Kong Gateway] -> [Istio IngressGateway] -> [Service Mesh]
```

Esta cadeia é **obrigatória** para expor qualquer serviço Core ou Suite, mantendo TLS passthrough até o Istio IngressGateway e **mTLS STRICT** dentro da malha.

* **Normalização TLS/mTLS**:
  O padrão oficial mantém:

  * TLS apenas entre bordas (Traefik → Coraza → Kong);
  * passthrough até o Istio IngressGateway;
  * **mTLS STRICT** dentro da malha Istio.
* **ApplicationSets obrigatórios**:
  Novos apps e migrações devem usar templates de **ApplicationSet**, evitando `Application` isolado fora do App-of-Apps.
* **Manifesto único de stack**:
  `development/v0.3/stack-unificada-v0.3.yaml` consolida namespaces, dependências e ordem de borda para Topologias A e B.
* **Baseline de retrofit**:
  Todas as correções em módulos e documentos de interoperabilidade devem referenciar `stack-unificada-v0.3.yaml` como **tabela de verdade** de dependências, namespaces e pipeline de borda.

A **linha v0** permanece a referência normativa; a **linha v0.3** consolida o retrofit previsto, sem adicionar serviços fora do Stack oficial.

---

## 2. Por que

Os principais motivos desta diretriz são:

1. **Garantir coerência com o Stack Core da AppGear**
   O Contrato v0 define um Stack Core obrigatório (rede, segurança, dados, IA, automação, observabilidade, FinOps, DR).
   A Interoperabilidade v0 garante que **todas as integrações usem esses componentes**, evitando stacks paralelas e soluções isoladas.

2. **Evitar Shadow IT e acoplamentos indevidos**
   Sem uma diretriz única, é comum:

   * cada módulo subir sua própria stack para problemas já resolvidos no Core;
   * integrações banco-a-banco entre Suítes;
   * bypass da cadeia Traefik → Coraza → Kong → Istio;
   * chamadas diretas a provedores de LLM, ignorando o LiteLLM.
     Esta diretriz padroniza **o caminho oficial** de comunicação e dependências.

3. **Tratar multi-tenancy e vClusters como requisitos centrais**
   A arquitetura AppGear exige:

   * `tenant_id` e `workspace_id` coerentes em todos os fluxos;
   * **vCluster por workspace** como unidade de isolamento forte (Topologia B);
   * multi-tenancy lógico em serviços compartilhados (bancos, filas, índices).
     A Interoperabilidade v0 descreve **como a multi-tenancy aparece nas integrações** (schemas, tópicos, índices, buckets, claims de identidade).

4. **Conectar o ecossistema AI-first ponta a ponta**
   Backstage, Flowise, LiteLLM, n8n, RAG, agentes, Suítes e stack de dados precisam se integrar via:

   * HTTP (Kong/Istio);
   * eventos (Redpanda/RabbitMQ);
   * dados (Postgres, Qdrant, Ceph, Meilisearch);
   * segredos (Vault);
   * observabilidade/FinOps.
     Esta diretriz formaliza **fluxos AI-first ponta a ponta**.

5. **Reduzir risco em clientes enterprise (Topologia B)**
   Ambientes com múltiplos tenants e workspaces dependem de integrações previsíveis e auditáveis.
   Uma diretriz clara reduz surpresas em produção e suporta **auditorias técnicas** e de conformidade.

---

## 3. Pré-requisitos

### 3.1. Documentos

Antes de aplicar esta diretriz, é necessário ter acesso a:

* `docs/architecture/contract/contract-v0.md` – Contrato de Arquitetura AppGear v0;
* `docs/architecture/audit/audit-v0.md` – Diretriz de Auditoria;
* `docs/architecture/interoperability/interoperability-v0.md` – este documento;
* `STATUS-ATUAL.md` – visão consolidada da linha v0/v0.3;
* `development/v0/module-XX-v0.md` – módulos 00–17 (baseline original);
* `development/v0.3/core-module-v0.3.md` – visão consolidada da linha v0.3;
* `development/v0.3/module-XX-v0.3.md` – módulos retrofitados;
* `development/v0.3/stack-unificada-v0.3.yaml` – stack unificada por serviço/componente.

### 3.2. Repositórios

Acesso de leitura, no mínimo, a:

* `appgear-docs` – documentação e artefatos de interoperabilidade;
* `appgear-infra-core` – GitOps do Stack Core;
* `appgear-suites` – GitOps das Suítes;
* `appgear-backstage` – portal e plugins;
* `appgear-workspace-template` – template GitOps por workspace.

Convenções:

* Prefixo de repositórios: `appgear-*`;
* Raiz local para Topologia A: `/opt/appgear`;
* Rede Docker padrão (quando utilizada): `appgear-net-core`.

### 3.3. Ambientes

**Topologia A (Docker / PoC / Dev)**

* host com `/opt/appgear` contendo:

  * `.env` (sem segredos de produção);
  * `docker-compose.yml`;
  * `config/`, `data/`, `logs/`.

**Topologia B (Kubernetes / Enterprise)**

* cluster com:

  * Argo CD (GitOps);
  * Istio com mTLS STRICT;
  * vClusters por workspace;
  * Vault/ExternalSecrets;
  * KEDA (Scale-to-Zero);
  * Tailscale (quando aplicável).

### 3.4. Pessoas

* responsável de Arquitetura / Plataforma;
* engenheiros responsáveis por módulos (M00–M17);
* Segurança / Governança;
* Produto / Comercial (para novas integrações e SLAs).

---

## 4. Como fazer (comandos)

Esta seção define o **procedimento padrão** para documentar e manter a interoperabilidade da AppGear, com comandos de exemplo.

### 4.1. Passo 1 – Estruturar arquivos de interoperabilidade

No repositório de documentação AppGear:

```bash
cd AppGear

mkdir -p docs/architecture/interoperability/resources

touch docs/architecture/interoperability/resources/mapa-global.md
touch docs/architecture/interoperability/resources/modulos.yaml
touch docs/architecture/interoperability/resources/fluxos-ai-first.md
```

Localização oficial deste documento:

```text
docs/architecture/interoperability/interoperability-v0.md
```

Arquivos auxiliares:

* `mapa-global.md` – mapa global Core x Suítes;
* `modulos.yaml` – matriz de interoperabilidade por módulo;
* `fluxos-ai-first.md` – fluxos AI-first ponta a ponta.

---

### 4.2. Passo 2 – Mapa global Core x Suítes (`mapa-global.md`)

No arquivo `docs/architecture/interoperability/resources/mapa-global.md`, documente:

1. **Stack Core (infra & governança)**
   Ex.:

   * Portal: Backstage;
   * Rede/borda: Traefik, Coraza, Kong, Istio, Tailscale;
   * Segurança: Vault, OpenFGA, OPA, Falco, Coraza;
   * Dados: Ceph, Postgres/PostGIS, Redis, Qdrant, Redpanda, RabbitMQ;
   * Observabilidade/FinOps: Prometheus, Grafana, Loki, OpenCost, Lago;
   * IA & Automação: Ollama, LiteLLM, Flowise, n8n, BPMN;
   * Legal/Compliance: Tika, Gotenberg, SignServer.

2. **Stack Add-on (Suítes)**

   * **Factory** – CDEs, Airbyte, integrações ERP/E-commerce/CRM;
   * **Brain** – RAG, Corporate Brain, AI Workforce, AutoML;
   * **Operations** – IoT, Digital Twins, RPA, Edge/KubeEdge, Action Center;
   * **Guardian** – Security Suite, Legal AI, Chaos, Governança da App Store.

Para cada componente, registre:

* nome lógico (ex.: `core-postgres`, `addon-factory-vscode`);
* interfaces:

  * HTTP: via Kong/Istio;
  * eventos: via Redpanda/RabbitMQ;
  * dados: via serviços de acesso (APIs/DAOs), não diretamente nos bancos;
* tipo de tenancy:

  * isolado por vCluster;
  * ou multi-tenant lógico com isolamento forte.

---

### 4.3. Passo 3 – Matriz de interoperabilidade por módulo (`modulos.yaml`)

No arquivo `docs/architecture/interoperability/resources/modulos.yaml`, para **cada módulo** MXX de Desenvolvimento, defina um bloco, por exemplo:

```yaml
- modulo: "M08 – Serviços de Aplicação Core"
  id: "M08"
  suite: "Core"
  topologias:
    - A
    - B
  usa_core:
    - core-postgres
    - core-redis
    - core-qdrant
    - core-ceph
  usa_suites:
    - factory
    - brain
  integra_com:
    http:
      - nome: "Directus"
        via: "core-kong"
        prefixo: "/directus"
        cadeia: "traefik -> coraza -> kong -> istio -> core-directus"
      - nome: "Appsmith"
        via: "core-kong"
        prefixo: "/appsmith"
    eventos:
      produz:
        - broker: "core-redpanda"
          topico: "appgear.core.m08.evento-exemplo"
      consome:
        - broker: "core-redpanda"
          topico: "appgear.factory.cde.*"
    dados:
      le_de:
        - "core-postgres (schema appgear_core)"
      escreve_em:
        - "core-postgres (schema appgear_core)"
  tenancy:
    tipo: "hard-multi-tenant"
    workspace_isolado_por: "vcluster"
    observa_multi_tenancy_logico:
      - "nao"
  seguranca:
    sso: "keycloak"
    autorizacao: "openfga"
    segredos: "vault"
  observabilidade:
    metrics: "prometheus"
    logs: "loki"
```

Recomendações:

* Criar bloco semelhante para **todos** os módulos M00–M17;
* Garantir que:

  * nenhuma integração chame LLMs diretamente (sempre via LiteLLM);
  * não haja acesso direto a bancos sensíveis ignorando serviços/APIs oficiais;
  * nomes lógicos de serviços sejam consistentes com `development/v0.3` e `stack-unificada-v0.3.yaml`.

---

### 4.4. Passo 4 – Fluxos ponta a ponta (`fluxos-ai-first.md`)

No arquivo `docs/architecture/interoperability/resources/fluxos-ai-first.md`, formalize pelo menos:

1. **Fluxo AI-First Ecosystem Generator**
   Exemplo de cadeia:

   * Backstage → n8n/BPMN → Flowise → LiteLLM → Argo CD → vCluster → Suítes.

   Documentar:

   * quem chama quem, por qual interface (HTTP, eventos, jobs);
   * como `tenant_id` e `workspace_id` fluem nas chamadas;
   * pontos em que entram:

     * Vault (segredos);
     * Qdrant (vetores);
     * Meilisearch (busca);
     * Redpanda/RabbitMQ (eventos).

2. **Fluxo de DR/Backup e restauração**

   * Velero / snapshots CSI / restore;
   * como dados de Core e Suítes são restaurados sem quebrar integrações com:

     * identidade (Keycloak/OpenFGA);
     * observabilidade;
     * workspaces/vClusters.

3. **Fluxos Edge / KubeEdge**

   * Nuvem (Core/Suítes) ↔ Edge (IoT/RPA);
   * como telemetria retorna ao Core;
   * como identidade e `tenant_id` são mantidos em dispositivos.

---

### 4.5. Passo 5 – Topologia A x Topologia B

Registrar diferenças de interoperabilidade entre:

**Topologia A (Docker / PoC / Dev)**

* `docker-compose.yml` em `/opt/appgear` deve:

  * usar nomes lógicos equivalentes (`core-*`, `addon-*`);
  * manter **rotas por prefixo** (`/directus`, `/appsmith`, `/n8n`, `/flowise`, `/metabase`);
  * centralizar variáveis em `.env` (sem segredos de produção).

**Topologia B (Kubernetes / Enterprise)**

* Serviços correspondentes na pilha Core devem:

  * existir com papéis equivalentes;
  * preservar, tanto quanto possível, o mesmo shape de rotas/APIs;
* Documentar:

  * diferenças por integração (autenticação, segurança, performance);
  * funcionalidades apenas disponíveis em Topologia B.

---

### 4.6. Passo 6 – Multi-tenancy e isolamento

Para serviços **multi-tenant lógicos** (Directus multi-tenant, Redpanda, Qdrant, Meilisearch, etc.):

* No `modulos.yaml`, descrever:

  * escopo de isolamento (por tenant, por workspace, misto);
  * como `tenant_id` e `workspace_id` aparecem em:

    * schemas/tabelas (Postgres);
    * índices/buckets (Qdrant, Ceph);
    * tópicos/filas (Redpanda/RabbitMQ);
    * coleções/índices (Meilisearch).

Definir testes esperados de **não vazamento**:

* consultas tentando acessar dados de outro tenant;
* eventos com IDs cruzados;
* tokens sem claims corretas de workspace.

A Diretriz de Auditoria deve usar esses cenários como base para checagens.

---

### 4.7. Passo 7 – Revisão por release

Para cada release (ex.: `v0.2.0`, `v0.3`):

* Atualizar:

  * `mapa-global.md`;
  * `modulos.yaml`;
  * `fluxos-ai-first.md`.

Verificar se:

* toda nova Suíte ou módulo aparece na matriz de interoperabilidade;
* fluxos AI-first críticos estão documentados;
* alterações em `development/v0.3` e `stack-unificada-v0.3.yaml` foram refletidas aqui.

Registrar, ao final deste documento, um **changelog de interoperabilidade** com:

* versão;
* mudanças principais;
* módulos/sistemas impactados.

---

## 5. Como verificar

### 5.1. Verificação da própria diretriz

A Diretriz de Interoperabilidade é considerada **OK** quando:

1. **Mapa Global**

   * todos os componentes Core do Contrato v0 aparecem em `mapa-global.md`;
   * todas as Suítes (Factory, Brain, Operations, Guardian) estão descritas.

2. **Matriz de Módulos**

   * todos os módulos M00–M17 aparecem em `modulos.yaml`;
   * cada módulo registra:

     * `usa_core`;
     * `usa_suites`;
     * `integra_com` (HTTP, eventos, dados);
     * `tenancy`, `seguranca`, `observabilidade`.

3. **Fluxos AI-first e críticos**

   * fluxos AI-first, DR/Backup e Edge estão formalizados em `fluxos-ai-first.md`.

4. **Integração com Auditoria**

   * a Diretriz de Auditoria (`audit-v0.md`) referencia esta diretriz para:

     * checar cadeia de borda oficial;
     * detectar Shadow IT;
     * validar multi-tenancy e uso correto de LiteLLM, Vault, etc.

### 5.2. Uso em análises de impacto

Ao propor uma nova integração ou alterar uma existente:

1. Validar no **Contrato v0** se ela é compatível com a arquitetura vigente;
2. Atualizar:

   * `mapa-global.md`;
   * `modulos.yaml`;
   * `fluxos-ai-first.md`;
3. Verificar se algum módulo em `development/v0.3` precisa de ajuste na seção de “Integrações e Dependências”.

---

## 6. Erros comuns

Principais erros a evitar:

1. **Integrar diretamente com bancos, filas ou LLMs sem passar pelos serviços Core**
   Ex.: acesso direto ao provider de LLM ignorando LiteLLM, ou acesso direto a banco ignorando serviços/APIs oficiais.

2. **Não documentar dependências no `modulos.yaml`**
   Criando serviços “órfãos”, sem visibilidade de quem depende de quem.

3. **Confundir Topologia A (PoC) com produção**
   Tomar suposições de Docker Compose como se fossem válidas para Topologia B em produção.

4. **Ignorar multi-tenancy lógico em serviços compartilhados**
   Levando a risco de vazamento de dados entre tenants/workspaces.

5. **Atualizar módulos e Suítes sem atualizar os artefatos de interoperabilidade**
   Omitindo mudanças em:

   * `interoperability-v0.md`;
   * `mapa-global.md`;
   * `modulos.yaml`;
   * `fluxos-ai-first.md`.

6. **Bypass da cadeia de borda oficial**
   Expor serviços diretamente via `LoadBalancer`/`NodePort` ou Ingress fora de Traefik → Coraza → Kong → Istio.

7. **Chamadas diretas a provedores de LLM**
   Código acessando `api.openai.com` (ou equivalentes) sem passar por LiteLLM.

---

## 7. Onde salvar

Este documento deve ser mantido em:

```text
docs/architecture/interoperability/interoperability-v0.md
```

Arquivos relacionados:

```text
docs/architecture/contract/contract-v0.md
docs/architecture/audit/audit-v0.md
development/v0/module-XX-v0.md
development/v0.3/core-module-v0.3.md
development/v0.3/module-XX-v0.3.md
development/v0.3/stack-unificada-v0.3.yaml
docs/architecture/interoperability/resources/mapa-global.md
docs/architecture/interoperability/resources/modulos.yaml
docs/architecture/interoperability/resources/fluxos-ai-first.md
```

Em repositórios externos (clientes/parceiros), recomenda-se:

* manter o mesmo nome de arquivo (`interoperability-v0.md`);
* referenciar explicitamente qual **Contrato v0** está sendo seguido.

### 7.1. Relação com outros documentos

* **Contrato de Arquitetura v0**
  Define Topologias A/B, Stack Core/Add-on, multi-tenancy, visão AI-first.
  A Interoperabilidade v0 **implementa** essa visão no nível das integrações concretas.

* **Diretriz de Auditoria v0**
  Usa esta diretriz como base para:

  * detectar bypass da cadeia de borda;
  * encontrar Shadow IT;
  * validar uso de LiteLLM, Vault, Core de dados e observabilidade.

* **Desenvolvimento (módulos 00–17)**
  Cada módulo deve ter seção de “Integrações e Dependências” coerente com:

  * `modulos.yaml`;
  * `fluxos-ai-first.md`;
  * `stack-unificada-v0.3.yaml`.

### 7.2. Histórico (não normativo)

Versões antigas, rascunhos e linhas descontinuadas desta diretriz devem ser movidas para:

```text
archive/interoperability/
```

Regras:

* nada em `archive/**` é considerado **vigente**;
* quando houver nova versão (ex.: `interoperability-v1.md`), este arquivo deve ser movido para `archive/interoperability/interoperability-v0-old.md` ou equivalente, preservando o histórico.

---

> [!IMPORTANT]
> **Esta Diretriz de Interoperabilidade é a referência oficial para todas as integrações AppGear.**
>
> * O **Contrato v0** define as decisões estruturais;
> * a **Interoperabilidade v0** define **como os componentes se conectam** (mapas, matrizes, fluxos);
> * a **Diretriz de Auditoria v0** define **como verificar** se essas integrações estão corretas em código e em ambiente.
>
> Qualquer mudança relevante na forma como os serviços se integram deve ser tratada como **evolução de diretriz** (por exemplo, `interoperability-v1.md`) e acompanhada de plano de migração dos artefatos de interoperabilidade, módulos e pipelines afetados.