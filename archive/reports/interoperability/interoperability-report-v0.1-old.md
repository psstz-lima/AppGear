# Relatório de Interoperabilidade v0.1 (Módulos 00–17)

## Objetivo

Consolidar a referência cruzada dos módulos 00 a 17 (v0.1) para validar aderência ao Contrato/Interoperabilidade e evidenciar dependências críticas entre governança, serviços core, suítes e automações AI-first.

## Metodologia

- Revisão dos artefatos canônicos em Markdown para cada módulo v0.1.
- Identificação de premissas comuns (labels `appgear.io/*`, GitOps, Topologia A/B) e de integrações explícitas entre módulos.
- Organização dos achados por camadas (governança, rede/dados/segurança, serviços core/portal, suítes, multi-tenancy, pipelines, continuidade).

## Achados por bloco

### 1) Governança e orquestração base

- **M00** fixa nomenclatura, formato `.md` e labels obrigatórias, servindo como pré-requisito de conformidade para todos os módulos subsequentes.
- **M01** formaliza Argo CD/App-of-Apps como fonte única de verdade operacional e amarra os AppProjects Core/Suites/Workspaces, garantindo deploy coerente em Topologia B.

### 2) Rede, observabilidade, dados e segurança

- **M02** define a cadeia de borda **Traefik → Coraza → Kong → Istio** e mTLS STRICT na malha, padronizando entrada/saída e evitando bypass em serviços Core e Suítes.
- **M03** exige labels `appgear.io/*` e usa Prometheus/Loki/Grafana/OpenCost/Lago para FinOps por tenant/workspace, consumindo dados de rotulação de todos os módulos.
- **M04** consolida storage (Ceph) e bancos/brokers core (Postgres, Redis, Qdrant, RabbitMQ, Redpanda) com backups/snaps, sustentando serviços de IA, automação e suites.
- **M05** institui Vault (segredos), OPA (policy), Falco (runtime) e OpenFGA (autorização) como camada de segurança compartilhada, alimentando pipelines e serviços.
- **M06** centraliza identidade/SSO com Keycloak + midPoint e integra ReBAC via OpenFGA, expondo claims `tenant_id`/`workspace_id` para autorização fina em portais e APIs.

### 3) Portal e serviços core reutilizáveis

- **M07** posiciona o Backstage como portal unificado (FinOps, Workspaces, Suítes) autenticado no M06, consumindo dados de M03 e disparando automações M14.
- **M08** agrupa serviços core (LiteLLM, Flowise, N8n, Directus, Appsmith, Metabase, BPMN) expostos via Kong, consumindo bancos de M04, segurança de M05 e identidade de M06.

### 4) Suítes de produto

- **M09 Factory** usa N8n/Appsmith/Directus e infra de dados/segurança para CDEs, pipelines de dados (Airbyte), builders e multiplayer.
- **M10 Brain** orquestra RAG/LLM (Qdrant + Meilisearch + LiteLLM/Flowise) e AutoML (JupyterHub/MLflow), servindo agentes e APIs para demais módulos.
- **M11 Operations** conecta IoT/Geo-Ops, streaming Redpanda e RPA/KEDA, integrando com N8n/BPMN e armazenamento geoespacial do PostGIS.
- **M12 Guardian** cobre segurança/compliance/chaos, reutilizando Tika/Gotenberg/SignServer (M04) e integrações com LLM/Flowise (M08) e validações OPA/Falco (M05).

### 5) Multi-tenancy, pipelines AI-first e resiliência

- **M13** formaliza `tenant_id`/`workspace_id` e vCluster por workspace via ApplicationSet GitOps, provendo isolamento, quotas e rotulagem para FinOps/Auditoria.
- **M14** descreve pipeline **N8n → Git (workspaces) → Argo Events/Workflows → Argo CD → vCluster** com validações OPA (M05) e gatilhos de caos (M12), garantindo geração AI-first governada.
- **M15** define backup/DR com Velero + snapshots Ceph e integrações Vault/ExternalSecrets, cobrindo namespaces core e workspaces etiquetados.
- **M16** padroniza conectividade híbrida via Tailscale (Operator/Compose) com segredos no Vault e limites de recursos etiquetados para FinOps.
- **M17** fixa ordem de boot (Sync Waves), initContainers de dependências e reload automático (Stakater Reloader), reduzindo CrashLoopBackOff e suportando rotação de segredos do M05.

## Convergência e riscos

- **Interdependência explícita**: M07 (Portal), M14 (pipelines) e M13 (Workspaces) dependem de identidade (M06), segurança/policies (M05) e core services (M08), reforçando a necessidade de sincronismo de versões.
- **Cadeia de borda única**: qualquer exposição fora de Traefik → Coraza → Kong → Istio quebra requisitos de M02/M08 e invalida métricas/FinOps de M03.
- **Rotulagem obrigatória**: a ausência de `appgear.io/tenant-id` ou `workspace-id` em manifests de suites e pipelines prejudica FinOps (M03) e enforcement OPA (M05).
- **Operação coordenada**: DR (M15) e Resiliência (M17) precisam das classes de storage/labels do M04 e das políticas de segurança do M05 para restaurar segredos e manter ordem de boot.

## Recomendações

1. Criar checklists GitOps que validem labels `appgear.io/*`, uso de Kong/IngressClass e dependências de banco/segredos antes de merge em repositórios Core/Suites/Workspaces.
2. Versionar alinhamentos entre Backstage (M07), N8n/Flowise (M08) e pipelines AI-first (M14) para evitar incompatibilidades de plugins ou schemas.
3. Priorizar rollout do M17 junto aos módulos de segurança (M05) e dados (M04) para garantir boot ordenado e reload automático em rotação de credenciais.
4. Estabelecer janelas regulares de teste de restore (M15) combinando DR + Chaos (M12) para validar recuperação ponta a ponta em vClusters críticos.
