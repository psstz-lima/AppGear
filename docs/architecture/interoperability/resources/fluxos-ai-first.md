# Fluxos AI-first AppGear

> [!IMPORTANT]
> **FLUXOS OFICIAIS AI-FIRST DA APPGEAR – VISÃO PONTA A PONTA**  
>  
> Este arquivo descreve os **fluxos AI-first ponta a ponta** da AppGear, conectando:  
> - Portal Backstage, n8n, Flowise, LiteLLM e Argo (Events/Workflows/CD);  
> - vClusters, Suítes (Factory, Brain, Operations, Guardian) e Stack Core;  
> - componentes de dados (Postgres, Ceph, Qdrant, Redpanda, Meilisearch) e observabilidade.  
>  
> Ele complementa:  
> - `docs/architecture/contract/contract-v0.md`  
> - `docs/architecture/audit/audit-v0.md`  
> - `docs/architecture/interoperability/interoperability-v0.md`  
> - `docs/architecture/interoperability/resources/mapa-global.md`  
> - `docs/architecture/interoperability/resources/modulos.yaml`  

---

## 1. O que é

Este documento registra, de forma **operacional e sequencial**, os principais **fluxos AI-first** da AppGear, isto é:

- **como um pedido do usuário** (por exemplo, “criar um novo workspace AI-first” ou “gerar um novo app”)  
  vira **ações coordenadas** em:
  - Backstage;
  - n8n/BPMN;
  - Flowise;
  - LiteLLM;
  - Argo (Events/Workflows/CD);
  - vClusters e Suítes (Factory, Brain, Operations, Guardian);
- **como os dados fluem** entre:
  - Tika/Gotenberg, Qdrant, Ceph, Postgres, Redpanda, Meilisearch;
- **como DR, Edge e observabilidade** entram nesses fluxos.

Ele não define novas regras; apenas transforma o que está no Contrato, Auditoria, Interoperabilidade e Módulos (M00–M17) em **histórias de fluxo** fáceis de auditar, desenhar e automatizar.

---

## 2. Por que

Motivações principais:

1. **Dar visão ponta a ponta**  
   Unir em um só lugar a “linha do tempo” de cada fluxo importante:
   - quem inicia;
   - quais sistemas participam;
   - onde os dados passam;
   - como entram IA, GitOps, DR e observabilidade.

2. **Facilitar auditoria e interoperabilidade**  
   Permitir que a Diretriz de Auditoria referencie fluxos específicos:
   - Fluxo AI-first de criação de workspace;
   - Fluxo AI-first de geração de app;
   - Fluxo RAG/Corporate Brain;
   - Fluxo de DR/restore.  
   Facilita criação de checklists e scripts de validação (infra + app).

3. **Apoiar automação e assistentes de arquitetura**  
   Servir de base para:
   - geração de diagramas;
   - geração de playbooks;
   - prompts de IA que precisam entender “como a AppGear funciona de ponta a ponta”.

4. **Evitar fluxos paralelos**  
   Sem um registro único, cada dev/equipe tende a inventar um fluxo próprio.  
   Este documento passa a ser o “mapa de verdade” dos fluxos AI-first.

---

## 3. Pré-requisitos

Para usar ou atualizar este arquivo corretamente, é necessário:

- Entender minimamente:
  - **Contrato v0** (Stack Core, Suítes, Topologias A/B, multi-tenancy);
  - **Diretriz de Auditoria v0** (como verificar fluxos);
  - **Diretriz de Interoperabilidade v0** (cadeias de borda, módulos, integrações).
- Ter acesso à matriz em:
  - `docs/architecture/interoperability/resources/modulos.yaml`
- Ter noção das capacidades de:
  - Backstage, n8n, Flowise, LiteLLM, Argo, vClusters;
  - Qdrant, Ceph, Postgres, Redpanda, Meilisearch.

---

## 4. Fluxos AI-first

### 4.1. Fluxo 1 – Criação AI-first de Workspace (Topologia B)

**Objetivo:** criar um novo workspace/vCluster para um tenant, com stack mínima da AppGear, via fluxo AI-first.

**Sequência (alto nível):**

1. **Usuário → Backstage**  
   - Usuário autenticado (Keycloak) acessa Backstage.  
   - Seleciona um **template AI-first de workspace** (Blueprint AppGear).

2. **Backstage → n8n / BPMN**  
   - Backstage dispara um fluxo no n8n (ou engine BPMN):
     - coleta inputs (tenant, workspace, contexto de negócio, Suítes desejadas);
     - chama Flowise/LiteLLM para:
       - sugerir layout de módulos;
       - sugerir nível de isolamento, integrações, stack mínima.

3. **n8n / Flowise → GitOps**  
   - Com os parâmetros validados, n8n:
     - cria/atualiza repositório `appgear-workspace-<id>` a partir do template;
     - gera manifests de vCluster, namespaces, ApplicationSets;
     - comita no repositório Git (linha M01/M13).

4. **GitOps → Argo CD**  
   - Argo CD detecta mudança no repositório de workspace:
     - cria/atualiza vCluster;
     - implanta stack Core mínima no vCluster (conectada ao Core global);
     - implanta Suítes selecionadas.

5. **Resultado**  
   - Novo workspace/vCluster disponível.  
   - Registros em:
     - `appgear.workspace.created` (Redpanda);
     - catálogo Backstage;
     - observabilidade (métricas e logs de criação/instalação).

---

### 4.2. Fluxo 2 – Geração AI-first de Aplicação/Stack no Workspace

**Objetivo:** dentro de um workspace já existente, gerar uma nova aplicação ou stack (por exemplo, um app Directus + Appsmith + n8n) via fluxo AI-first.

**Sequência:**

1. **Usuário → Backstage (no contexto do workspace)**  
   - Usuário escolhe um template de “Aplicação AI-first”:
     - ex.: “App CRM básico AI-first”, “Dashboard Operacional AI-first”.

2. **Backstage → n8n → Flowise / LiteLLM**  
   - Backstage chama n8n:
     - coleta requisitos (entidades, fluxos, integrações externas, tipo de UI);
     - n8n orquestra chamadas a Flowise + LiteLLM para:
       - gerar proposta de stack (módulos envolvidos);
       - gerar skeleton de esquemas (Postgres), coleções (Qdrant), dashboards;
       - gerar pipelines (n8n, Argo Workflows).

3. **n8n → GitOps (workspace)**  
   - n8n escreve arquivos no repositório Git do workspace:
     - manifests para novos serviços (Appsmith apps, Directus collections, n8n workflows);
     - configurações de rotas (prefixos em Kong/Traefik);
     - artefatos de UI/infra.

4. **GitOps → Argo CD (vCluster do workspace)**  
   - Argo CD aplica as mudanças no vCluster:
     - sobe novos serviços;
     - aplica configs de rotas;
     - executa pipelines de inicialização (se necessário).

5. **Resultado**  
   - App AI-first disponível para o usuário, por exemplo:
     - `/appsmith/...`, `/directus/...`, `/n8n/...`, `/flowise/...` no contexto do workspace;
   - Registros de uso e criação em:
     - `appgear.ai.pipeline.executed`;
     - `appgear.core.m08.usage` (M08 – Serviços Core).

---

### 4.3. Fluxo 3 – RAG / Corporate Brain (Brain + Factory)

**Objetivo:** transformar dados/arquivos de negócio em conhecimento consultável via RAG/LLM, respeitando tenants/workspaces.

**Sequência:**

1. **Ingestão de dados (Factory)**  
   - CDEs/Airbyte conectam sistemas de negócio (ERP, CRM, E-commerce etc.);  
   - Documentos são enviados para:
     - Ceph (arquivos brutos);
     - Postgres (metadados, tabelas normalizadas);  
   - Eventos de ingestão:
     - `appgear.factory.cde.output` em Redpanda.

2. **Preparação para RAG (Brain)**  
   - Serviços da Suíte Brain:
     - consomem `appgear.factory.cde.output`;
     - usam Tika/Gotenberg para extrair texto/metadata de documentos;
     - chamam LiteLLM para geração de embeddings/contextos;
     - gravam embeddings em Qdrant (por tenant/workspace);
     - gravam artefatos em Ceph e metadados em Postgres.

3. **Consulta RAG/Corporate Brain**  
   - Usuário (ou app) envia pergunta via API Brain:
     - passa pelo pipeline Traefik → Coraza → Kong → Istio → Brain;  
   - Brain:
     - resolve contexto (tenant/workspace, identidade, escopo);
     - consulta Qdrant (similaridade);
     - monta contexto final;
     - chama LiteLLM (via gateway único) para resposta;  
   - Resposta retorna via mesma cadeia de borda.

4. **Resultado**  
   - Perguntas são respondidas com base em dados multi-fonte (Factory + documentos),  
     sempre isoladas por tenant/workspace.  
   - Logs/métricas de uso de IA atualizados (M03, M08, M10).

---

### 4.4. Fluxo 4 – DR/Backup e Restauração (Velero + Core de Dados)

**Objetivo:** garantir que ambientes AI-first (Core + workspaces) possam ser restaurados em caso de falha.

**Sequência:**

1. **Agendamento de backups**  
   - Velero configurado para:
     - tirar snapshots periódicos de volumes relevantes (Ceph);
     - exportar backups de recursos Kubernetes;  
   - Bancos Postgres e outros bancos críticos seguem política de backup específica (dump, réplica etc.).

2. **Gatilhos de DR**  
   - Evento de DR:
     - falha de cluster;
     - perda de workspace;
     - teste planejado (Chaos/Guardian).

3. **Restauração**  
   - Velero restaura:
     - recursos de cluster (namespaces, deployments, CRDs relevantes);
     - volumes associados;  
   - Processos adicionais:
     - reconectar-se a Keycloak, Vault, OpenFGA;
     - reindexar Qdrant/Meilisearch se necessário.

4. **Fluxos AI-first impactados**  
   - Criação de workspace (Fluxo 1) pode ser reexecutada parcial ou totalmente;  
   - Pipelines AI-first (Fluxo 2) podem ser reidratados com base em repositórios Git;  
   - RAG (Fluxo 3) pode exigir reindexação.

5. **Resultado**  
   - Ambiente de Core e workspaces volta a um estado consistente com o momento do backup;  
   - Registros em `appgear.dr.backup.*` (M15).

---

### 4.5. Fluxo 5 – Edge / KubeEdge / IoT (Operations + Core)

**Objetivo:** conectar dispositivos/edge nodes a workloads AI-first.

**Sequência (alto nível):**

1. **Edge → Core**  
   - Dispositivos se conectam a gateways (Edge/KubeEdge/Operations);  
   - Telemetria e comandos trafegam via:
     - Redpanda;
     - HTTP/MQTT através de Istio/Tailscale (quando aplicável).

2. **Core → Brain/Factory/Operations**  
   - Dados de telemetria são:
     - armazenados (Ceph/Postgres);
     - processados (n8n/Argo Workflows);
     - enriquecidos com IA (Brain/Flowise/LiteLLM).

3. **Decisões e ações**  
   - Brain gera insights, recomendações ou ações automáticas;  
   - Operations executa ações em dispositivos (via Edge/IoT gateways).

4. **Resultado**  
   - Ecossistema AI-first estende-se até o Edge, mantendo segurança, observabilidade e multi-tenancy.

---

## 5. Como verificar

A Diretriz de Auditoria pode usar este arquivo para:

- Selecionar um fluxo (por exemplo, Fluxo 2 – Geração AI-first de Aplicação) e:
  - verificar se os sistemas mencionados existem e estão integrados;
  - validar que:
    - chamadas de IA passam por LiteLLM;
    - rotas HTTP respeitam Traefik → Coraza → Kong → Istio;
    - eventos existem em Redpanda com nomes previstos;
    - dados estão em Qdrant/Ceph/Postgres como descrito.

Procedimento sugerido:

1. Escolher um fluxo (ex.: Fluxo 1 ou 2).  
2. Seguir cada etapa, checando:
   - serviços;
   - eventos;
   - bancos/dados;
   - logs/métricas.  
3. Registrar evidências de que o fluxo está implementado de acordo.

---

## 6. Erros comuns

- **Fluxos implementados que não aparecem aqui**  
  Novos caminhos AI-first criados sem atualizar este arquivo.

- **Fluxos descritos aqui que não existem mais**  
  Serviços descontinuados sem atualização deste documento.

- **Uso de IA fora do fluxo oficial**  
  Chamadas diretas a provedores de LLM sem passar por LiteLLM.

- **Bypass de borda**  
  Fluxo aponta Traefik → Coraza → Kong → Istio, mas na prática há:
  - ingressos paralelos;
  - uso direto de LoadBalancer/NodePort.

- **Falhas de multi-tenancy**  
  Fluxos que misturam dados de tenants/workspaces diferentes em:
  - Qdrant;
  - Ceph;
  - Postgres;
  - tópicos de eventos.

---

## 7. Onde salvar

Este arquivo deve ser mantido em:

```text
docs/architecture/interoperability/resources/fluxos-ai-first.md
```

Relação com outros artefatos:

- `docs/architecture/interoperability/interoperability-v0.md`  
  – documento normativo de interoperabilidade (este arquivo é um anexo operacional).
- `docs/architecture/interoperability/resources/mapa-global.md`  
  – mapa Core x Suítes; este arquivo usa aquele como base conceitual.
- `docs/architecture/interoperability/resources/modulos.yaml`  
  – detalhamento por módulo (M00–M17); este arquivo amarra os módulos em fluxos ponta a ponta.

Alterações em fluxos AI-first **devem** ser refletidas aqui, e qualquer mudança estrutural (mudança de cadeia de borda, substituição de componentes Core etc.) deve ser feita primeiro no Contrato v0 e, depois, refletida neste documento.

---

## 8. Matriz de cobertura – Fluxos AI-first x Módulos (M00–M17)

Esta matriz resume quais módulos M00–M17 estão diretamente envolvidos em cada fluxo AI-first descrito neste arquivo.

| Fluxo                                                   | Módulos principais                                       | Módulos de infraestrutura/transversais                                                                 |
|---------------------------------------------------------|----------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| **Fluxo 1 – Criação AI-first de Workspace (Topologia B)** | M01 (GitOps), M07 (Backstage), M13 (Workspaces/vCluster) | M02 (Borda/Malha), M03 (Observabilidade), M04 (Dados Core), M05 (Segurança), M06 (SSO), M14 (Pipelines AI-first)                            |
| **Fluxo 2 – Geração AI-first de Aplicação/Stack**       | M07 (Backstage), M08 (Serviços Core), M09 (Factory), M10 (Brain), M11 (Operations) | M01 (GitOps), M02 (Borda/Malha), M03 (Observabilidade), M04 (Dados Core), M05 (Segurança), M06 (SSO), M14 (Pipelines AI-first)              |
| **Fluxo 3 – RAG / Corporate Brain (Brain + Factory)**   | M09 (Factory), M10 (Brain)                              | M02 (Borda/Malha), M03 (Observabilidade), M04 (Dados Core), M05 (Segurança), M06 (SSO), M08 (Serviços Core), M14 (Pipelines AI-first)      |
| **Fluxo 4 – DR/Backup e Restauração**                   | M15 (DR & Backup Global)                                | M01 (GitOps), M02 (Borda/Malha), M03 (Observabilidade), M04 (Dados Core), M05 (Segurança), M06 (SSO), M12 (Guardian), M17 (Políticas/Resiliência) |
| **Fluxo 5 – Edge / KubeEdge / IoT**                     | M11 (Operations), M16 (Conectividade Híbrida)           | M02 (Borda/Malha), M03 (Observabilidade), M04 (Dados Core), M05 (Segurança), M06 (SSO), M09 (Factory), M10 (Brain), M17 (Políticas/Resiliência)  |

Notas:

- **M00** (Convenções, Repositórios e Nomenclatura) é base conceitual e não aparece diretamente em fluxos.  
- **M12** (Guardian) atua principalmente como camada de segurança/governança em DR, auditorias e chaos, mesmo quando não é citado nominalmente em cada fluxo.  
- **M17** (Políticas Operacionais e Resiliência) é transversal — impacta todos os fluxos via Policy-as-Code, Falco, testes de resiliência etc.  
- Os detalhes de cada módulo estão em `modulos.yaml`; esta tabela é uma visão de alto nível para navegação rápida.
