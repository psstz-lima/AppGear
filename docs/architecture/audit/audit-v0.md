# Diretriz de Auditoria AppGear

> [!IMPORTANT]
> **DIRETRIZ OFICIAL DE AUDITORIA DA APPGEAR – FONTE NORMATIVA ÚNICA DA DISCIPLINA DE AUDITORIA**  
>  
> Este documento define as regras de **como auditar a plataforma AppGear** que **toda implantação AppGear** deve seguir:  
> - alinhamento obrigatório ao **Contrato de Arquitetura v0** como referência principal;  
> - aplicação consistente dos **módulos de desenvolvimento v0/v0.3 (00–17)** como camada de implementação;  
> - auditoria sistemática de **Topologia A** (Docker/PoC) e **Topologia B** (Kubernetes/produção);  
> - verificação do uso correto do **Stack Core** e das **Suítes** (Factory, Brain, Operations, Guardian);  
> - validação de **LiteLLM como gateway único de IA**, proibindo chamadas diretas a provedores de LLM;  
> - confirmação de que GitOps, Service Mesh, Vault, KEDA, observabilidade e DR estão implantados conforme o contrato.  

Versão normativa: v0  
Linha de revisão ativa: v0.3    

---

## 1. O que é

A Diretriz de Auditoria AppGear é o documento normativo que define **como auditar tecnicamente** a plataforma.

Ela estabelece:

- o escopo mínimo de uma auditoria (documentação, código, infraestrutura e ambientes);
- os documentos e repositórios que devem ser usados como referência;
- o conjunto de verificações obrigatórias sobre:
  - arquitetura e Stack Core;
  - módulos de desenvolvimento (00–17) nas linhas v0 e v0.3;
  - interoperabilidade e segurança;
  - pipelines CI/CD, IA/RAG e agentes;
  - ambientes em **Topologia A** (PoC/labs) e **Topologia B** (produção).

Esta diretriz é usada para:

- orientar auditorias internas e externas;
- alimentar checklists manuais ou semiautomáticos;
- servir de base para motores de auditoria com IA;
- produzir relatórios formais de auditoria AppGear.

O **Contrato de Arquitetura v0** define o “o quê” (regras e decisões); esta diretriz define o “como verificar”.

---

## 2. Por que

Os objetivos desta diretriz são:

1. **Padronizar auditorias**  
   Garantir que qualquer auditor siga o mesmo roteiro ao avaliar uma implantação AppGear, evitando lacunas e variações arbitrárias.

2. **Assegurar aderência ao Contrato de Arquitetura v0**  
   Toda auditoria deve verificar se a implementação em Topologia A/B está alinhada a:
   - Stack Core;
   - Topologias de implantação;
   - modelo de multi-tenancy (tenant/workspace/vCluster);
   - cadeia de borda (Traefik → WAF/Coraza → Kong → Istio);
   - LiteLLM como gateway único de IA.

3. **Conectar desenvolvimento, auditoria e interoperabilidade**  
   - Contrato v0 define as regras estruturais;  
   - Módulos v0/v0.3 detalham a implementação;  
   - Interoperabilidade define cadeias de integração;  
   - Auditoria verifica se tudo isso está coerente em código e ambiente.

4. **Suportar automação e relatórios integrados**  
   - Permitir a geração de checklists e prompts de auditoria consistentes;  
   - Facilitar relatórios consolidados por ambiente, módulo, tenant/workspace.

5. **Reduzir risco de falhas de segurança e governança**  
   - Evitar uso indevido de Topologia A em produção;  
   - Evitar bypass de LiteLLM, Service Mesh e GitOps;  
   - Garantir observabilidade, DR e rastreabilidade de decisões.

---

## 3. Pré-requisitos

### 3.1. Documentos obrigatórios

Antes de iniciar uma auditoria, o auditor deve ter acesso às versões atuais de:

- `docs/architecture/contract/contract-v0.md`  
  – Contrato de Arquitetura AppGear v0 (norma global).
- `docs/architecture/audit/audit-v0.md`  
  – este documento (Diretriz de Auditoria).
- `docs/architecture/interoperability/interoperability-v0.md`  
  – Diretriz de Interoperabilidade.
- `STATUS-ATUAL.md`  
  – visão consolidada da linha v0/v0.3.
- `development/v0/`  
  – baseline original dos módulos 00–17.
- `development/v0.3/core-module-v0.3.md`  
  – visão consolidada da linha v0.3.
- `development/v0.3/module-XX-v0.3.md`  
  – módulos v0.3 por domínio.
- `development/v0.3/stack-unificada-v0.3.yaml`  
  – stack unificada por serviço/componente.
- `reports/interoperability/interoperability-cross-check-v0.3.md`  
  – evidência de interoperabilidade atual.

Versões intermediárias (v0.1, v0.2) devem estar arquivadas em `archive/**` e são **não normativas**.

---

### 3.2. Repositórios e organização mínima

Devem existir, no mínimo:

- repositório de infraestrutura/core (ex.: `appgear-infra-core`);
- repositório de suítes/add-ons (ex.: `appgear-suites`);
- repositório de documentação (ex.: `appgear-docs`);
- repositórios específicos de clientes/workspaces, quando houver customizações.

Padrões esperados:

- prefixo oficial `appgear-*` para repositórios da plataforma;
- para Topologia A (PoC/labs): diretório base sugerido `/opt/appgear`;
- para Topologia B (prod): organização GitOps clara, com repositórios separados para:
  - Core (stack base);
  - Suítes;
  - Workspaces/Tenants.

---

### 3.3. Acesso a ambientes

**Topologia A (PoC / labs – não produção):**

- acesso SSH/console ao host;
- acesso à pasta `/opt/appgear` (ou equivalente);
- acesso ao `.env` (sem segredos de produção).

**Topologia B (produção):**

- `kubectl` com permissão de leitura nos namespaces/vClusters AppGear;
- acesso de leitura ao Argo CD (ou ferramenta GitOps equivalente);
- acesso de leitura ao Vault;
- acesso de leitura ao Backstage;
- acesso de leitura à stack de observabilidade (Prometheus, Loki, Grafana, OpenCost/Lago);
- acesso de leitura ao IdP (Keycloak) e, quando aplicável, a OpenFGA/OPA.

---

### 3.4. Pessoas envolvidas

- representante de Arquitetura/Plataforma;
- representante de Segurança/Governança;
- representante de Produto/Comercial (quando houver impacto em SLA/escopo);
- eventualmente, representante do cliente em auditorias conjuntas.

---

## 4. Como fazer (comandos)

Esta seção define o **roteiro padrão de auditoria**, com exemplos de comandos.  
Adapte nomes de clusters, namespaces, tenants e workspaces ao ambiente real.

### 4.1. Fase 0 – Preparação

1. Abrir registro de auditoria (issue/ticket/doc) com:
   - escopo (módulos, ambientes, datas);
   - objetivo (ex.: “homologar ambiente `appgear-br-prod` para produção”);
   - equipe envolvida.

2. Clonar/atualizar repositórios de referência:

```bash
git clone <url-appgear-docs> appgear-docs
git clone <url-appgear-infra-core> appgear-infra-core
git clone <url-appgear-suites> appgear-suites

cd appgear-docs
git pull
```

3. Registrar hashes de commit relevantes (docs + infra) na abertura da auditoria.

---

### 4.2. Fase 1 – Auditoria global (arquitetura / Stack Core)

No repositório de infraestrutura (Topologia B):

```bash
cd appgear-infra-core

# Namespaces principais da plataforma
kubectl get ns | grep appgear

# Componentes core esperados (exemplo)
kubectl get pods -A | grep -E "traefik|kong|istio|keda|vault|prometheus|loki|grafana|openfga|keycloak"
```

Checklist mínimo:

* Traefik presente como entrypoint;
* cadeia de borda respeitada (Traefik → Coraza → Kong → Istio);
* Istio com mTLS STRICT em namespaces sensíveis;
* Vault implantado e referenciado por manifests (sem segredos em claro);
* KEDA presente, com políticas de Scale-to-Zero em workloads adequados;
* observabilidade (Prometheus, Loki, Grafana) operacional;
* FinOps (OpenCost/Lago) ativo, quando aplicável.

---

### 4.3. Fase 2 – Auditoria por módulo (00–17)

Para cada módulo `module-XX`:

1. Localizar os arquivos:

   * `development/v0/module-XX-v0.md`
   * `development/v0.3/module-XX-v0.3.md`

2. Ler objetivo, dependências e integrações do módulo.

3. Verificar, nos manifests e scripts de infra/suítes, se as decisões do módulo estão implementadas.

4. Registrar para cada módulo:

   * não-conformidades (NCs);
   * riscos;
   * recomendações;
   * evidências (links de commit, trechos de manifestos, prints, saídas de comando).

---

### 4.4. Fase 3 – Auditoria de interoperabilidade

Referências:

* `docs/architecture/interoperability/interoperability-v0.md`;
* `development/v0.3/stack-unificada-v0.3.yaml`;
* `reports/interoperability/interoperability-cross-check-v0.3.md`.

Passos típicos:

1. Validar cadeias de tráfego de borda (Traefik → Coraza → Kong → Istio).
2. Verificar que serviços expostos externamente usam apenas essas cadeias, sem bypass.
3. Confirmar integrações obrigatórias (LiteLLM, Postgres, Redis, Qdrant, etc.).
4. Verificar uso de labels e políticas de multi-tenancy e FinOps conforme contrato.

---

### 4.5. Fase 4 – Auditoria de CI/CD, artefatos e IA

Referências:

* `guides/ai-ci-cd-flow.md`;
* `guides/integrated-report-procedure.md` (quando existir).

Passos:

1. Verificar se pipelines geram artefatos padronizados:

```text
/artifacts/ai_reports
/artifacts/reports
/artifacts/coverage
/artifacts/tests
/artifacts/docker
/artifacts/sbom
```

2. Conferir existência de hashes SHA-256 para imagens e artefatos críticos.

3. Confirmar que há parecer automatizado da IA e, quando definido, validação humana (RAPID/CCB).

4. Garantir que imagens de produção não usam `:latest`.

---

### 4.6. Fase 5 – Auditoria de ambientes (Topologias A e B)

#### 4.6.1. Topologia B (Kubernetes / produção)

* Verificar segregação de namespaces/vClusters por tenant/workspace:

```bash
kubectl get ns | grep workspace
```

* Validar:

  * uso de vClusters (ou solução equivalente) para isolamento;
  * configuração de DR/backup (Velero, snapshots, backups de banco);
  * uso consistente de labels `appgear.io/tenant`, `appgear.io/workspace`, `appgear.io/vcluster`, `appgear.io/env`.

#### 4.6.2. Topologia A (Docker / PoC)

Estrutura esperada (exemplo):

```text
/opt/appgear
  .env                 # sem segredos de produção
  docker-compose.yml
  /config
  /data
  /logs
```

Verificar que:

* a stack está classificada como PoC/lab;
* não há segredos de produção em `.env` ou volumes;
* qualquer uso de Topologia A em produção deve ser registrado como **NC crítica**.

---

## 5. Como verificar

### 5.1. Classificação dos itens auditados

Para cada requisito verificado, classificar:

* `OK` – aderente ao contrato/diretriz;
* `NOK` – não aderente;
* `N.A.` – não aplicável no escopo da auditoria.

### 5.2. Evidências mínimas

Todo item marcado como `OK` ou `NOK` deve ter ao menos uma evidência:

* print de tela (Argo, Grafana, Backstage, Vault etc.);
* trecho de manifesto ou Helm Chart (sem segredos);
* link para commit/PR;
* saída de comando (`kubectl`, `git`, etc.).

### 5.3. Criticidade

* violações de **restrições estruturais** (exposição indevida, ausência de mTLS, segredos em código, bypass de LiteLLM/GitOps) → **NC crítica**;
* lacunas de boas práticas (documentação incompleta, dashboards ausentes, naming inconsistente) → **NC não crítica** ou recomendação.

### 5.4. Rastreabilidade

Cada NC deve referenciar:

* seção correspondente do **Contrato v0**;
* módulo(s) afetados (00–17);
* ambiente (Topologia A/B, cluster, namespace/vCluster);
* artefatos envolvidos (pipelines, manifests, docs).

---

## 6. Erros comuns

Principais erros que violam direta ou indiretamente esta diretriz:

1. **Usar documentos antigos (v0.1, v0.2) como regra vigente**
   Em vez deste arquivo + Contrato v0 + módulos v0.3.

2. **Auditar apenas infraestrutura**
   Ignorando Suítes (Factory, Brain, Operations, Guardian), fluxo AI-First, agentes, pipelines.

3. **Tratar Topologia A como produção**
   docker-compose em servidores definitivos, sem K8s, sem GitOps, sem DR.

4. **Bypass de cadeia de borda**
   Serviços expostos diretamente por `LoadBalancer`/`NodePort` ou Ingress não alinhado a Traefik → Coraza → Kong → Istio.

5. **Chamadas diretas a provedores de LLM**
   Código acessando `api.openai.com` (ou equivalente) sem passar por LiteLLM.

6. **Ausência de GitOps real**
   Manifests aplicados manualmente, divergindo do estado em Git; Argo CD sem ApplicationSets para Core, Suítes e Workspaces.

7. **Ausência de DR ou testes de restore**
   Velero não configurado, snapshots inexistentes, backups apenas em storage interno ao cluster.

8. **Documentação paralela não alinhada**
   Arquitetura documentada em wikis/planilhas que contradizem o Contrato v0 ou esta diretriz.

---

## 7. Onde salvar

Este documento deve ser mantido em:

```text
docs/architecture/audit/audit-v0.md
```

### 7.1. Relação com outros documentos normativos

* **Contrato de Arquitetura (norma global)**

  * `docs/architecture/contract/contract-v0.md`

* **Diretriz de Interoperabilidade**

  * `docs/architecture/interoperability/interoperability-v0.md`

* **Desenvolvimento (módulos e stack)**

  * `development/v0/**` – baseline funcional original.
  * `development/v0.3/core-module-v0.3.md` – visão consolidada v0.3.
  * `development/v0.3/module-XX-v0.3.md` – módulos v0.3.
  * `development/v0.3/stack-unificada-v0.3.yaml` – stack unificada.

Esses documentos são a base normativa e técnica sobre a qual a auditoria é feita.

### 7.2. Relação com relatórios e evidências

* `STATUS-ATUAL.md` – consolida estado v0/v0.3 à luz do contrato e desta diretriz;
* `reports/interoperability/interoperability-cross-check-v0.3.md` – evidências de interoperabilidade;
* `reports/review/**` – análises, motores e relatórios de revisão.

Relatórios são **evidências de aplicação**, não fontes normativas.

### 7.3. Arquivo de histórico (não normativo)

Versões antigas, rascunhos e linhas descontinuadas desta diretriz devem ser movidas para:

```text
archive/audit/
```

Regras:

* nada em `archive/**` é considerado **vigente**;
* quando houver nova versão (ex.: `audit-v1.md`), este arquivo deve ser movido para `archive/audit/audit-v0-old.md` ou equivalente, preservando o histórico.

---

> [!IMPORTANT]
> **Este arquivo é a referência oficial da disciplina de auditoria AppGear.**
>
> * O **Contrato v0** define as decisões estruturais; esta diretriz define **como verificar** sua aplicação.
> * Módulos de Desenvolvimento v0/v0.3 e a Diretriz de Interoperabilidade detalham **como implementar e integrar** o que será auditado.
>
> Qualquer mudança relevante na forma de auditar (escopo, método, critérios de aceitação) deve ser tratada como **evolução de diretriz** (por exemplo, `audit-v1.md`) e acompanhada de plano de migração de checklists, relatórios e motores de auditoria.