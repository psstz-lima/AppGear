Perfeito, vou aplicar o diagnóstico e já te entregar o **Módulo 07 v0.1 em Markdown**, com:

* Formato `.md` (corrige G15 / Forma Canônica).
* Labels de FinOps, incluindo **`appgear.io/tenant-id: global`** em todos os recursos (corrige M00-3 / Rastreamento de Custos).
* Mantendo **resources** (requests/limits) explícitos no Deployment do Backstage.
* Reforçando interoperabilidade com **M03 (FinOps), M06 (Identidade), M13/M14 (Workspaces + Automação via N8n/Scaffolder)**.

Você pode salvar este conteúdo como:
`Módulo 07 v0.1.md`

---

# Módulo 07 – Portal Backstage e Integrações Core (v0.1)

> Arquivo: `Módulo 07 v0.1.md`
> Este módulo substitui o artefato legado `Módulo 07 v0.py` e corrige:
>
> * Formato (agora em Markdown);
> * Labels de FinOps (`appgear.io/tenant-id: global`);
> * Consolida Backstage como Portal, integrando M00–M06 e alimentando M13/M14.

---

## O que é

O **Módulo 07 – Portal Backstage e Integrações Core** define o **Portal Unificado da Plataforma**, implementado com **Backstage**, atuando como:

1. **Sistema Operacional da Plataforma**

   * UI central para construtores e administradores;
   * Agrega plugins de:

     * **AI Dependency Alert** (Flowise/LiteLLM);
     * **Private App Store** (midPoint + N8n/BPMN);
     * **FinOps Hub** (OpenCost + Lago + Grafana);
     * **OpenMetadata Bridge** (catálogo técnico);
     * **Workspace Hub** (Workspaces, vClusters, Suítes e módulos por cliente).

2. **Cliente principal da identidade (M06)**

   * Integra-se ao **Keycloak** via OIDC;
   * Respeita provisão/desprovisão e políticas de acesso do **midPoint**;
   * Orquestra permissões de acesso às Suítes e módulos.

3. **Interface do projeto de FinOps (M03)**

   * Exibe no próprio Backstage os custos vindos de **OpenCost** e **Lago**, por:

     * `tenant-id`
     * workspace
     * suíte / módulo
   * O próprio Backstage é rotulado com `appgear.io/tenant-id: global`, permitindo rastrear seu custo.

4. **Portal de criação de Workspaces (M13/M14)**

   * Usa **Scaffolder Templates** do Backstage para chamar **N8n/BPMN**, que:

     * criam workspaces;
     * disparam criação de vClusters;
     * configuram módulos de Suítes;
     * notificam times e aprovadores.

---

## Por que

1. **Substituir a PWA por um Portal padrão de mercado**

   * Backstage é a cabine de comando da plataforma;
   * centraliza acesso a Suítes, Workspaces, FinOps, CI/CD, catálogo, App Store.

2. **Governança de FinOps sobre o próprio Portal**

   * Backstage consome dados de FinOps e, ao mesmo tempo, **gera custo**;
   * Sem a label `appgear.io/tenant-id: global`, esse custo ficaria invisível;
   * Com as labels padronizadas, OpenCost/Lago conseguem atribuir o custo do Portal à “plataforma global”.

3. **Interoperabilidade M03 + M06 + M13 + M14**

   * M06: Backstage é o principal cliente de Keycloak/midPoint;
   * M03: Backstage consome OpenCost/Lago e mostra custos;
   * M13: Backstage é a UI oficial de criação e gestão de Workspaces/vClusters;
   * M14: Backstage chama N8n/BPMN via Scaffolder para orquestrar automações.

4. **Experiência de usuário moderna e coerente**

   * Plugins internos usam **Tailwind CSS + shadcn/ui** para UI;
   * Garante consistência visual entre App Store, Hub de Workspaces, FinOps e AI Alerts.

---

## Pré-requisitos

### Organizacionais

* **0 – Contrato v0** aprovado como fonte de verdade.
* Módulos anteriores implementados:

  * **M00** – Convenções, Repositórios e Nomenclatura.
  * **M01** – GitOps e Argo CD (App-of-Apps).
  * **M02** – Malha e Borda (Istio, Traefik, Coraza, Kong).
  * **M03** – Observabilidade e FinOps (Prometheus, Grafana, Loki, OpenCost, Lago).
  * **M04** – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, etc.).
  * **M05** – Segurança e Segredos (Vault, OPA, Falco, OpenFGA).
  * **M06** – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC).

### Infraestrutura (Topologia B – Kubernetes)

* Cluster `ag-<regiao>-core-<env>` com:

  * **Argo CD** configurado para o repo `appgear-gitops-core`;
  * **Istio** com mTLS STRICT nos namespaces de plataforma;
  * Cadeia **Traefik → Coraza → Kong → Istio** ativa;
  * Namespaces: `backstage`, `appgear-core`, `argocd`, `observability`, `security` etc.

* Serviços Core acessíveis:

  * `core-postgres` (DB Core);
  * `core-openmetadata`;
  * `core-opencost`, `core-lago`;
  * `core-argo-cd`, `core-argo-workflows`;
  * `core-flowise`, `core-litellm` (ou serviço equivalente);
  * `core-keycloak`, `core-midpoint`;
  * `core-n8n` (para BPMN/Workflows).

* Vault (M05):

  * Auth Kubernetes habilitado;
  * Policy `appgear-core-services`;
  * Paths `kv/appgear/*` e `database/creds/*` configurados.

### Ferramentas de desenvolvimento

* Node.js 18+ e pnpm ou Yarn.
* `@backstage/create-app` disponível (via npx).
* Acesso Git a:

  * `appgear-gitops-core` (infra GitOps);
  * `appgear-backstage` (código do Portal).

### Topologia A (opcional, Dev/PoC)

* Ubuntu LTS com Docker + docker-compose;
* Diretório base `/opt/appgear` com `.env` central padrão.

---

## Como fazer (comandos)

### 1. Estrutura GitOps do Módulo 07

No repositório `appgear-gitops-core`:

```bash
cd appgear-gitops-core

mkdir -p apps/core/backstage
mkdir -p apps/core/openmetadata
mkdir -p apps/core/kong
```

Editar `apps/core/kustomization.yaml` (garantir inclusão):

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
    appgear.io/module: "mod7-portal-backstage"
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
    appgear.io/module: "mod7-portal-backstage"
EOF
```

Role no Vault:

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
    appgear.io/module: "mod7-portal-backstage"
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

> Segredos e tokens vêm do Vault via Vault Agent; não devem ser hardcoded.

---

### 4. Deployment + Service do Backstage (com resources + tenant-id)

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
    appgear.io/module: "mod7-portal-backstage"
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
    appgear.io/module: "mod7-portal-backstage"
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

### 5. OpenMetadata (labels de tenant) – shape mínimo

`apps/core/openmetadata/kustomization.yaml`:

```bash
cat > apps/core/openmetadata/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - namespace.yaml
  # Aqui podem ser referenciados manifests/HelmRelease oficiais do OpenMetadata
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
    appgear.io/module: "mod7-portal-backstage"
EOF
```

> Deployments/Services de `core-openmetadata` devem seguir o mesmo padrão de labels e tenant-id.

---

### 6. Rota `/backstage` em Kong (com tenant-id)

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
    appgear.io/module: "mod7-portal-backstage"
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

Incluir em `apps/core/kong/kustomization.yaml`:

```yaml
resources:
  - backstage-route.yaml
  # demais rotas...
```

---

### 7. Repositório `appgear-backstage` – Portal + Plugins (Tailwind + shadcn/ui)

No repo de aplicação:

```bash
git clone git@github.com:appgear/appgear-backstage.git
cd appgear-backstage
```

Se necessário, criar app:

```bash
npx @backstage/create-app@latest
# nome sugerido: appgear-backstage
```

#### 7.1 Tailwind CSS + shadcn/ui

```bash
pnpm add -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

`tailwind.config.js` (resumo):

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

> Os componentes shadcn/ui serão usados nos plugins internos.

#### 7.2 Criação dos plugins

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

#### 7.3 Scaffolder Templates chamando N8n (integração M13/M14)

Exemplo de template YAML (`packages/app/templates/workspace-create/template.yaml`):

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

No backend, endpoint `/scaffolder/workspace` chama o webhook do N8n (M14) que cria workspace, vCluster e aciona processos de automação.

---

### 8. Topologia A – Docker Compose (Dev/PoC)

Em `/opt/appgear/backstage`:

```bash
mkdir -p /opt/appgear/backstage
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

## Como verificar

1. **GitOps / Argo CD**

```bash
argocd app sync core-backstage
argocd app sync core-kong
argocd app sync core-openmetadata

argocd app get core-backstage
```

* Esperado: `Synced` e `Healthy`.

2. **Kubernetes / Istio**

```bash
kubectl get pods -n backstage
kubectl get svc -n backstage
```

* Pod `core-backstage` em `Running` com sidecar Istio;
* Service `core-backstage` expondo porta 80.

3. **Vault / Segredos**

```bash
kubectl exec -n backstage deploy/core-backstage -c backstage -it -- sh
ls /vault/secrets
cat /vault/secrets/oidc
cat /vault/secrets/db-creds
```

* Arquivos contendo variáveis de OIDC e credenciais de banco.

4. **Portal / SSO**

* URL: `https://core.<env>.<dominio_base>/backstage`
* Verificar fluxo de login via Keycloak e retorno autenticado.

5. **FinOps / Labels**

* Verificar labels:

  ```bash
  kubectl get deploy core-backstage -n backstage -o jsonpath='{.metadata.labels}'
  ```

  Deve incluir `appgear.io/tenant-id: global`.

* No painel OpenCost/Lago/Grafana, confirmar:

  * presença de custo agregado para `tenant-id = global` com itens de `core-backstage`;
  * Backstage aparecendo como consumidor de recursos.

6. **Plugins**

* **AI Dependency Alert**:

  * Acessar página de gestão de módulos/suítes;
  * Tentar desligar módulo com dependências;
  * Sistema deve exibir alerta IA e bloquear.

* **Private App Store**:

  * Acessar rota `/app-store`, solicitar app;
  * Verificar solicitação criada no midPoint/N8n.

* **FinOps Hub**:

  * Acessar `/finops`, visualizar custos por workspace/tenant/suite.

* **OpenMetadata Bridge**:

  * Acessar `/catalog-omd`, listar serviços e bancos com labels `appgear.io/*`.

7. **Scaffolder / N8n (M13/M14)**

* No Backstage, executar template `Criar Workspace AppGear`;
* Confirmar no N8n:

  * execução do fluxo correspondente;
  * criação de workspace e vCluster (M13);
  * disparo de automações (M14).

---

## Erros comuns

1. **Formatação legada (arquivo .py)**

   * Problema: manter M07 como script Python.
   * Correção: usar exclusivamente `Módulo 07 v0.1.md` como fonte oficial.

2. **Ausência de `appgear.io/tenant-id: global`**

   * Impacto: custo do Backstage não aparece no projeto de FinOps;
   * Correção: garantir a label em **Namespace, SA, ConfigMap, Deployment, Service e KongIngress**.

3. **Resources ausentes ou exagerados**

   * Backstage é Node.js com múltiplos plugins;
   * valores de v0 (requests: `250m/512Mi`, limits: `1000m/1Gi`) são baseline;
   * Ajustar após testes de carga (não remover resources).

4. **Segredos hardcoded em ConfigMap**

   * Qualquer token/clientSecret dentro do `app-config.yaml` é falha grave;
   * Todos os segredos devem vir do Vault via `vault.hashicorp.com/agent-inject-*`.

5. **Rota fora da cadeia Traefik → Coraza → Kong**

   * Expor Backstage via NodePort/Ingress direto viola o modelo de borda;
   * Correção: apenas `/backstage` via Kong.

6. **Plugin AI Dependency Alert sem Flowise/LiteLLM**

   * Erro 500 / timeout na verificação de dependências;
   * Verificar se `core-flowise` está saudável e se `FLOWISE_API_URL` + `FLOWISE_DEPENDENCY_FLOW_ID` estão corretos.

7. **Scaffolder sem integração real com N8n**

   * Template de Workspace apenas cria repositório, mas não chama N8n/BPMN;
   * Corrigir endpoint `appgearWorkspaceHub.apiUrl` e webhook configurado no N8n.

8. **Uso de Topologia A como produção**

   * Compose local não é resiliente nem observável como o cluster;
   * Deve ser usado apenas para desenvolvimento, demos e troubleshooting.

---

## Onde salvar

* **Contrato / Documentação**

  * Repositório: `appgear-contracts`
  * Caminho: `1 - Desenvolvimento v0.md`
  * Seção:

    ```md
    ### Módulo 07 – Portal Backstage e Integrações Core (v0.1)
    ```

    Colar TODO o conteúdo deste arquivo abaixo desse título.

* **GitOps Infra**

  * Repositório: `appgear-gitops-core`
  * Estrutura:

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
      backstage-route.yaml
    ```

* **Portal / Código Backstage**

  * Repositório: `appgear-backstage`

    ```text
    packages/app/
      src/App.tsx
      src/index.tsx        # import tailwind.css

    plugins/
      ai-dependency-alert/
      ai-dependency-alert-backend/
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

Com isso, o **Módulo 07 – Portal Backstage e Integrações Core** está retrabalhado como **v0.1**, em formato Markdown, com labels de FinOps (`appgear.io/tenant-id: global`) e interoperabilidade com M03, M06, M13 e M14 explicitamente endereçadas.
