Este documento define a **diretriz base de interoperabilidade** da plataforma AppGear.



Ele descreve **como módulos, serviços Core e Suítes se integram** em:



- Topologia A (Docker / PoC / Dev);

- Topologia B (Kubernetes / produção enterprise);

- Fluxos AI-first, dados, automação, segurança e observabilidade.



Serve como **parecer oficial de integrações** da AppGear, complementando:



- `0 – Contrato v0` (princípios e restrições arquiteturais);

- `1 – Desenvolvimento v0.x` (módulos 00–17);

- `2 – Auditoria v0` (diretriz de auditoria técnica);

- `4 – Comercial v0` (combinações suportadas para ofertas e planos).



---

## 1. O que é



A **Interoperabilidade v0** é o documento que:



1. Define **como mapear dependências e integrações** entre:

   - Stack Core (infra, dados, IA, automação, segurança, observabilidade);

   - Stack Add-on (Suítes Factory, Brain, Operations, Guardian);

   - Módulos 00–17 de `1 – Desenvolvimento`;

   - Ambientes nas Topologias A e B. :contentReference[oaicite:2]{index=2}  

2. Padroniza **como documentar interoperabilidade** (tabelas, matrizes, fluxos ponta-a-ponta).

3. Funciona como **base de verdade** para:

   - projetar novos módulos e Suítes;

   - verificar se integrações respeitam o Contrato v0;

   - apoiar a auditoria (2 – Auditoria v0) e o `auditoria-modulos.yaml`.



### 1.1 Relação com os demais documentos (0–4)



- **0 – Contrato v0**  

  Define o modelo oficial de Topologias A/B, Stack Core, Suítes, multi-tenancy e AI-first. A Interoperabilidade v0 implementa a visão de integrações e dependências definida ali.



- **1 – Desenvolvimento v0.x**  

  Cada módulo (M00–M17) deve ter uma seção **“Integrações e Dependências”** coerente com esta diretriz (serviços Core consumidos, Suítes integradas, fluxos de dados/eventos).



- **2 – Auditoria v0**  

  Usa este documento como “gabarito” para checar se:

  - integrações seguem a cadeia de borda oficial;

  - não existe Shadow IT (serviços paralelos ao Core);

  - módulos não furam multi-tenancy ou bypassam LiteLLM, Vault, etc.



- **4 – Comercial v0**  

  Consulta a Interoperabilidade v0 para definir:

  - quais combinações de Suítes e integrações podem ser ofertadas;

  - quais cenários exigem restrições (ex.: “somente Topologia B”).



---

## 2. Por que



A diretriz de interoperabilidade existe para:



1. **Garantir coerência com o Stack Core**  

   O contrato define um **Stack Core obrigatório** (Traefik, Coraza, Kong, Istio, Tailscale, Vault, LiteLLM, Ceph, Postgres, Redis, Qdrant, Redpanda, etc.). As integrações devem usar esses componentes, não soluções paralelas.



2. **Evitar Shadow IT e acoplamentos indevidos**  

   Sem um documento único de interoperabilidade, é comum:

   - cada módulo subir sua própria stack para problemas já resolvidos no Core;

   - integrações banco-a-banco entre Suítes;

   - bypass da cadeia Traefik → Coraza → Kong → Istio;

   - chamadas diretas a provedores de LLM, ignorando o LiteLLM.



3. **Tratar multi-tenancy e vClusters como requisitos centrais**  

   A arquitetura AppGear exige:

   - `tenant_id` e `workspace_id` consistentes;

   - vCluster por workspace como unidade isolada;

   - serviços multi-tenant lógicos com isolamento forte de dados.



4. **Conectar o ecossistema AI-First ponta a ponta**  

   Backstage, Flowise, LiteLLM, n8n, RAG, Agentes, Suítes e stack de dados precisam conversar com:

   - rotas, APIs, eventos e dados bem definidos;

   - governança clara de segredos e identidades;

   - observabilidade e FinOps adequados.



5. **Reduzir risco em clientes (Topologia B)**  

   Ambientes enterprise com múltiplos tenants e workspaces dependem de integrações previsíveis. Uma diretriz clara evita surpresas em produção.



---

## 3. Pré-requisitos



### 3.1 Documentos



Antes de usar esta diretriz, tenha:



- `docs/architecture/0-contrato/0-Contrato-v0.md`

- `docs/architecture/1-desenvolvimento/v0.1-raw/Modulo-XX-v0.1.md`

- `docs/architecture/2-auditoria/2-Auditoria-v0.md`

- `docs/architecture/4-comercial/4-Comercial-v0.md`



Opcional, mas recomendado:



- módulos v1.0 retrofitados:

  - `docs/architecture/1-desenvolvimento/v1.0-retrofit/Modulo-XX-v1.0.md`

- arquivos auxiliares de interoperabilidade (ver seção 4.1).



### 3.2 Repositórios



Acesso de leitura a:



- `appgear-docs` (documentação e artefatos de interoperabilidade);

- `appgear-infra-core` (GitOps do Stack Core);

- `appgear-suites` (GitOps dos Add-ons das Suítes);

- `appgear-backstage` (Portal e plugins);

- `appgear-workspace-template` (template GitOps por workspace).

**Convenção de nomes:** sempre que citar repositórios ou diretórios locais,
utilize o prefixo `appgear-`, a raiz `/opt/appgear` e, na Topologia A, a rede
`appgear-net-core`.



### 3.3 Ambientes



- Topologia A (Docker / PoC / Dev):

  - host com `/opt/appgear` contendo `.env`, `docker-compose.yml`, `config/`, `data/`, `logs/`.

- Topologia B (Kubernetes):

  - cluster com Argo CD, Istio + mTLS, vClusters por workspace, Vault, KEDA, Tailscale.



### 3.4 Pessoas



- Responsável de Arquitetura / Plataforma;

- Engenheiros de módulo (M00–M17);

- Segurança / Governança;

- Produto / Comercial (para novas integrações, planos, SLAs).



---

## 4. Como fazer (roteiro de interoperabilidade)



### 4.1 Fase 0 – Estrutura de arquivos de interoperabilidade



No `appgear-docs`:



```bash
cd appgear-docs

mkdir -p docs/architecture/interoperabilidade

touch docs/architecture/interoperabilidade/mapa-global.md
touch docs/architecture/interoperabilidade/modulos.yaml
touch docs/architecture/interoperabilidade/fluxos-ai-first.md
```

Este documento fica em:



```text
docs/architecture/3-interoperabilidade/3-Interoperabilidade-v0.md
```



Arquivos auxiliares em `docs/architecture/interoperabilidade/` detalham:



- mapa global de componentes (Core x Suítes);

- matriz de interoperabilidade por módulo;

- fluxos AI-first ponta a ponta.



### 4.2 Fase 1 – Mapa global Core x Suítes



No `docs/architecture/interoperabilidade/mapa-global.md`:



- Documentar a Stack Core (infra & governança):

  - Portal (Backstage);

  - Rede (Traefik, Coraza, Kong, Istio, Tailscale);

  - Segurança (Vault, OpenFGA, OPA, Falco, Coraza);

  - Dados (Ceph, Postgres/PostGIS, Redis, Qdrant, Redpanda, RabbitMQ);

  - Observabilidade & FinOps (Prometheus, Grafana, Loki, OpenCost, Lago);

  - IA & Automação (Ollama, LiteLLM, Flowise, n8n, BPMN);

  - Legal/Compliance (Tika, Gotenberg, SignServer).



- Documentar a Stack Add-on (Suítes):

  - Factory – CDEs, Airbyte, build nativo, ERP/E-commerce/CRM etc.;

  - Brain – RAG, Corporate Brain, AI Workforce, AutoML;

  - Operations – IoT, Digital Twins, RPA, Edge/KubeEdge, Action Center;

  - Guardian – Security Suite, Legal AI, Chaos, Governança da App Store.



Para cada componente, registrar:



- nome lógico (core-postgres, addon-factory-vscode, etc.);

- interfaces (HTTP via Kong/Istio, eventos via Redpanda/RabbitMQ, acesso a dados via serviços);

- tipo de tenancy:

  - isolado por vCluster;

  - multi-tenant lógico (instância compartilhada).



### 4.3 Fase 2 – Matriz de interoperabilidade por módulo



No `docs/architecture/interoperabilidade/modulos.yaml`, para cada módulo MXX:



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



- Criar um bloco semelhante para todos os módulos M00–M17.

- Garantir que:

  - nenhuma integração chame LLMs diretamente (sempre via LiteLLM);

  - não haja acesso direto a bancos sensíveis ignorando serviços/API oficiais;

  - nomes lógicos de serviços sejam consistentes com `1 – Desenvolvimento`.



### 4.4 Fase 3 – Fluxos ponta a ponta



No `docs/architecture/interoperabilidade/fluxos-ai-first.md`, formalizar fluxos como:



- **AI-First Ecosystem Generator**

  - Backstage → n8n/BPMN → Flowise → LiteLLM → Argo CD → vCluster → Suítes;

  - descrever:

    - quem chama quem;

    - via qual interface;

    - como `tenant_id`/`workspace_id` fluem;

    - onde entram Vault, Qdrant, Meilisearch, etc.



- **DR/Backup e restauração**

  - Velero / snapshots / restore;

  - como dados de Suítes e Core são trazidos de volta sem quebrar integrações.



- **Fluxos Edge / KubeEdge**

  - Nuvem (Core/Suítes) ↔ Edge (workloads IoT/RPA);

  - como eventos retornam para a nuvem.



### 4.5 Fase 4 – Topologia A x Topologia B



- **Topologia A (Docker / PoC)**

  - `docker-compose.yml` em `/opt/appgear` deve:

    - usar nomes lógicos equivalentes (`core-*`, `addon-*`);

    - manter rotas por prefixo (`/directus`, `/appsmith`, `/n8n`, `/flowise`, `/metabase`);

    - centralizar variáveis em `.env` (sem segredos de produção).



- **Topologia B (Kubernetes)**

  - serviços correspondentes na pilha Core devem existir com papéis equivalentes;

  - rotas e APIs devem preservar, tanto quanto possível, o mesmo shape.



Neste documento, registrar:



- diferenças entre A e B para cada integração importante (autenticação, segurança, performance);

- limitações (o que só é suportado em B).



### 4.6 Fase 5 – Multi-tenancy e isolamento



Para serviços multi-tenant lógicos:



- Descrever no `modulos.yaml`:

  - escopo de isolamento (por tenant, por workspace, misto);

  - como `tenant_id`/`workspace_id` aparecem em:

    - schemas e tabelas (Postgres);

    - índices/buckets (Qdrant, Ceph);

    - tópicos/filas (Redpanda/RabbitMQ);

    - coleções/índices (Meilisearch).



Para cada caso, indicar testes esperados de não vazamento:



- query tentando acessar dados de outro tenant;

- eventos com IDs conflitantes;

- tokens sem claims de workspace adequadas.



Indicar quais itens de `2 – Auditoria v0` devem ser usados para validar esses cenários.



### 4.7 Fase 6 – Revisão por release



Para cada release (ex.: v0.1.0, v0.2.0):



- Atualizar `modulos.yaml` e `fluxos-ai-first.md` com novas integrações.



Verificar se:



- toda nova Suíte ou módulo aparece na matriz de interoperabilidade;

- fluxos AI-first críticos estão documentados.



Registrar um histórico de alterações em uma seção de “Changelog de interoperabilidade”, no final deste arquivo.



---

## 5. Como verificar



### 5.1 Verificação da própria Interoperabilidade v0



Considerar este documento “OK” quando:



- todos os componentes Core do Contrato v0 aparecem no mapa global;

- todas as Suítes e módulos relevantes aparecem em `modulos.yaml`;

- existem fluxos documentados para:

  - AI-first;

  - DR/backup;

  - Edge (quando houver);

- `2 – Auditoria v0` consegue:

  - apontar checklists de integrações usando este documento como referência;

  - classificar NCs de integração (ex.: bypass de LiteLLM, bypass da cadeia de borda).



### 5.2 Uso em análises de impacto



Quando uma nova integração for proposta:



- Verificar no `0 – Contrato` se é compatível com a arquitetura vigente.



- Registrar o impacto:

  - atualizar `mapa-global.md`, `modulos.yaml`, `fluxos-ai-first.md`;

  - avaliar alterações necessárias em módulos `1 – Desenvolvimento`;

  - ajustar checklists em `2 – Auditoria` e limites em `4 – Comercial`.



---

## 6. Erros comuns



- Integrar diretamente com bancos, filas ou LLMs sem passar pelos serviços Core apropriados.



- Não documentar dependências no `modulos.yaml`, gerando “serviços órfãos”.



- Misturar detalhe de Topologia A (PoC) com cenário de produção em Topologia B.



- Ignorar multi-tenancy lógico em serviços compartilhados.



- Atualizar módulos e Suítes sem atualizar este documento e os artefatos associados.



---

## 7. Onde salvar (localização oficial)



Este arquivo deve ser salvo como:



```text
appgear-docs/docs/architecture/3-interoperabilidade/3-Interoperabilidade-v0.md
```



Ele referencia, quando necessário:



```text
appgear-docs/docs/architecture/0-contrato/0-Contrato-v0.md
appgear-docs/docs/architecture/1-desenvolvimento/v0.1-raw/Modulo-XX-v0.1.md
appgear-docs/docs/architecture/1-desenvolvimento/v1.0-retrofit/Modulo-XX-v1.0.md
appgear-docs/docs/architecture/2-auditoria/2-Auditoria-v0.md
appgear-docs/docs/architecture/4-comercial/4-Comercial-v0.md
appgear-docs/docs/architecture/interoperabilidade/*
```



Em repositórios externos (clientes, parceiros), manter:



- o mesmo nome (`3-Interoperabilidade-v0.md`);

- referência explícita ao Contrato v0 utilizado.
