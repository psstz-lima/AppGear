# Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)

Versão: v0.2

### Atualizações v0.2

- Centraliza SSO/identidade com claims `tenant_id`/`workspace_id` propagadas a portais e APIs.


### Premissas padrão (v0.2)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Centraliza identidade de usuários, clientes e sistemas.
Padroniza Keycloak, federação com IdPs externos, provisionamento (midPoint) e modelo de papéis/regra de acesso (RBAC/ReBAC) por tenant/workspace. 

---

## O que é

Este módulo define a **camada de Identidade & SSO** da plataforma **AppGear** na **Topologia B (Kubernetes)**, composta por:

1. **Keycloak (`core-keycloak`)** 

   * Provedor de identidade (IdP) e SSO único da plataforma.
   * Realm único `appgear` com:

     * Roles globais: `platform-admin`, `workspace-owner`, `workspace-member`, `workspace-viewer`.
     * Grupos por workspace (`ws:<workspace_id>:owner`, etc.).
     * Atributos `workspace_ids` e `tenant_id` expostos como claims no token (ID/Access Token).

2. **midPoint (`core-midpoint`)** 

   * Camada de **IGA (Identity Governance & Administration)**:

     * Governa ciclo de vida (joiner/mover/leaver) de usuários e grupos.
     * Provisiona e reconcilia identidades no Keycloak.

3. **RBAC/ReBAC via OpenFGA (`core-openfga`)**

   * Modelo de autorização **ReBAC** para `user`, `workspace`, `app`, `resource`. 
   * Consome `workspace_id` e `tenant_id` emitidos pelo Keycloak para decisões de acesso.

4. **Governança & FinOps**

   * Todos os Deployments e Services deste módulo (Keycloak, midPoint, job do modelo OpenFGA) possuem:

     * `appgear.io/tenant-id: global` (custo atribuído ao tenant global da plataforma);
     * `resources.requests/limits` coerentes com `JAVA_OPTS` das JVMs (Keycloak e midPoint). 

5. **Exposição via borda**

   * Keycloak acessível via `/sso` em `core.dev.appgear.local`.
   * midPoint acessível via `/midpoint` em `core.dev.appgear.local` (via Traefik → Coraza → Kong → Istio, conforme M02).

6. **Topologia A (opcional – laboratório)**

   * Compose mínimo para **laboratório/dev local**: Keycloak + midPoint + Postgres, sem caráter produtivo.

---

## Por que

1. **Conformidade com o Contrato v0 e M00 v0.1** 

   * Substitui o artefato anterior em Python (`Módulo 06 v0.py`) por **documento canônico `.md`**.
   * Alinha identidade/SSO ao padrão de governança, FinOps e documentação definido no Módulo 00.

2. **FinOps: IAM é custoso e deve ser atribuído ao tenant correto** 

   * Keycloak e midPoint são serviços **JVM com alto consumo de memória**.
   * `appgear.io/tenant-id: global` em Deployments/Services garante que ferramentas de FinOps
     (OpenCost/Lago, M03) aloque o custo da camada de IAM ao tenant global da plataforma,
     evitando “custos órfãos”.

3. **Governança de performance**

   * Sem `requests/limits` e `JAVA_OPTS` consistentes, Keycloak/midPoint podem consumir memória do nó e
     derrubar outros workloads (OOMKill).
   * Este módulo fixa um baseline de recursos e parâmetros JVM, garantindo previsibilidade
     e controle de noisy neighbors.

4. **Identidade & Autorização centralizadas**

   * Keycloak segue como **IdP único**; midPoint governa ciclo de vida e provisionamento. 
   * OpenFGA concentra o modelo ReBAC consumido por Backstage, APIs core e Suites.

5. **Multi-tenancy lógico e preparação para Workspaces (M13)**

   * Atributos `tenant_id` e `workspace_ids` no token permitem:

     * enforcement de RLS (Postgres, M04);
     * autorização ReBAC (OpenFGA, M05);
     * segregação de Workspaces (M13).

---

## Pré-requisitos

### Contratuais / Governança

* **0 – Contrato v0** como base de requisitos funcionais e não funcionais. 
* **Módulo 00 v0.1 – Convenções, Repositórios e Nomenclatura**:

  * Forma canônica `.md`;
  * Labels `appgear.io/*` obrigatórias (incluindo `appgear.io/tenant-id`);
  * Convenções para paths no Vault (`kv/appgear`, `database/creds/...`).

### Módulos anteriores implantados

* **Módulo 0 – Convenções e Topologias** (versão base).
* **Módulo 1 – GitOps/Argo CD** (App-of-Apps e `apps-core.yaml`).
* **Módulo 2 – Borda (Traefik/Coraza/Istio/Kong)**.
* **Módulo 3 – Observabilidade/FinOps** (Prometheus, Loki, Grafana, OpenCost, Lago).
* **Módulo 4 – Armazenamento/Bancos Core** (Ceph, Postgres, Redis, Qdrant).
* **Módulo 5 – Segurança e Segredos** (Vault, OPA, Falco, OpenFGA).

### Infraestrutura (Topologia B – Kubernetes)

* Cluster `ag-<regiao>-core-<env>` (ex.: `ag-br-core-dev`). 

* StorageClass `ceph-block` (para bancos de IAM, se usado).

* Namespaces:

  * `security` (IAM, Vault, OPA, Falco, OpenFGA, Keycloak, midPoint);
  * `appgear-core`, `observability`, `argocd` etc. já criados.

* `core-postgres.appgear-core.svc.cluster.local` ativo (M04).

### Segurança / Segredos (Vault – M05)

* Engine `database/` configurada para Postgres.
* Engine `kv/appgear` para configurações não-DB.
* Secrets gerados via Vault → Secrets/ExternalSecrets para: 

  * `core-keycloak-db` (user/pass DB).
  * `core-keycloak-admin` (admin user/pass).
  * `core-midpoint-db` (user/pass DB).
  * Segredos de clientes OIDC (Directus, Appsmith, N8n, Backstage, etc.) em `kv/appgear/sso/oidc-client-secrets`.

### Ferramentas

* `git`, `kubectl`, `kustomize`, `argocd`.
* `jq` e `curl` para testes de token e chamadas ao OpenFGA (opcional).

---

## KEDA e scale-to-zero para IAM (Keycloak/midPoint)

* **Padrão obrigatório:** todos os deployments de Keycloak e midPoint devem estar protegidos por `ScaledObject` com `minReplicaCount: 0` e `cooldownPeriod` curto (ex.: `90s`) para economizar custo em ambientes dev/pequeno porte.
* **Triggers recomendados:**

  * **HTTP** via add-on HTTP do KEDA (`scaledobject.keda.sh/hosts: sso.<dominio>`) com thresholds de RPS baixos (ex.: `targetPendingRequests: 5`).
  * **Métricas de sessão** do Prometheus (`keycloak_sessions_active`) para evitar cold-start excessivo em picos.
  * **Jobs de provisionamento** (midPoint) via `ScaledJob` usando fila (RabbitMQ/Redpanda) quando houver tarefas assíncronas.
* **Valores default nos charts:**

  * `values.yaml`/`kustomization.yaml` de Keycloak/midPoint devem trazer o bloco KEDA habilitado por padrão, sem flag opcional, incluindo:

    ```yaml
    keda:
      enabled: true
      pollingInterval: 15 # otimizado para ambientes pequenos
      cooldownPeriod: 90
      minReplicaCount: 0
      maxReplicaCount: 3
    ```
  * `ScaledObject` referenciando Service `keycloak-http` e `midpoint-http`, com label selector `app.kubernetes.io/name` consistente com o chart.
* **Governança:** registrar os parâmetros (trigger, `pollingInterval`, `cooldownPeriod`) na documentação do módulo e no repositório `guides/` (ver `guides/keda-scale-to-zero.md`).

---

## Como fazer (comandos)

> Todos os manifests devem ser versionados em Git (repositório **`appgear-gitops-core`**) e aplicados via Argo CD (GitOps), não diretamente via `kubectl apply` em produção. 

---

### 1. Estrutura GitOps do Módulo 06

No repositório `appgear-gitops-core`:

```bash
cd appgear-gitops-core

mkdir -p apps/core/identity
mkdir -p apps/core/keycloak
mkdir -p apps/core/midpoint
mkdir -p apps/core/identity/openfga-model
```

`apps/core/identity/kustomization.yaml`:

```bash
cat > apps/core/identity/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: security

resources:
  - ../keycloak
  - ../midpoint
  - ./openfga-model
EOF
```

---

### 2. Namespace `security` (forma canônica + tenant-id)

Se já existir via M05, este manifesto apenas garante labels e anotações corretas:

```bash
cat > apps/core/keycloak/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: security
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
EOF
```

---

### 3. `core-keycloak` – IdP/SSO único

#### 3.1 Kustomization

```bash
cat > apps/core/keycloak/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: security

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - ingressroute.yaml
  - configmap-realm-appgear.json.yaml
EOF
```

#### 3.2 ConfigMap do Realm `appgear` (claims `tenant_id` e `workspace_ids`)

```bash
cat > apps/core/keycloak/configmap-realm-appgear.json.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-keycloak-realm-appgear
  labels:
    app.kubernetes.io/name: core-keycloak
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
data:
  appgear-realm.json: |
    {
      "realm": "appgear",
      "enabled": true,
      "displayName": "AppGear Realm",
      "registrationAllowed": false,
      "rememberMe": true,
      "resetPasswordAllowed": true,
      "loginWithEmailAllowed": true,
      "duplicateEmailsAllowed": false,
      "roles": {
        "realm": [
          { "name": "platform-admin", "description": "Administrador global da plataforma" },
          { "name": "workspace-owner", "description": "Dono de workspace" },
          { "name": "workspace-member", "description": "Membro de workspace" },
          { "name": "workspace-viewer", "description": "Visualizador de workspace" }
        ]
      },
      "groups": [
        {
          "name": "ws:template:owner",
          "attributes": {
            "workspace_template": ["true"]
          }
        }
      ],
      "attributes": {
        "appgear.realm.version": "v0.1"
      },
      "userManagedAccessAllowed": true,
      "clients": [
        {
          "clientId": "backstage",
          "enabled": true,
          "publicClient": true,
          "protocol": "openid-connect",
          "redirectUris": [
            "https://portal.dev.appgear.local/backstage/*",
            "https://portal.stg.appgear.cloud/backstage/*",
            "https://portal.appgear.cloud/backstage/*"
          ],
          "webOrigins": [ "*" ],
          "attributes": {
            "pkce.code.challenge.method": "S256",
            "backchannel.logout.session.required": "true"
          }
        }
        // demais clients (directus, appsmith, n8n, etc.) são configurados
        // de forma semelhante, com secrets geridos pelo Vault.
      ],
      "clientScopes": [
        {
          "name": "appgear-workspace",
          "protocol": "openid-connect",
          "protocolMappers": [
            {
              "name": "workspace_ids",
              "protocol": "openid-connect",
              "protocolMapper": "oidc-usermodel-attribute-mapper",
              "consentRequired": false,
              "config": {
                "user.attribute": "workspace_ids",
                "claim.name": "workspace_ids",
                "jsonType.label": "String",
                "multivalued": "true",
                "id.token.claim": "true",
                "access.token.claim": "true"
              }
            },
            {
              "name": "tenant_id",
              "protocol": "openid-connect",
              "protocolMapper": "oidc-usermodel-attribute-mapper",
              "consentRequired": false,
              "config": {
                "user.attribute": "tenant_id",
                "claim.name": "tenant_id",
                "jsonType.label": "String",
                "multivalued": "false",
                "id.token.claim": "true",
                "access.token.claim": "true"
              }
            }
          ]
        }
      ]
    }
EOF
```

#### 3.3 Deployment do Keycloak (com tenant-id, resources e JAVA_OPTS)

```bash
cat > apps/core/keycloak/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-keycloak
  labels:
    app.kubernetes.io/name: core-keycloak
    app.kubernetes.io/instance: core-keycloak
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-keycloak
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-keycloak
        app.kubernetes.io/instance: core-keycloak
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:24.0
          args:
            - "start"
            - "--optimized"
            - "--hostname-strict=false"
            - "--import-realm"
          env:
            - name: KC_DB
              value: "postgres"
            - name: KC_DB_URL
              value: "jdbc:postgresql://core-postgres.appgear-core.svc.cluster.local:5432/keycloak"
            - name: KC_DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: core-keycloak-db
                  key: username
            - name: KC_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: core-keycloak-db
                  key: password
            - name: KEYCLOAK_ADMIN
              valueFrom:
                secretKeyRef:
                  name: core-keycloak-admin
                  key: username
            - name: KEYCLOAK_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: core-keycloak-admin
                  key: password
            - name: KC_PROXY
              value: "edge"
            - name: JAVA_OPTS
              value: "-Xms512m -Xmx768m -XX:+UseContainerSupport"
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
          volumeMounts:
            - name: realm-import
              mountPath: /opt/keycloak/data/import
      volumes:
        - name: realm-import
          configMap:
            name: core-keycloak-realm-appgear
            items:
              - key: appgear-realm.json
                path: appgear-realm.json
EOF
```

#### 3.4 Service e IngressRoute do Keycloak

`apps/core/keycloak/service.yaml`:

```bash
cat > apps/core/keycloak/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-keycloak
  labels:
    app.kubernetes.io/name: core-keycloak
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
spec:
  selector:
    app.kubernetes.io/name: core-keycloak
  ports:
    - name: http
      port: 8080
      targetPort: http
EOF
```

`apps/core/keycloak/ingressroute.yaml`:

```bash
cat > apps/core/keycloak/ingressroute.yaml << 'EOF'
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: core-keycloak
  namespace: security
  labels:
    app.kubernetes.io/name: core-keycloak
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`core.dev.appgear.local`) && PathPrefix(`/sso`)
      kind: Rule
      middlewares:
        - name: strip-sso-prefix
          namespace: appgear-core
      services:
        - name: core-keycloak
          port: 8080
  tls:
    certResolver: default
EOF
```

---

### 4. `core-midpoint` – IGA (Governança de Identidade)

#### 4.1 Kustomization

```bash
cat > apps/core/midpoint/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: security

resources:
  - deployment.yaml
  - service.yaml
  - ingressroute.yaml
  - configmap-midpoint-config.xml.yaml
EOF
```

#### 4.2 ConfigMap do midPoint

```bash
cat > apps/core/midpoint/configmap-midpoint-config.xml.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-midpoint-config
  labels:
    app.kubernetes.io/name: core-midpoint
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
data:
  system-configuration.xml: |
    <systemConfiguration xmlns="http://midpoint.evolveum.com/xml/ns/public/common/common-3">
      <name>AppGear System Configuration</name>
      <globalSecurityPolicyRef oid="00000000-0000-0000-0000-00000000sec0"/>
    </systemConfiguration>

  resource-keycloak.xml: |
    <resource xmlns="http://midpoint.evolveum.com/xml/ns/public/common/common-3">
      <name>Keycloak AppGear</name>
      <connectorRef oid="00000000-0000-0000-0000-00000000kc01"/>
      <connectorConfiguration>
        <!-- Detalhes sensíveis vêm do Vault e são aplicados via pipeline -->
      </connectorConfiguration>
      <schemaHandling>
        <objectType>
          <kind>account</kind>
          <displayName>Keycloak User</displayName>
        </objectType>
      </schemaHandling>
    </resource>
EOF
```

#### 4.3 Deployment do midPoint (tenant-id, resources, JAVA_OPTS)

```bash
cat > apps/core/midpoint/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-midpoint
  labels:
    app.kubernetes.io/name: core-midpoint
    app.kubernetes.io/instance: core-midpoint
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-midpoint
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-midpoint
        app.kubernetes.io/instance: core-midpoint
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: midpoint
          image: evolveum/midpoint:4.8
          env:
            - name: MP_DATABASE_TYPE
              value: "postgresql"
            - name: MP_DATABASE_HOST
              value: "core-postgres.appgear-core.svc.cluster.local"
            - name: MP_DATABASE_PORT
              value: "5432"
            - name: MP_DATABASE_NAME
              value: "midpoint"
            - name: MP_DATABASE_USERNAME
              valueFrom:
                secretKeyRef:
                  name: core-midpoint-db
                  key: username
            - name: MP_DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: core-midpoint-db
                  key: password
            - name: JAVA_OPTS
              value: "-Xms256m -Xmx512m -XX:+UseContainerSupport"
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              cpu: "200m"
              memory: "384Mi"
            limits:
              cpu: "750m"
              memory: "768Mi"
          volumeMounts:
            - name: midpoint-config
              mountPath: /opt/midpoint/var
      volumes:
        - name: midpoint-config
          configMap:
            name: core-midpoint-config
EOF
```

#### 4.4 Service e IngressRoute do midPoint

`apps/core/midpoint/service.yaml`:

```bash
cat > apps/core/midpoint/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-midpoint
  labels:
    app.kubernetes.io/name: core-midpoint
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
spec:
  selector:
    app.kubernetes.io/name: core-midpoint
  ports:
    - name: http
      port: 8080
      targetPort: http
EOF
```

`apps/core/midpoint/ingressroute.yaml`:

```bash
cat > apps/core/midpoint/ingressroute.yaml << 'EOF'
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: core-midpoint
  namespace: security
  labels:
    app.kubernetes.io/name: core-midpoint
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`core.dev.appgear.local`) && PathPrefix(`/midpoint`)
      kind: Rule
      middlewares:
        - name: strip-midpoint-prefix
          namespace: appgear-core
      services:
        - name: core-midpoint
          port: 8080
  tls:
    certResolver: default
EOF
```

---

### 5. Modelo ReBAC no OpenFGA (Identity Model)

#### 5.1 ConfigMap com modelo ReBAC

```bash
cat > apps/core/identity/openfga-model/configmap-openfga-identity-model.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-openfga-identity-model
  labels:
    app.kubernetes.io/name: core-openfga-identity-model
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
data:
  model.fga: |
    model
      schema 1.1

    type user

    type workspace
      relations
        define admin  as user
        define member as user or admin
        define viewer as member

    type app
      relations
        define owner     as user
        define workspace as workspace
        define admin     as owner or workspace.admin
        define editor    as admin or workspace.member
        define viewer    as editor or workspace.viewer

    type resource
      relations
        define parent     as resource
        define app        as app
        define workspace  as workspace
        define owner      as user or app.owner
        define editor     as owner or app.editor or workspace.admin
        define viewer     as editor or app.viewer or workspace.viewer
EOF
```

#### 5.2 Job de bootstrap do modelo no OpenFGA

```bash
cat > apps/core/identity/openfga-model/job-openfga-bootstrap-model.yaml << 'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: core-openfga-bootstrap-identity-model
  namespace: security
  labels:
    app.kubernetes.io/name: core-openfga-bootstrap-identity-model
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/bootstrap-type: "openfga-identity-model"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod6-identity-sso"
spec:
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-openfga-bootstrap-identity-model
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      restartPolicy: OnFailure
      containers:
        - name: openfga-bootstrap
          image: curlimages/curl:8.7.1
          command:
            - /bin/sh
            - -c
          env:
            - name: OPENFGA_ENDPOINT
              value: "http://core-openfga.security.svc.cluster.local:8080"
          args:
            - |
              set -e
              echo ">> Criando store 'appgear-identity' no OpenFGA..."
              STORE_ID=$(curl -s -X POST "${OPENFGA_ENDPOINT}/stores" \
                -H "Content-Type: application/json" \
                -d '{"name": "appgear-identity"}' | jq -r '.id')
              echo "Store ID: ${STORE_ID}"

              echo ">> (TODO) Converter model.fga em JSON e aplicar via API."
              # A pipeline de conversão FGA DSL -> JSON será detalhada
              # em versão posterior ou em módulo de automação específico.
          volumeMounts:
            - name: model
              mountPath: /model
      volumes:
        - name: model
          configMap:
            name: core-openfga-identity-model
            items:
              - key: model.fga
                path: model.fga
EOF
```

#### 5.3 Kustomization do submódulo OpenFGA Model

```bash
cat > apps/core/identity/openfga-model/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: security

resources:
  - configmap-openfga-identity-model.yaml
  - job-openfga-bootstrap-model.yaml
EOF
```

---

### 6. GitOps – Application `core-identity` (Argo CD)

Em `clusters/ag-<regiao>-core-<env>/apps-core.yaml` (M01), garantir o `Application`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-identity
  namespace: argocd
  labels:
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/module: "mod6-identity-sso"
    appgear.io/tenant-id: global
spec:
  project: default
  source:
    repoURL: git@github.com:appgear/appgear-gitops-core.git
    targetRevision: main
    path: apps/core/identity
  destination:
    server: https://kubernetes.default.svc
    namespace: security
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

### 7. Topologia A – Docker/Legacy (laboratório)

> Apenas para **laboratório/dev local**. Para ambientes com SLA usar somente Topologia B.

Em `/opt/appgear/sso`:

```bash
sudo mkdir -p /opt/appgear/sso
cd /opt/appgear/sso
```

`.env`:

```bash
cat > .env << 'EOF'
POSTGRES_USER=appgear
POSTGRES_PASSWORD=appgear
POSTGRES_DB=appgear_sso

KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin

MIDPOINT_DB=midpoint
MIDPOINT_DB_USER=midpoint
MIDPOINT_DB_PASSWORD=midpoint

JAVA_OPTS_KEYCLOAK=-Xms512m -Xmx768m
JAVA_OPTS_MIDPOINT=-Xms256m -Xmx512m
EOF
```

`docker-compose.sso.yml`:

```bash
cat > docker-compose.sso.yml << 'EOF'
version: "3.8"

services:
  core-postgres-sso:
    image: postgres:16
    container_name: core-postgres-sso
    env_file: .env
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - ../data/postgres-sso:/var/lib/postgresql/data
    networks:
      - appgear

  core-keycloak:
    image: quay.io/keycloak/keycloak:24.0
    container_name: core-keycloak
    depends_on:
      - core-postgres-sso
    env_file: .env
    environment:
      - KC_DB=postgres
      - KC_DB_URL=jdbc:postgresql://core-postgres-sso:5432/${POSTGRES_DB}
      - KC_DB_USERNAME=${POSTGRES_USER}
      - KC_DB_PASSWORD=${POSTGRES_PASSWORD}
      - KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN}
      - KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
      - KC_PROXY=edge
      - JAVA_OPTS=${JAVA_OPTS_KEYCLOAK}
    command: ["start-dev", "--hostname-strict=false"]
    ports:
      - "8082:8080"
    networks:
      - appgear

  core-midpoint:
    image: evolveum/midpoint:4.8
    container_name: core-midpoint
    depends_on:
      - core-postgres-sso
    env_file: .env
    environment:
      - MP_DATABASE_TYPE=postgresql
      - MP_DATABASE_HOST=core-postgres-sso
      - MP_DATABASE_PORT=5432
      - MP_DATABASE_NAME=${MIDPOINT_DB}
      - MP_DATABASE_USERNAME=${MIDPOINT_DB_USER}
      - MP_DATABASE_PASSWORD=${MIDPOINT_DB_PASSWORD}
      - JAVA_OPTS=${JAVA_OPTS_MIDPOINT}
    ports:
      - "8083:8080"
    networks:
      - appgear

networks:
  appgear:
    driver: bridge
EOF
```

Subir:

```bash
docker compose -f docker-compose.sso.yml up -d
```

---

## Como verificar

### 1. Argo CD / GitOps

```bash
argocd app sync core-identity
argocd app get core-identity
```

* Esperado: `Sync Status: Synced`, `Health: Healthy`.

### 2. Pods, Services e labels de FinOps

```bash
kubectl get pods,svc -n security -o wide

kubectl get deploy core-keycloak core-midpoint -n security -o yaml \
  | grep -A5 "appgear.io/tenant-id"
```

* Esperado: `appgear.io/tenant-id: global` em Deployments e Services.

### 3. Resources e eventos de OOM

```bash
kubectl describe deploy core-keycloak -n security | grep -A6 "Limits"
kubectl describe deploy core-midpoint -n security | grep -A6 "Limits"
kubectl get pods -n security
```

* Esperado: blocos `Requests`/`Limits` presentes, sem eventos `OOMKilled`.

### 4. Acesso ao SSO e midPoint via Borda

Navegador:

* `https://core.dev.appgear.local/sso/`
* `https://core.dev.appgear.local/midpoint/`

Verificar:

* Certificado TLS correto (Traefik).
* Tela de login do Keycloak.
* Console do midPoint acessível.

### 5. Claims `workspace_ids` e `tenant_id` nos tokens

Após autenticar em um client OIDC (ex.: Backstage):

```bash
ID_TOKEN="<cole_o_token_aqui>"

PAYLOAD=$(echo "$ID_TOKEN" | cut -d '.' -f2 | base64 -d 2>/dev/null || echo "err")
echo "$PAYLOAD" | jq .
```

* Esperado (exemplo):

  ```json
  "workspace_ids": ["acme-erp"],
  "tenant_id": "tenant-global"
  ```

(conforme atributos configurados no usuário e client scopes).

### 6. OpenFGA – checagem básica

```bash
OPENFGA_ENDPOINT="http://core-openfga.security.svc.cluster.local:8080"

curl -s -X POST "${OPENFGA_ENDPOINT}/stores/<STORE_ID>/check" \
  -H "Content-Type: application/json" \
  -d '{
    "tuple_key": {
      "user": "user:alice",
      "relation": "viewer",
      "object": "workspace:acme-erp"
    }
  }' | jq .
```

* Esperado: resposta JSON indicando se o acesso é permitido.

### 7. midPoint operacional

* Acessar `/midpoint`.
* Verificar se:

  * `system-configuration.xml` está ativo;
  * Recurso Keycloak aparece (ainda que como placeholder, até configuração completa).

---

## Erros comuns

1. **Ausência de `appgear.io/tenant-id` após retrofit**

   * Sintoma: custos de Keycloak/midPoint aparecem como “não alocados” em OpenCost/Lago.
   * Correção: revisar manifests de `core-keycloak`, `core-midpoint` e submódulo `openfga-model`, garantindo `appgear.io/tenant-id: global`.

2. **OOMKill em Keycloak/midPoint**

   * Sintoma: pods reiniciando com `OOMKilled`.
   * Causas:

     * `JAVA_OPTS` incompatíveis com `limits.memory`;
     * carga maior que o planejado.
   * Correção:

     * Ajustar `JAVA_OPTS` para caber dentro do limit;
     * aumentar `limits.memory` conscientemente (e revisar FinOps).

3. **Token sem `tenant_id` ou `workspace_ids`**

   * Sintoma: claims ausentes.
   * Causas:

     * atributos não configurados no usuário;
     * client scope `appgear-workspace` não associado ao client.
   * Correção:

     * adicionar atributos nos usuários/grupos;
     * associar o client scope aos clients relevantes.

4. **Job do OpenFGA falhando**

   * Sintoma: `core-openfga-bootstrap-identity-model` em estado `Error`.
   * Causas:

     * endpoint OpenFGA incorreto;
     * ausência de `jq` na imagem, conforme script exemplificado.
   * Correção:

     * validar `OPENFGA_ENDPOINT`;
     * ajustar imagem ou script para contemplar `jq`.

5. **Diferença de comportamento entre Topologia A e B**

   * Sintoma: fluxo funcionando em `localhost` (compose), mas falhando em `core.dev.appgear.local`.
   * Causa: ausência de Traefik/Istio na Topologia A.
   * Correção:

     * considerar Topologia A apenas para testes de laboratório;
     * validar fluxos completos somente na Topologia B.

6. **Segredos espalhados em ConfigMaps ou manifests**

   * Sintoma: credenciais de DB/clients OIDC aparecendo em YAML.
   * Correção:

     * mover segredos para Vault (M05) e consumi-los via Secrets/ExternalSecrets;
     * utilizar OPA (M05) para bloquear commits com segredos.

---

## Onde salvar

1. **Documento de governança (este módulo)**

   * Repositório: `appgear-docs` ou `appgear-contracts`.

   * Arquivo sugerido:

     * `Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC-ReBAC) v0.1.md`.

   * Deve ser referenciado em:

     * `1 - Desenvolvimento v0` como versão vigente do Módulo 06.

2. **Manifests GitOps (Topologia B)**

   * Repositório: `appgear-gitops-core`.
   * Estrutura recomendada:

     ```text
     apps/core/identity/
       kustomization.yaml
       openfga-model/
         kustomization.yaml
         configmap-openfga-identity-model.yaml
         job-openfga-bootstrap-model.yaml

     apps/core/keycloak/
       namespace.yaml
       kustomization.yaml
       deployment.yaml
       service.yaml
       ingressroute.yaml
       configmap-realm-appgear.json.yaml

     apps/core/midpoint/
       kustomization.yaml
       deployment.yaml
       service.yaml
       ingressroute.yaml
       configmap-midpoint-config.xml.yaml

     clusters/ag-<regiao>-core-<env>/apps-core.yaml
       # inclui Application core-identity
     ```

3. **Topologia A (laboratório)**

   * Host Linux:

     * `/opt/appgear/sso/.env`
     * `/opt/appgear/sso/docker-compose.sso.yml`
     * `/opt/appgear/data/postgres-sso/` (dados locais).

---

## Dependências entre os módulos

A relação deste Módulo 06 com os demais módulos AppGear deve ser respeitada para garantir uma implantação coerente:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Fornece:

    * forma canônica `.md`,
    * convenções de repositório (`appgear-gitops-core`, `appgear-docs`),
    * padrão de labels `appgear.io/*` (incluindo `appgear.io/tenant-id`),
    * regras de FinOps e governança (M00-3).

* **Módulo 01 – GitOps e Argo CD**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD como controlador GitOps,
    * `clusters/ag-<regiao>-core-<env>/apps-core.yaml`, onde este módulo registra o `Application core-identity`.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * malha de serviço com `mTLS STRICT`, protegendo o tráfego para Keycloak/midPoint/OpenFGA,
    * cadeia de borda (`Traefik → Coraza → Kong → Istio`) usada para expor `/sso` e `/midpoint`.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * **Depende deste módulo** para:

    * coletar métricas/logs e custo da camada de IAM (Keycloak, midPoint, OpenFGA model job) por `tenant-id`,
    * construir dashboards de autenticação/autorização e custos de segurança/plataforma.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, etc.)**

  * **Pré-requisito técnico** para este módulo:

    * `core-postgres` serve como banco de Keycloak e midPoint,
    * StorageClass `ceph-block` oferece persistência para bancos de IAM quando configurados com PVC.

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * **Pré-requisito direto**:

    * Vault armazena segredos de DB/admin e clientes OIDC,
    * OPA pode validar manifests deste módulo (segredos, labels, imagens `:latest`),
    * Falco monitora runtime dos pods de IAM,
    * OpenFGA é usado como backend de autorização ReBAC (modelo definido aqui).

* **Módulo 06 – Identidade e SSO (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05**.
  * Entrega:

    * Keycloak como IdP/SSO único da plataforma,
    * midPoint como IGA/governança de identidade,
    * modelo ReBAC de identidade no OpenFGA.

* **Módulos posteriores (exemplos: Backstage/Portal, Workspaces/M13, Suites, PWA)**

  * **Dependem deste módulo** para:

    * autenticação centralizada via Keycloak,
    * claims `tenant_id` e `workspace_ids` nos tokens,
    * autorização fina via OpenFGA,
    * governança de identidade via midPoint.

Em resumo:

* **M00 → M01 → M02 → M03 → M04 → M05 → M06 → (Backstage, Workspaces/M13, Suites, PWA, etc.)**

Sem o Módulo 06, a AppGear não possui uma camada padronizada de **Identidade & SSO**, o que inviabiliza autenticação centralizada, multi-tenancy lógico e autorização ReBAC para os módulos superiores.
