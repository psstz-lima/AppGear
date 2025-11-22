# Diretriz de Auditoria AppGear v0

Este documento define a **Diretriz Base de Auditoria da plataforma AppGear v0**.

Ele explica **como auditar**:

- o alinhamento com o **0 – Contrato de Arquitetura v0**;
- os módulos de **1 – Desenvolvimento v0.x** (00–17);
- a implantação em **Topologia A (Docker/PoC)** e **Topologia B (Kubernetes/produção)**;
- o uso correto do **stack Core**, das **Suítes**, de **LiteLLM, KEDA, Vault, Tailscale, Istio, GitOps**, etc.

Ele também serve como referência para:

- o `Prompt-Motor-Retrofit-v1.md` (retrofit de módulos);
- o `Prompt-Motor-Auditoria-v1.md` (auditoria por módulo);
- o arquivo `docs/retrofit/auditoria-modulos.yaml` (mapa estruturado de NCs por módulo).

---

## 1. Objetivo

Os objetivos desta diretriz de auditoria são:

1. Definir um **roteiro único de auditoria técnica** para a AppGear.  
2. Garantir que qualquer auditor (interno, cliente, parceiro) consiga:
   - ler o **0 – Contrato de Arquitetura v0**;
   - navegar pelos módulos de **1 – Desenvolvimento v0.x** (00–17);
   - avaliar ambientes em **Topologia A** e **Topologia B**;
   - registrar **não-conformidades (NCs)**, **riscos** e **recomendações** de forma rastreável.  
3. Fornecer base para:
   - versões futuras de **2 – Auditoria v1.x**;
   - outputs do `Prompt-Motor-Auditoria-v1` em YAML;
   - checklists e relatórios formais de auditoria.

> **Guia para chats – Seção 1 (Objetivo)**  
> - **0 – Contrato:** use esta seção como base para saber “para que serve” a auditoria na visão da plataforma.  
> - **1 – Desenvolvimento:** garanta que cada módulo possa ser auditado contra estes objetivos.  
> - **2 – Auditoria:** trate esta seção como o “escopo-mãe” de qualquer checklist.  
> - **3 – Interoperabilidade e 4 – Comercial:** use esta seção para justificar auditorias técnicas perante áreas de negócio ou parceiros.

---

## 2. Escopo e documentos de referência

### 2.1. Escopo

Esta diretriz cobre:

- Auditoria de **documentação**:
  - `0 – Contrato v0`;
  - `1 – Desenvolvimento v0.x` (módulos 00–17);
  - `3 – Interoperabilidade v0`;
  - `4 – Comercial v0`.
- Auditoria de **infraestrutura e implantação**:
  - Stack Core (Traefik, Kong, Istio, Tailscale, Ceph, Vault, Observabilidade, FinOps etc.);
  - Suítes add-ons (Factory, Brain, Operations, Guardian);
  - Ambientes em **Topologia A** (PoC/Dev) e **Topologia B** (produção).
- Auditoria de **IA, RAG e agentes**, incluindo:
  - uso de **LiteLLM** como gateway único;
  - RAG (Qdrant, Meilisearch);
  - agentes orquestrados (Flowise, n8n, etc.).

### 2.2. Documentos de referência

A auditoria deve sempre considerar:

- `docs/architecture/0-contrato/0-Contrato-v0.md` – **Contrato de Arquitetura AppGear v0**.  
- Módulos de desenvolvimento (v0.x/v0.1):

  ```text
  docs/architecture/1-desenvolvimento/v0.1-raw/Modulo-XX-v0.1.md
  ```

- Módulos já retrofitados (v1.x):

  ```text
  docs/architecture/1-desenvolvimento/v1.0-retrofit/Modulo-XX-v1.0.md
  ```

- `docs/architecture/3-interoperabilidade/3-Interoperabilidade-v0.md` – integrações.  
- `docs/architecture/4-comercial/4-Comercial-v0.md` – visão de produto, limites e planos.  
- `docs/retrofit/Manifesto-Coordenacao-Retrofit-v1.md` – regras globais de retrofit.  
- `docs/retrofit/Prompt-Motor-Retrofit-v1.md` – motor de retrofit de módulos.  
- `docs/retrofit/Prompt-Motor-Auditoria-v1.md` – motor de auditoria por módulo.  
- `docs/retrofit/auditoria-modulos.yaml` – mapa de NCs por módulo.

> **Guia para chats – Seção 2 (Escopo e referências)**  
> - **2 – Auditoria:** sempre ancorar qualquer parecer nesses arquivos; se um item não estiver mapeado em nenhum deles, registrar como lacuna de documentação.  
> - **1 – Desenvolvimento:** garantir que cada módulo indique claramente quais seções do Contrato v0 e da Interoperabilidade v0 ele implementa.  

---

## 3. Pré-requisitos de auditoria

Antes de iniciar a auditoria, garanta:

### 3.1. Documentos

- Versão atual do **0 – Contrato v0**.  
- Versão atual de **2 – Auditoria v0** (este documento).  
- Acesso aos módulos de desenvolvimento v0.1 e, quando existirem, v1.x retrabalhados.  
- (Opcional, mas recomendado) acesso a:
  - **3 – Interoperabilidade v0**;
  - **4 – Comercial v0**.

### 3.2. Repositórios e código

- Repositório de **infra Core** (ex.: `appgear-infra-core/`).  
- Repositório de **Suítes/Add-ons** (ex.: `appgear-suites/`).  
- Repositório de **documentação** (`appgear-docs/`).  
- Quando aplicável, repositórios de imagens customizadas citadas nos módulos.

### 3.3. Acesso a ambientes

- **Topologia A (opcional – PoC/Dev):**
  - acesso SSH/console ao host;
  - acesso à pasta `/opt/appgear` (ou equivalente).  

- **Topologia B (obrigatória – produção/enterprise):**
  - `kubectl` com permissão de leitura;
  - acesso de leitura ao Argo CD;
  - acesso de leitura ao Vault;
  - acesso de leitura ao Backstage;
  - acesso read-only à console do provedor (quando aplicável).

### 3.4. Pessoas envolvidas

- Representante de Arquitetura / Plataforma.  
- Representante de Segurança / Governança.  
- Representante de Produto / Comercial.  
- (Opcional) Representante de cliente, em auditorias externas.

> **Guia para chats – Seção 3 (Pré-requisitos)**  
> - **2 – Auditoria:** nunca iniciar uma auditoria formal sem garantir estes pré-requisitos; se algo faltar, registrar como risco metodológico.  

---

## 4. Como fazer – Roteiro de auditoria

### 4.1. Fase 0 – Preparação

1. Abrir um **registro de auditoria** (issue, ticket ou documento) com:
   - escopo (módulos, ambientes, datas);
   - equipe envolvida;
   - objetivo (ex.: homologar cluster `ag-br-core-prod` para produção).  
2. Clonar/atualizar os repositórios:
   - `appgear-infra-core/`;
   - `appgear-suites/`;
   - `appgear-docs/`.  
3. Registrar as hashes de commit relevantes (documentos e infraestrutura) na abertura da auditoria.

---

### 4.2. Fase 1 – Auditoria global cross-módulos

Nesta fase você avalia a **arquitetura como um todo**, independente de módulos individuais.

#### 4.2.1. Stack Core e Suítes

1. Confirmar se todos os componentes Core estão implantados conforme o Contrato v0  
   (Traefik, Kong, Istio, Tailscale, Ceph, Vault, Prometheus, Loki, Grafana, Open/CloudCost, Lago, Postgres, Redis, Qdrant, etc.).  
2. Verificar se as **Suítes** (Factory, Brain, Operations, Guardian) utilizam a pilha Core, sem recriar componentes equivalentes (evitar “shadow Core”).

#### 4.2.2. Topologias e multi-tenancy

1. Confirmar se o cluster de produção segue o padrão de **Topologia B**:
   - GitOps (Argo) como **fonte de verdade**;
   - Istio com mTLS;
   - vCluster por workspace;
   - Vault como fonte de segredos;
   - KEDA para Scale-to-Zero;
   - Tailscale para conectividade híbrida.  
2. Avaliar o modelo de multi-tenancy:
   - isolamento por `tenant_id` e `workspace_id`;
   - ausência de vazamento entre tenants, inclusive em serviços multi-tenant lógicos (Airbyte, etc.).

#### 4.2.3. IA, RAG, agentes e LiteLLM

1. Verificar se **LiteLLM é o gateway único para LLMs**:
   - não deve haver chamadas diretas a providers em código/configs.  
2. Confirmar se:
   - RAG utiliza Qdrant/Meilisearch conforme contrato;
   - agentes são orquestrados via Flowise/LiteLLM/n8n, com segurança adequada.  
3. Avaliar isolamento de:
   - CDEs, agentes, pipelines RAG, dados sensíveis.

#### 4.2.4. Observabilidade e FinOps

1. Verificar a presença de:
   - Prometheus, Grafana, Loki, OpenCost, Lago (ou equivalentes).  
2. Validar:
   - `ScaledObjects` KEDA para add-ons pesados, exceto se explicitamente 24/7 em **4 – Comercial**;
   - dashboards de custo por workspace/suíte.

#### 4.2.5. Governança, segurança e identidade

1. Confirmar:
   - Keycloak como IdP único;
   - midPoint como IGA.  
2. Verificar:
   - OpenFGA/OPA para autorização;
   - Falco (ou equivalente) para monitoramento runtime.  
3. Checar isolamento por vCluster e uso de OPA tanto em deploy quanto em runtime.  
4. Verificar integração com SignServer, Tika, Gotenberg quando o caso envolver Legal/Contracts.

#### 4.2.6. Documentos e repositórios

1. Confirmar que:
   - `0 – Contrato v0` está versionado em `docs/architecture/0-contrato/0-Contrato-v0.md`;
   - `2 – Auditoria v0` está em `docs/architecture/2-auditoria/2-Auditoria-v0.md`;
   - `3 – Interoperabilidade v0` e `4 – Comercial v0` estão em suas respectivas pastas.  
2. Verificar:
   - se todos os documentos referenciam explicitamente o Contrato v0;
   - se a versão (`v0`) está correta nos cabeçalhos.  
3. Checar separação de repositórios:
   - `appgear-infra-core/` (Core);
   - `appgear-suites/` (Suítes);
   - `appgear-docs/` (documentação).

---

### 4.3. Fase 2 – Auditoria por módulo (00–17)

Para cada módulo `MXX – Nome do módulo` de **1 – Desenvolvimento v0.x**:

1. Ler no **Contrato v0** em qual seção o módulo está ancorado (Segurança, Rede, DR, Suítes etc.).  
2. Ler o módulo v0.1:

   ```text
   docs/architecture/1-desenvolvimento/v0.1-raw/Modulo-XX-v0.1.md
   ```

3. (Se existir) Ler o módulo v1.0 retrofitado:

   ```text
   docs/architecture/1-desenvolvimento/v1.0-retrofit/Modulo-XX-v1.0.md
   ```

4. Preencher um checklist de auditoria para o módulo, podendo usar:
   - este documento como base;
   - o `Prompt-Motor-Auditoria-v1.md` para gerar:
     - texto de auditoria do módulo;
     - bloco YAML para `auditoria-modulos.yaml`;
     - checklist de auditoria.

---

### 4.4. Fase 3 – Auditoria de ambientes (Topologia B – Kubernetes)

1. Cruzar:
   - manifests GitOps;
   - estado real do cluster (via `kubectl`, Argo, Istio, Vault, Backstage).  
2. Validar, módulo a módulo, se o que está em produção:
   - segue as regras do **Contrato v0**;
   - respeita as decisões do **Manifesto de Retrofit v1**;
   - corresponde aos módulos retrofitados v1.x.  
3. Registrar:
   - NCs por módulo;
   - riscos residuais;
   - recomendações e plano de ação.

---

### 4.5. Fase 4 – Auditoria de implantação – Topologia A (Docker / PoC)

Topologia A **não é suportada para produção**. A auditoria deve apenas:

1. Confirmar que a estrutura do host de teste segue o padrão:

   ```text
   /opt/appgear
     .env              # sem segredos de produção
     docker-compose.yml
     /config
     /data
     /logs
   ```

2. Verificar se:
   - os serviços levantados são coerentes com ambiente de teste (Traefik, Postgres, Redis, Flowise, n8n, Directus, Appsmith, Metabase, LiteLLM etc.);
   - não há engenharia de segredos incompatível com o contrato (nunca usar chaves de produção em `.env`).  

3. Registrar que qualquer uso de Topologia A em **produção** configura **não conformidade**.

> **Guia para chats – Seção 4 (Roteiro)**  
> - **2 – Auditoria:** sempre seguir estas fases na ordem; se alguma for pulada, registrar claramente o motivo.

---

## 5. Como verificar (evidências e critérios de aceitação)

Para cada item auditado:

1. **Classificar o resultado**:
   - `OK`: aderente ao contrato;  
   - `NOK`: não aderente;  
   - `N.A.`: não aplicável no escopo auditado.  
2. **Registrar evidências**:
   - prints de tela (Argo, Grafana, Backstage, Vault etc.);
   - trechos de manifestos/Helm (sem segredos);
   - links para commits/PRs.  
3. **Classificar Criticidade**:
   - Itens que ferem **restrições estruturais** (exposição fora da cadeia de borda, uso de LLM sem LiteLLM, segredos em código) → **não conformidade crítica**;
   - Itens de melhor prática → **recomendação**.  
4. **Rastreabilidade**:
   - Sempre vincular o item a:
     - trecho do **Contrato v0**;
     - módulo(s) de desenvolvimento;
     - ambiente/cluster envolvido.

> **Guia para chats – Seção 5 (Verificação)**  
> - **2 – Auditoria:** se não houver evidência, o item não deve ser marcado como `OK`.  

---

## 6. Erros comuns de auditoria

Principais erros recorrentes:

- Auditar só infraestrutura, ignorando:
  - Suítes (Factory, Brain, Operations, Guardian);
  - fluxo AI-First (n8n/Flowise/Backstage).  
- Não verificar multi-tenancy lógico em serviços multi-tenant.  
- Ignorar o uso correto de LiteLLM, permitindo chamadas diretas a LLMs em código/configs.  
- Não diferenciar Topologia A (teste) de Topologia B (produção).  
- Não checar:
  - presença de KEDA/ScaledObjects em add-ons pesados;
  - uso de Tailscale para mesh VPN;
  - DR/backup efetivo (não só manifestos em Git).  
- Não registrar evidências suficientes (prints, PRs, manifestos).

> **Guia para chats – Seção 6 (Erros comuns)**  
> - **2 – Auditoria:** use esta lista como checklist negativo; se algum erro aparecer, registre explicitamente no relatório.

---

## 7. Onde salvar (localização oficial)

- Este arquivo deve ser salvo como:

  ```text
  appgear-docs/docs/architecture/2-auditoria/2-Auditoria-v0.md
  ```

- Ele referencia e depende de:

  ```text
  appgear-docs/docs/architecture/0-contrato/0-Contrato-v0.md
  appgear-docs/docs/architecture/3-interoperabilidade/3-Interoperabilidade-v0.md
  appgear-docs/docs/architecture/4-comercial/4-Comercial-v0.md
  ```

- Os módulos de desenvolvimento são mantidos como:

  ```text
  appgear-docs/docs/architecture/1-desenvolvimento/v0.1-raw/Modulo-XX-v0.1.md
  appgear-docs/docs/architecture/1-desenvolvimento/v1.0-retrofit/Modulo-XX-v1.0.md
  ```

- Em repositórios externos (clientes, parceiros), manter:
  - o mesmo nome de arquivo (`2-Auditoria-v0.md`);
  - referência explícita à versão do contrato usada (ex.: **0 – Contrato v0**).

> **Guia para chats – Seção 7 (Onde salvar)**  
> - **1–4:** sempre apontar para este caminho como “fonte oficial” da diretriz de auditoria.

---

## 8. Checklist Operacional de Auditoria (OK / NOK / N.A.)

> Preencha as colunas **OK / NOK / N.A.** com `X` e registre evidências mínimas (print, link de commit, trecho de manifesto).

### 8.1. Exemplo de Checklist Global (Arquitetura / Cross-módulos)

| ID  | Item                                                                                                 | Referência                       | OK | NOK | N.A. | Evidências / Observações |
| --- | ---------------------------------------------------------------------------------------------------- | -------------------------------- | -- | --- | ---- | ------------------------ |
| G01 | Stack Core implantada (Traefik, Kong, Istio, Tailscale, Ceph, Vault, Observabilidade, FinOps, etc.) | Contrato v0 / M00, M01, M02, M03 |    |     |      |                          |
| G02 | Suítes usam a pilha Core, sem componentes paralelos redundantes                                      | Contrato v0 / Módulos de Suítes  |    |     |      |                          |
| G03 | GitOps como fonte de verdade (Argo), sem bypass manual em produção                                   | Contrato v0 / M01, M02           |    |     |      |                          |
| G04 | Multi-tenancy implementado (tenant/workspace/vCluster)                                               | Contrato v0 / M02                |    |     |      |                          |
| G05 | LiteLLM como gateway único para LLMs (sem chamadas diretas)                                          | Contrato v0 / IA/RAG             |    |     |      |                          |
| G06 | KEDA/Scale-to-Zero para add-ons pesados, salvo exceções documentadas em 4 – Comercial                | Contrato v0 / M03 / Comercial    |    |     |      |                          |
| G07 | Documentação 0–4 versionada e referenciando explicitamente o Contrato v0                             | 0,1,2,3,4                        |    |     |      |                          |

### 8.2. Checklist por Módulo (MXX)

Use um checklist por módulo, por exemplo:

| ID     | Item                                                           | Referência (Contrato / Módulo) | OK | NOK | N.A. | Evidências / Observações |
| ------ | -------------------------------------------------------------- | ------------------------------ | -- | --- | ---- | ------------------------ |
| MXX-01 | Escopo do módulo está alinhado ao Contrato v0                  | 0 – Contrato v0 / MXX          |    |     |      |                          |
| MXX-02 | Exemplos não usam `:latest` em imagens                         | Manifestos / MXX               |    |     |      |                          |
| MXX-03 | Não há segredos em código, manifests ou `.env` de produção     | Contrato v0 / M05              |    |     |      |                          |
| MXX-04 | Labels obrigatórias de tenant/workspace/FinOps estão presentes | Contrato v0 / M00              |    |     |      |                          |
| MXX-05 | Interoperabilidade com módulos anteriores está documentada     | Módulos M00..M(XX-1)           |    |     |      |                          |

Este checklist pode ser expandido para cada módulo conforme o avanço do Retrofit v1.x e o preenchimento de `auditoria-modulos.yaml`.

---

*Fim da Diretriz de Auditoria AppGear v0.*
