# M07 – Portal Backstage e Integrações Core (v0.3)

> [!IMPORTANT]
> Este documento define o **Módulo 07 (M07)** da arquitetura AppGear na linha v0.3.  
> Deve ser lido em conjunto com:
> - `docs/architecture/contract/contract-v0.md`
> - `docs/architecture/audit/audit-v0.md`
> - `docs/architecture/interoperability/interoperability-v0.md`
> - `docs/architecture/interoperability/resources/fluxos-ai-first.md`
> - `docs/architecture/interoperability/resources/mapa-global.md`

Versão do módulo: v0.3  
Compatibilidade: linha v0 / v0.3  

---

## Contexto v0.3

### Padronização v0.3

- `.env` centralizado em `/opt/appgear/.env` (Topologia A) ou segredos via Vault/ExternalSecrets (Topologia B); apenas `.env.example` permanece versionado.
- Cadeia obrigatória `Traefik (TLS passthrough SNI) → Coraza WAF → Kong → Istio IngressGateway → Service Mesh` com mTLS **STRICT**, registrando exceções no quadro de monitoramento.
- Stack integrada sob controle GitOps via ArgoCD com **ApplicationSet list-generator** e labels `appgear.io/*`; App-of-Apps fica restrito ao bootstrap do Argo CD.
- Trilha CI/CD v1.1 com MAPA_NC → PLANO_CORRECAO → MODULO_REESCRITO → CHECKLIST e artefatos em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` com hash SHA-256 de SBOM.

---

# Módulo 07 – Portal Backstage e Integrações Core

Versão: v0.3

### Atualizações v0.3

- Convergido para o baseline `development/v0.3/stack-unificada-v0.3.yaml`, sem ampliar o escopo funcional previsto na linha v0.
- Cadeia Traefik → Coraza → Kong → Istio com mTLS STRICT e labels `appgear.io/*` permanece obrigatória para este módulo.
- Publicação de artefatos padronizados e parecer automatizado da IA + RAPID/CCB conforme `guides/ai-ci-cd-flow.md` e `guides/integrated-report-procedure.md`.

### Estado atual (v0.3)

- Linha v0 permanece como baseline estável; esta versão consolida o retrofit previsto para v0.3 sem adicionar novas capacidades.
- Baseline técnico: `development/v0.3/stack-unificada-v0.3.yaml` + recomendações de interoperabilidade v0.1 (Traefik → Coraza → Kong → Istio, LiteLLM, KEDA).
- CI/CD e governança: gate automatizado de IA, artefatos em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` e registro de hashes SHA-256 e parecer RAPID/CCB conforme `guides/ai-ci-cd-flow.md` e `guides/integrated-report-procedure.md`.
- Labels `appgear.io/*` para FinOps/multi-tenancy e SBOMs rastreáveis são pré-condições de entrega.

- Usa Backstage como portal único autenticado (M06) e gatilho das automações M14.


### Premissas padrão (v0.3)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Define o Backstage como “portal de desenvolvedor / operador” da AppGear.
Integra plugins para provisionar workspaces, ver status de módulos, acionar pipelines, consultar docs e catálogos de serviços. 

---

## 1. O que é

O **Módulo 07 – Portal Backstage e Integrações Core** define o **Portal Unificado da Plataforma AppGear**, implementado com **Backstage**, atuando como:

1. **Sistema Operacional da Plataforma (Portal AppGear)**

   * Interface central para times de plataforma, produto e clientes internos.
   * Agrega plugins e integrações Core, incluindo:

     * **AI Dependency Alert** (Flowise / LiteLLM) – alerta de dependências críticas e bloqueio de ações de risco;
     * **Private App Store** (midPoint + N8n/BPMN) – catálogo interno de apps e fluxos de aprovação;
     * **FinOps Hub** (OpenCost + Lago + Grafana) – visão de custos por tenant, workspace, suíte e módulo;
     * **OpenMetadata Bridge** – ponte com o catálogo técnico;
     * **Workspace Hub** – visão central de Workspaces, vClusters, Suítes e módulos.

2. **Cliente principal de Identidade (M06)**

   * Backstage autenticado via **Keycloak** (OIDC).
   * Respeita o ciclo de vida de identidades governado pelo **midPoint**.
   * Reutiliza claims `tenant_id` e `workspace_ids` para autorização fina (OpenFGA, M05).

3. **Interface principal do FinOps (M03)**

   * Consome dados de **OpenCost** e **Lago** para exibir custos:

     * por `tenant-id`,
     * por workspace,
     * por suíte e módulo.
   * O próprio Backstage é rotulado com `appgear.io/tenant-id: global`, permitindo rastrear seu custo como parte da plataforma.

4. **Portal de criação de Workspaces (M13/M14)**

   * Usa **Scaffolder Templates** do Backstage para chamar **N8n/BPMN** que:

     * criam Workspaces e vClusters,
     * configuram módulos de Suítes,
     * disparam automações e notificações (M14).

5. **Base de UI interna da AppGear**

   * Plugins e páginas internas usam **Tailwind CSS + shadcn/ui**, garantindo consistência visual com demais produtos da plataforma.

---

## 2. Por que

1. **Substituição da PWA por um Portal padrão de mercado** 

   * Backstage é o “painel de controle” da AppGear: reúne catálogo, CI/CD, FinOps, App Store, AI Alerts, Workspaces e Suítes em um único ponto.

2. **Governança e FinOps sobre o próprio Portal**

   * O Portal consome dados de FinOps, mas também **gera custo relevante** (Node.js + plugins + DB).
   * Sem `appgear.io/tenant-id: global`, este custo ficaria invisível.
   * Com labels padronizadas, M03 (OpenCost/Lago) consegue atribuir claramente o custo de operação do Portal ao tenant global da plataforma.

3. **Integração entre M03, M06, M13, M14**

   * M06: Backstage é o principal cliente Keycloak/midPoint.
   * M03: Backstage é a UI oficial de FinOps.
   * M13: Backstage é a UI de Workspaces/vClusters.
   * M14: Backstage dispara N8n/BPMN via Scaffolder para automações de criação e gestão de ambientes.

4. **Experiência de usuário moderna e coerente**

   * Plugins internos com **Tailwind + shadcn/ui** evitam divergência de UI entre módulos.
   * Usuário tem um único ponto de entrada para todo o ecossistema AppGear (Suítes, Workspaces, Portais, automações).

5. **Alinhamento com o padrão de documentação e governança**

   * Substitui o artefato legado `Módulo 07 v0.py` por `Módulo 07 v0.1.md`. 
   * Aplica labels `appgear.io/*` e `resources` mínimos, alinhando o Portal a M00, M03, M04 e M05.

---

## 3. Pré-requisitos

### Organizacionais

* **0 – Contrato v0** aprovado como fonte de verdade. 
* Módulos anteriores implantados e operacionais:

  * **M00** – Convenções, Repositórios e Nomenclatura.
  * **M01** – GitOps e Argo CD (App-of-Apps).
  * **M02** – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong).
  * **M03** – Observabilidade e FinOps (Prometheus, Grafana, Loki, OpenCost, Lago).
  * **M04** – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, etc.).
  * **M05** – Segurança e Segredos (Vault, OPA, Falco, OpenFGA).
  * **M06** – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC).

### Infraestrutura – Topologia B (Kubernetes)

* Cluster `ag-<regiao>-core-<env>` com:

  * **Argo CD** configurado para o repo `appgear-gitops-core`;
  * **Istio** com mTLS STRICT STRICT nos namespaces de plataforma;
  * Cadeia **Traefik → Coraza → Kong → Istio** ativa;
  * Namespaces: `backstage`, `appgear-core`, `argocd`, `observability`, `security`, etc.

* Serviços Core acessíveis:

  * `core-postgres` (DB Core);
  * `core-openmetadata` (quando utilizado);
  * `core-opencost`, `core-lago`;
  * `core-argo-cd`, `core-argo-workflows`;
  * `core-flowise`, `core-litellm` (ou equivalentes de AI);
  * `core-keycloak`, `core-midpoint`;
  * `core-n8n` (para BPMN/Workflows).

### Segurança / Segredos (M05 – Vault)

* Auth Kubernetes habilitado no Vault.
* Policy `appgear-core-services`.
* Paths configurados:

  * `kv/appgear/*` (para segredos de OIDC, tokens de integração etc.);
  * `database/creds/*` (para credenciais dinâmicas de Postgres, inclusive `postgres-role-backstage`).

### Ferramentas de desenvolvimento

* Node.js 18+ e pnpm ou Yarn.
* `@backstage/create-app` disponível (via `npx`).
* Acesso Git a:

  * `appgear-gitops-core` (infra GitOps);
  * `appgear-backstage` (código do Portal).

### Topologia A (opcional – Dev/PoC local)

* Ubuntu LTS com Docker + docker-compose.
* Diretório base `/opt/appgear` com `.env` central.

---

## 4. Como fazer (comandos)

> Todos os passos de infraestrutura assumem o repositório **`appgear-gitops-core`** e aplicação via **Argo CD (GitOps)**.

---

### 1. Estrutura GitOps do Módulo 07

No repositório `appgear-gitops-core`:

```bash
cd appgear-gitops-core

mkdir -p apps/core/backstage
mkdir -p apps/core/openmetadata
mkdir -p apps/core/kong
```

Caso exista um `apps/core/kustomization.yaml`, garantir a inclusão (exemplo):

```yaml
resources:
  - backstage/
  - openmetadata/
  - kong/
```

---

### 2. Namespace e ServiceAccount do Backstage (com tenant-id)

`apps/core/backstage/kustomization.yaml`:

```bash
cat > apps/core/backstage/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: backstage

resources:
  - namespace.yaml
  - serviceaccount.yaml
  - config-backstage.yaml
  - deployment.yaml
  - service.yaml
EOF
```

`apps/core/backstage/namespace.yaml`:

```bash
cat > apps/core/backstage/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: backstage
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod07-portal-backstage"
EOF
```

`apps/core/backstage/serviceaccount.yaml`:

```bash
cat > apps/core/backstage/serviceaccount.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: core-backstage
  namespace: backstage
  labels:
    app.kubernetes.io/name: core-backstage
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod07-portal-backstage"
EOF
```

Role no Vault atrelada ao SA:

```bash
vault write auth/kubernetes/role/appgear-backstage \
  bound_service_account_names="core-backstage" \
  bound_service_account_namespaces="backstage" \
  policies="appgear-core-services" \
  ttl="1h"
```

---

### 3. ConfigMap do Backstage (app-config.yaml)

`apps/core/backstage/config-backstage.yaml`:

```bash
cat > apps/core/backstage/config-backstage.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-backstage-config
  labels:
    app.kubernetes.io/name: core-backstage
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod07-portal-backstage"
data:
  app-config.yaml: |
    app:
      title: AppGear Studio
      baseUrl: ${BACKSTAGE_BASE_URL}

    backend:
      baseUrl: ${BACKSTAGE_BASE_URL}
      listen:
        port: 7007
      cors:
        origin: ${BACKSTAGE_BASE_URL}
      database:
        client: pg
        connection:
          host: ${BACKSTAGE_PG_HOST}
          port: ${BACKSTAGE_PG_PORT}
          user: ${BACKSTAGE_PG_USER}
          password: ${BACKSTAGE_PG_PASSWORD}
          database: ${BACKSTAGE_PG_DB}

    auth:
      environment: production
      providers:
        oidc:
          production:
            clientId: ${BACKSTAGE_OIDC_CLIENT_ID}
            clientSecret: ${BACKSTAGE_OIDC_CLIENT_SECRET}
            metadataUrl: ${BACKSTAGE_OIDC_METADATA_URL}

    argocd:
      baseUrl: ${ARGO_PUBLIC_URL}
      appLocatorMethods:
        - type: config
          instances:
            - name: main
              url: ${ARGO_INTERNAL_URL}

    appgearFinops:
      opencost:
        baseUrl: ${OPEN_COST_URL}
      lago:
        baseUrl: ${LAGO_API_URL}
      grafana:
        baseUrl: ${GRAFANA_PUBLIC_URL}

    catalog:
      providers:
        openmetadata:
          apiUrl: ${OPENMETADATA_API_URL}
          auth:
            type: bearer
            token: ${OPENMETADATA_TOKEN}

    appgearAiDependencyAlert:
      flowiseApiUrl: ${FLOWISE_API_URL}
      dependencyFlowId: ${FLOWISE_DEPENDENCY_FLOW_ID}
      litellmBaseUrl: ${LITELLM_BASE_URL}

    appgearPrivateAppStore:
      midpointApiUrl: ${MIDPOINT_API_URL}
      midpointAuthToken: ${MIDPOINT_TOKEN}
      n8nWebhookUrl: ${N8N_WEBHOOK_URL}
      bpmnProcessId: ${BPMN_PROCESS_ID}

    appgearWorkspaceHub:
      apiUrl: ${WORKSPACE_API_URL}

    proxy:
      '/flowise':
        target: ${FLOWISE_API_URL}
      '/opencost':
        target: ${OPEN_COST_URL}
      '/lago':
        target: ${LAGO_API_URL}
      '/openmetadata':
        target: ${OPENMETADATA_API_URL}
      '/midpoint':
        target: ${MIDPOINT_API_URL}
      '/workspace':
        target: ${WORKSPACE_API_URL}
EOF
```

> Tokens e segredos vêm do Vault via Vault Agent; **não** devem ser codificados em texto plano.

---

### 4. Deployment + Service do Backstage (resources + tenant-id)

`apps/core/backstage/deployment.yaml`:

```bash
cat > apps/core/backstage/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-backstage
  labels:
    app.kubernetes.io/name: core-backstage
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod07-portal-backstage"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-backstage
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-backstage
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "appgear-backstage"
        vault.hashicorp.com/agent-inject-secret-oidc: "kv/data/appgear/sso/oidc-client-secrets"
        vault.hashicorp.com/agent-inject-template-oidc: |
          {{- with secret "kv/data/appgear/sso/oidc-client-secrets" -}}
          BACKSTAGE_OIDC_CLIENT_ID={{ .Data.data.client_id }}
          BACKSTAGE_OIDC_CLIENT_SECRET={{ .Data.data.client_secret }}
          BACKSTAGE_OIDC_METADATA_URL={{ .Data.data.metadata_url }}
          {{- end }}
        vault.hashicorp.com/agent-inject-secret-db-creds: "database/creds/postgres-role-backstage"
        vault.hashicorp.com/agent-inject-template-db-creds: |
          {{- with secret "database/creds/postgres-role-backstage" -}}
          BACKSTAGE_PG_USER={{ .Data.username }}
          BACKSTAGE_PG_PASSWORD={{ .Data.password }}
          {{- end }}
    spec:
      serviceAccountName: core-backstage
      containers:
        - name: backstage
          image: ghcr.io/backstage/backstage:latest
          imagePullPolicy: IfNotPresent
          env:
            - name: NODE_ENV
              value: production
            - name: BACKSTAGE_BASE_URL
              value: "https://core.${APPGEAR_ENV}.${APPGEAR_BASE_DOMAIN}/backstage"
            - name: BACKSTAGE_PG_HOST
              value: core-postgres.appgear-core.svc.cluster.local
            - name: BACKSTAGE_PG_PORT
              value: "5432"
            - name: BACKSTAGE_PG_DB
              value: "backstage"
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1000m"
              memory: "1Gi"
          volumeMounts:
            - name: app-config
              mountPath: /app/app-config.yaml
              subPath: app-config.yaml
      volumes:
        - name: app-config
          configMap:
            name: core-backstage-config
            items:
              - key: app-config.yaml
                path: app-config.yaml
EOF
```

`apps/core/backstage/service.yaml`:

```bash
cat > apps/core/backstage/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-backstage
  labels:
    app.kubernetes.io/name: core-backstage
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod07-portal-backstage"
spec:
  ports:
    - name: http
      port: 80
      targetPort: 7007
  selector:
    app.kubernetes.io/name: core-backstage
EOF
```

---

### 5. OpenMetadata (shape mínimo com tenant-id)

`apps/core/openmetadata/kustomization.yaml`:

```bash
cat > apps/core/openmetadata/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - namespace.yaml
EOF
```

`apps/core/openmetadata/namespace.yaml`:

```bash
cat > apps/core/openmetadata/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: appgear-core
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod07-portal-backstage"
EOF
```

> Os manifests específicos de `core-openmetadata` (operator/helm/etc.) devem seguir o mesmo padrão de labels e resources.

---

### 6. Rota `/backstage` em Kong (cadeia de borda)

`apps/core/kong/backstage-route.yaml`:

```bash
cat > apps/core/kong/backstage-route.yaml << 'EOF'
apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: core-backstage
  labels:
    app.kubernetes.io/name: core-backstage
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod07-portal-backstage"
route:
  methods:
    - GET
    - POST
    - PUT
    - PATCH
    - DELETE
  paths:
    - /backstage
upstream:
  serviceName: core-backstage.backstage.svc.cluster.local
  servicePort: 80
EOF
```

`apps/core/kong/kustomization.yaml` (exemplo):

```bash
cat > apps/core/kong/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - backstage-route.yaml
  # demais rotas...
EOF
```

---

### 7. Repositório `appgear-backstage` – Portal + Plugins (Tailwind + shadcn/ui)

No repositório de aplicação:

```bash
git clone git@github.com:appgear/appgear-backstage.git
cd appgear-backstage
```

Se for criar o app:

```bash
npx @backstage/create-app@latest
# sugerir nome: appgear-backstage
```

#### 7.1 Tailwind CSS + shadcn/ui

```bash
pnpm add -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

`tailwind.config.js` (exemplo mínimo):

```js
module.exports = {
  content: ['./packages/**/*.{ts,tsx,js,jsx}'],
  theme: { extend: {} },
  plugins: [],
};
```

Importar CSS (ex.: `packages/app/src/index.tsx`):

```ts
import '../styles/tailwind.css';
```

shadcn/ui:

```bash
pnpm dlx shadcn-ui@latest init
pnpm dlx shadcn-ui@latest add card button alert dialog input
```

> Esses componentes serão usados nos plugins internos (AI Dependency Alert, App Store, FinOps Hub, etc.).

#### 7.2 Criação dos plugins principais

```bash
pnpm backstage-cli create-plugin --name ai-dependency-alert
pnpm backstage-cli create-plugin --name private-app-store
pnpm backstage-cli create-plugin --name finops-hub
pnpm backstage-cli create-plugin --name openmetadata-bridge
pnpm backstage-cli create-plugin --name workspace-hub
```

Registrar rotas em `packages/app/src/App.tsx`:

```tsx
<FlatRoutes>
  <Route path="/ai-dependency-alert" element={<AiDependencyAlertPage />} />
  <Route path="/app-store" element={<PrivateAppStorePage />} />
  <Route path="/finops" element={<FinopsHubPage />} />
  <Route path="/catalog-omd" element={<OpenMetadataBridgePage />} />
  <Route path="/workspaces" element={<WorkspaceHubPage />} />
</FlatRoutes>
```

#### 7.3 Scaffolder Template chamando N8n (Workspaces)

`templates/workspace-create/template.yaml` (exemplo):

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: create-workspace
  title: Criar Workspace AppGear
  description: Cria workspace + vCluster via N8n/BPMN.
spec:
  owner: platform-team
  type: service

  parameters:
    - title: Dados do Workspace
      properties:
        workspaceId:
          type: string
          title: Workspace ID
        tenantId:
          type: string
          title: Tenant ID
          default: "global"
        suiteSet:
          type: array
          title: Suítes Ativadas
          items:
            type: string
            enum: [factory, brain, operations, guardian]
  steps:
    - id: call-n8n
      name: Chamar fluxo N8n
      action: http:backstage:request
      input:
        method: POST
        url: ${{ config.appgearWorkspaceHub.apiUrl }}/scaffolder/workspace
        body:
          workspaceId: ${{ parameters.workspaceId }}
          tenantId: ${{ parameters.tenantId }}
          suiteSet: ${{ parameters.suiteSet }}
  output:
    workspaceId: ${{ parameters.workspaceId }}
```

---

### 8. Topologia A – Docker Compose (Dev/PoC)

> Apenas para **desenvolvimento local / laboratório**. Produção deve usar Topologia B.

Em `/opt/appgear/backstage`:

```bash
sudo mkdir -p /opt/appgear/backstage
cd /opt/appgear/backstage
```

`.env`:

```bash
cat > .env << 'EOF'
BACKSTAGE_BASE_URL=http://localhost:7007
BACKSTAGE_PG_HOST=core-postgres
BACKSTAGE_PG_PORT=5432
BACKSTAGE_PG_DB=backstage
BACKSTAGE_PG_USER=backstage
BACKSTAGE_PG_PASSWORD=backstage

APPGEAR_ENV=dev
APPGEAR_BASE_DOMAIN=appgear.local
EOF
```

`docker-compose.backstage.yml`:

```bash
cat > docker-compose.backstage.yml << 'EOF'
version: "3.8"
services:
  core-postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: ${BACKSTAGE_PG_DB}
      POSTGRES_USER: ${BACKSTAGE_PG_USER}
      POSTGRES_PASSWORD: ${BACKSTAGE_PG_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data

  core-backstage:
    image: ghcr.io/backstage/backstage:latest
    environment:
      BACKSTAGE_BASE_URL: ${BACKSTAGE_BASE_URL}
      BACKSTAGE_PG_HOST: core-postgres
      BACKSTAGE_PG_PORT: ${BACKSTAGE_PG_PORT}
      BACKSTAGE_PG_DB: ${BACKSTAGE_PG_DB}
      BACKSTAGE_PG_USER: ${BACKSTAGE_PG_USER}
      BACKSTAGE_PG_PASSWORD: ${BACKSTAGE_PG_PASSWORD}
    depends_on:
      - core-postgres
    labels:
      traefik.enable: "true"
      traefik.http.routers.backstage.rule: "PathPrefix(`/backstage`)"
      traefik.http.services.backstage.loadbalancer.server.port: "7007"

volumes:
  pgdata: {}
EOF
```

Subir:

```bash
docker compose -f docker-compose.backstage.yml --env-file .env up -d
```

---

## 5. Como verificar

1. **GitOps / Argo CD**

```bash
argocd app sync core-backstage
argocd app sync core-kong
argocd app sync core-openmetadata

argocd app get core-backstage
```

* Esperado: `Sync Status: Synced` e `Health: Healthy`.

2. **Kubernetes / Istio**

```bash
kubectl get pods -n backstage
kubectl get svc -n backstage
```

* Esperado: pod `core-backstage` em `Running`, com sidecar Istio (se configurado).
* Service `core-backstage` expondo porta 80 → 7007.

3. **Vault / Segredos injetados**

```bash
kubectl exec -n backstage deploy/core-backstage -c backstage -it -- sh -c "ls /vault/secrets && cat /vault/secrets/oidc && cat /vault/secrets/db-creds"
```

* Esperado: arquivos `oidc` e `db-creds` com variáveis para OIDC e Postgres.

4. **Portal e SSO**

* Navegador: `https://core.<env>.<dominio_base>/backstage`
* Verificar:

  * Redirecionamento para Keycloak (M06);
  * Login;
  * Retorno autenticado ao Portal.

5. **FinOps / Labels**

```bash
kubectl get deploy core-backstage -n backstage -o jsonpath='{.metadata.labels}'
```

* Esperado: presença de `appgear.io/tenant-id: global`.

Em OpenCost/Lago/Grafana (M03):

* Verificar se:

  * `core-backstage` é contabilizado em `tenant-id = global`;
  * custos aparecem agregados corretamente.

6. **Plugins principais**

* **AI Dependency Alert**:

  * Simular tentativa de desligar módulo crítico com dependências;
  * Verificar se há alerta/erro retornado pela IA.

* **Private App Store**:

  * Acessar `/app-store`;
  * Solicitar app;
  * Confirmar criação de requisição no midPoint/N8n.

* **FinOps Hub**:

  * Acessar `/finops`;
  * Visualizar custos por tenant/workspace/suite.

* **OpenMetadata Bridge**:

  * Acessar `/catalog-omd`;
  * Listar serviços/bancos rotulados com `appgear.io/*`.

* **Workspace Hub** / Scaffolder:

  * Executar template `Criar Workspace AppGear`;
  * Confirmar disparo de fluxo N8n e registro de novo Workspace.

7. **Topologia A – Dev local**

* `docker ps` deve mostrar `core-postgres` e `core-backstage`.
* `http://localhost:7007/backstage` acessível (sem SSO completo, apenas para PoC).

---

## 6. Erros comuns

1. **Ausência de `appgear.io/tenant-id: global` em recursos do Portal**

   * Impacto: custos do Backstage ficam “não alocados” em OpenCost/Lago.
   * Correção: garantir a label em:

     * Namespace `backstage`,
     * ServiceAccount,
     * ConfigMap,
     * Deployment,
     * Service,
     * KongIngress.

2. **Resources ausentes ou inadequados**

   * Backstage consome recursos significativos; sem `requests/limits`:

     * risco de OOMKill ou competição com workloads de negócio.
   * Correção: manter baseline:

     * `requests: 250m/512Mi`,
     * `limits: 1000m/1Gi`,
       ajustando conforme perfil de uso, mas nunca removendo o bloco.

3. **Segredos hardcoded no `app-config.yaml`**

   * Qualquer `clientSecret`, `token` ou password ali é incidente de segurança.
   * Correção: mover todos os segredos para Vault (M05) e acessar via Vault Agent.

4. **Rota fora da cadeia Traefik → Coraza → Kong**

   * Expor Backstage via NodePort/Ingress direto viola o modelo de borda (M02).
   * Correção: usar apenas `/backstage` via Kong, respeitando a cadeia completa.

5. **Plugins AI/FinOps sem endpoints corretos**

   * Falhas 500 ou timeouts em páginas de AI Dependency Alert ou FinOps Hub.
   * Correção: revisar URLs (`FLOWISE_API_URL`, `OPEN_COST_URL`, `LAGO_API_URL`, `GRAFANA_PUBLIC_URL`) e saúde dos serviços core.

6. **Scaffolder sem integração real com N8n/M13/M14**

   * Template aparentemente executa, mas não cria Workspaces/vClusters reais.
   * Correção: garantir que o endpoint `appgearWorkspaceHub.apiUrl` chame o backend correto, que por sua vez dispara o webhook do N8n.

7. **Uso de Topologia A como se fosse produção**

   * Compose local não possui observabilidade/segurança equivalentes ao cluster.
   * Correção: restringir Topologia A a Dev/PoC; produção sempre em Topologia B.

---

## 7. Onde salvar

* **Documento de governança (este módulo)**

  * Repositório: `appgear-docs` ou `appgear-contracts`.
  * Arquivo sugerido:

    * `Módulo 07 – Portal Backstage e Integrações Core v0.1.md`.
  * Referenciar em:

    * `1 - Desenvolvimento v0` como módulo 07 oficial.

* **Manifests GitOps (Topologia B)**

  * Repositório: `appgear-gitops-core`.
  * Estrutura sugerida:

    ```text
    apps/core/backstage/
      kustomization.yaml
      namespace.yaml
      serviceaccount.yaml
      config-backstage.yaml
      deployment.yaml
      service.yaml

    apps/core/openmetadata/
      kustomization.yaml
      namespace.yaml

    apps/core/kong/
      kustomization.yaml
      backstage-route.yaml

    clusters/ag-<regiao>-core-<env>/apps-core.yaml
      # inclui Application core-backstage / core-kong / core-openmetadata (conforme design M01)
    ```

* **Portal / Código Backstage (aplicação)**

  * Repositório: `appgear-backstage`.
  * Pastas principais:

    ```text
    packages/app/
      src/App.tsx
      src/index.tsx        # import tailwind.css

    plugins/
      ai-dependency-alert/
      private-app-store/
      finops-hub/
      openmetadata-bridge/
      workspace-hub/

    templates/
      workspace-create/
        template.yaml

    styles/
      tailwind.css
    ```

* **Topologia A (Dev/PoC)**

  * Host: `/opt/appgear/backstage` com:

    * `.env`
    * `docker-compose.backstage.yml`
    * volume local de dados do Postgres.

---

## 8. Dependências entre os módulos

A relação deste Módulo 07 com os demais módulos da AppGear deve ser respeitada para garantir implantação ordenada e coerente:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Fornece:

    * forma canônica de documentação (`.md`),
    * convenções de repositório (`appgear-gitops-core`, `appgear-backstage`, `appgear-docs`),
    * padrão de labels `appgear.io/*` (incluindo `appgear.io/tenant-id`) aplicadas neste módulo,
    * regras de FinOps e governança.

* **Módulo 01 – GitOps e Argo CD**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD como controlador GitOps,
    * `clusters/ag-<regiao>-core-<env>/apps-core.yaml`, onde este módulo registra Applications (`core-backstage`, `core-kong`, `core-openmetadata`).

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * Istio com `mTLS STRICT STRICT`, garantindo tráfego seguro entre Portal e serviços core,
    * cadeia de borda (`Traefik → Coraza → Kong → Istio`) usada para expor `/backstage`.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * **Dependência mútua:**

    * M03 depende deste módulo para oferecer uma UI consolidada de FinOps no Portal;
    * M07 depende de M03 para obter métricas e custos de infraestrutura e aplicações (OpenCost, Lago, Grafana);
    * labels `appgear.io/tenant-id: global` neste módulo permitem atribuir custo do Portal ao tenant correto.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, etc.)**

  * **Pré-requisito técnico.**
  * Fornece:

    * `core-postgres` como banco do Backstage (e potencialmente de OpenMetadata),
    * StorageClass `ceph-block` para volumes persistentes.

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * **Pré-requisito direto.**
  * Fornece:

    * Vault como SSoT de segredos do Portal (credenciais de OIDC, DB, tokens de integrações),
    * OPA para validar manifests deste módulo (segredos, labels, uso de `latest` etc.),
    * Falco para monitorar runtime dos pods do Portal,
    * OpenFGA como backend de autorização fina (consumido indiretamente via M06/M13, quando aplicável).

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * **Pré-requisito direto.**
  * Fornece:

    * Keycloak como IdP/SSO para o Backstage,
    * midPoint para governança de identidades e grupos,
    * claims `tenant_id` e `workspace_ids` nos tokens, utilizadas pelos plugins do Portal.

* **Módulo 07 – Portal Backstage e Integrações Core (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06**.
  * Entrega:

    * Portal unificado da AppGear (Backstage),
    * plugins de AI, App Store, FinOps, catálogo técnico e Workspaces,
    * integração com N8n/BPMN para automações (M13/M14).

* **Módulos posteriores (ex.: M13 – Workspaces e vClusters; M14 – Automações e BPMN; Suítes; PWA)**

  * **Dependem deste módulo** para:

    * oferecer uma UI padrão (Backstage) para criação/gestão de Workspaces e Suítes,
    * expor scaffolder templates que acionam fluxos N8n/BPMN,
    * permitir que usuários/autorizadores utilizem SSO, FinOps e catálogo em um único Portal.

Em resumo:

* **M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → (M13, M14, Suítes, PWA, etc.)**

Sem o Módulo 07, a AppGear não possui um **Portal unificado** para operar o ecossistema, reduzindo visibilidade, governança e experiência de uso dos demais módulos.

---

## 9. Metadados
- Gerado automaticamente por CodeGPT
- Versão do módulo: v0.3
- Compatibilidade: full
- Data de geração: 2025-11-24
