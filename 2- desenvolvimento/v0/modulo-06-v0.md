Segue o **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC) – v0.1**, já com:

* Forma canônica corrigida (Markdown, para `Módulo 06 v0.1.md`);
* Labels de FinOps adicionadas (`appgear.io/tenant-id: global` em todos os Deployments/Services);
* `resources.requests/limits` definidos para Keycloak e midPoint, com `JAVA_OPTS` compatíveis.

Este texto substitui integralmente o Módulo 06 v0 anterior (arquivo `.py`).

---

# Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC) – v0.1

> Módulo 06 do **1 - Desenvolvimento v0**.
> Este documento substitui o artefato anterior em Python (`Módulo 06 v0.py`) e passa a ser a única fonte de verdade para o módulo de Identidade e SSO.
> Alinhado ao **0 - Contrato v0** e ao **Módulo 00 v0.1** (forma canônica, FinOps e governança).

---

## 1. O que é

Este módulo define a **arquitetura de Identidade e SSO** da plataforma, composta por:

1. **Keycloak (`core-keycloak`)**

   * Provedor de identidade (IdP) e SSO único da plataforma.
   * Realm único `appgear` com:

     * Roles globais: `platform-admin`, `workspace-owner`, `workspace-member`, `workspace-viewer`.
     * Grupos por workspace (ex.: `ws:<workspace_id>:owner`).
     * Atributos `workspace_ids` e `tenant_id` expostos como claims no token.

2. **midPoint (`core-midpoint`)**

   * Camada de **IGA (Identity Governance & Administration)**:

     * Governa ciclo de vida de usuários, grupos e acessos (joiner/mover/leaver).
     * Provisiona e reconcilia identidades no Keycloak.

3. **RBAC/ReBAC via OpenFGA (`core-openfga`)**

   * Modelo de autorização **ReBAC** para `user`, `workspace`, `app`, `resource`.
   * Consome `workspace_id` e `tenant_id` do token emitido pelo Keycloak.

4. **Governança e FinOps**

   * Todos os Deployments e Services do módulo (Keycloak/midPoint/OpenFGA model job) possuem:

     * `appgear.io/tenant-id: global` (atribuição de custo à camada de plataforma).
     * `resources.requests/limits` definidos, com `JAVA_OPTS` compatíveis para evitar estouro de memória.

5. **Exposição via Borda**

   * Keycloak acessível via `/sso` em `core.dev.appgear.local`.
   * midPoint acessível via `/midpoint` em `core.dev.appgear.local`.

6. **Modo Legacy / Topologia A (opcional)**

   * Compose mínimo para laboratório: Keycloak + midPoint + Postgres, sem caráter produtivo.

---

## 2. Por que

Atende diretamente às exigências do **0 - Contrato v0** e corrige os pontos levantados no diagnóstico profundo do Módulo 06 v0:

1. **Forma Canônica (G15)**

   * O módulo agora é **Markdown (.md)**, auditável e versionável em Git, conforme **Módulo 00 v0.1**.

2. **FinOps (M00-3 / tenant-id)**

   * A camada de IAM (Keycloak/midPoint) é intensiva em recursos (especialmente memória por ser JVM).
   * Atribuir `appgear.io/tenant-id: global` aos Deployments e Services:

     * Garante correta alocação de custos de CPU/RAM ao **“Tenant Global”** da plataforma.
     * Evita que Keycloak/midPoint apareçam como "custos órfãos" nas ferramentas de FinOps (OpenCost, Lago, etc.).

3. **Governança de Performance (M00-3 / resources)**

   * Sem `resources.requests/limits`, a JVM pode consumir toda a memória do nó, causando:

     * OOMKill de pods de outros serviços;
     * Instabilidade geral do cluster.
   * Este módulo define **requests/limits explícitos** e `JAVA_OPTS` coerentes com os limites, garantindo:

     * Previsibilidade de uso (FinOps);
     * Estabilidade (noisy neighbor control).

4. **Identidade & Autorização (M06-1, M06-3)**

   * Mantém Keycloak como **IdP único** e midPoint como IGA, conforme o contrato.
   * Mantém e documenta a integração conceitual com OpenFGA (modelo ReBAC).

5. **Multi-tenancy lógico (Impacto no M13)**

   * Reforça o uso de atributos `tenant_id` e `workspace_ids` no token.
   * Prepara a base para o Módulo 13 (Workspaces/vCluster) e para o enforcement de RLS no Módulo 04 (Postgres) e ReBAC no Módulo 05 (OpenFGA).

---

## 3. Pré-requisitos

### Contratuais / Governança

* **0 - Contrato v0** como fonte de verdade de requisitos funcionais e não-funcionais.
* **Módulo 00 v0.1** aplicado (forma canônica, labels, FinOps).
* Módulos anteriores implantados:

  * **Módulo 0 – Convenções e Topologias**.
  * **Módulo 1 – GitOps/Argo CD**.
  * **Módulo 2 – Borda (Traefik/Coraza/Istio/Kong)**.
  * **Módulo 3 – Observabilidade/FinOps** (OpenCost, etc.).
  * **Módulo 4 – Armazenamento/Bancos Core** (Postgres/Redis/Qdrant/Ceph).
  * **Módulo 5 – Segurança e Segredos** (Vault, OPA, Falco, OpenFGA).

### Infraestrutura (Topologia B – K8s)

* Cluster `ag-<regiao>-core-<env>` (ex.: `ag-br-core-dev`).
* Storage Classes:

  * `ceph-block` para DBs e volumes persistentes.
* Namespaces:

  * `security` para IAM e segurança (Vault, OPA, Falco, OpenFGA, Keycloak, midPoint).
* Postgres core (`core-postgres.appgear-core.svc.cluster.local`) operacional.

### Segurança / Segredos

* Vault já configurado (Módulo 5) com:

  * Engine `database/` para Postgres.
  * Engine `kv/appgear` para configurações não-DB.
* Segredos a serem gerados via Vault → Secrets (ou ExternalSecrets):

  * `core-keycloak-db` (username/password).
  * `core-keycloak-admin` (username/password).
  * `core-midpoint-db` (username/password).
  * Segredos de clientes OIDC (Directus, Appsmith, N8n, Backstage) em `kv/appgear/sso/oidc-client-secrets`.

### Ferramentas

* `git`, `kubectl`, `kustomize`, `argocd` CLI.
* `jq` e `curl` para testes de token e OpenFGA (opcional).

---

## 4. Como fazer (comandos)

> Abaixo, a implementação para **Topologia B (Kubernetes/GitOps)** e, ao final, o compose de laboratório da **Topologia A**.

---

### 4.1 Estrutura GitOps do Módulo 06

No repositório `webapp-ia-gitops-core`:

```bash
cd webapp-ia-gitops-core

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

### 4.2 Namespace `security` (forma canônica + tenant-id)

Se já existir via Módulo 5, o manifesto é idempotente; aqui reforçamos labels exigidas pelo M00-3:

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

### 4.3 core-keycloak – IdP/SSO único

#### 4.3.1 Kustomization

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

#### 4.3.2 Realm `appgear` (ConfigMap) – com atributos `tenant_id` e `workspace_ids`

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
        // demais clients (directus, appsmith, n8n, etc.) seguem forma semelhante,
        // com secrets gerenciados pelo Vault em pipelines específicas.
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

#### 4.3.3 Deployment do Keycloak – com tenant-id, resources e JAVA_OPTS

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

#### 4.3.4 Service e IngressRoute do Keycloak – com tenant-id

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

### 4.4 core-midpoint – IGA (Governança de Identidade)

#### 4.4.1 Kustomization

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

#### 4.4.2 ConfigMap do midPoint

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

#### 4.4.3 Deployment do midPoint – com tenant-id, resources e JAVA_OPTS

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

#### 4.4.4 Service e IngressRoute do midPoint – com tenant-id

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

### 4.5 Modelo ReBAC no OpenFGA (Identity Model)

#### 4.5.1 ConfigMap com modelo FGA

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

#### 4.5.2 Job de bootstrap do modelo – com tenant-id

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

#### 4.5.3 Kustomization do submódulo OpenFGA Model

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

### 4.6 Topologia A – Docker/Legacy (laboratório)

Em `/opt/webapp-ia/sso`:

```bash
sudo mkdir -p /opt/webapp-ia/sso
cd /opt/webapp-ia/sso
```

`.env` (apenas para laboratório):

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
      - webapp-ia

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
      - webapp-ia

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
      - webapp-ia

networks:
  webapp-ia:
    driver: bridge
EOF
```

Subir:

```bash
docker compose -f docker-compose.sso.yml up -d
```

---

## 5. Como verificar

### 5.1 Pods, services e labels FinOps

```bash
kubectl get pods,svc -n security -o wide
kubectl get deploy core-keycloak core-midpoint -n security -o yaml | grep -A5 "appgear.io/tenant-id"
```

Esperado: todos os Deployments e Services com `appgear.io/tenant-id: global`.

### 5.2 Resources e consumo em runtime

```bash
kubectl describe deploy core-keycloak -n security | grep -A6 "Limits"
kubectl describe deploy core-midpoint -n security | grep -A6 "Limits"
```

Verificar se:

* `requests`/`limits` estão presentes;
* Não há eventos de `OOMKilled` nos pods.

### 5.3 Acesso SSO e midPoint via Traefik

Navegador:

* `https://core.dev.appgear.local/sso/`
* `https://core.dev.appgear.local/midpoint/`

Verificar:

* Certificado TLS via Traefik;
* Login no Keycloak (`/sso`).
* Painel do midPoint (`/midpoint`).

### 5.4 Claims `workspace_ids` e `tenant_id`

Após login em um client OIDC (ex.: Backstage):

1. Capturar ID Token.
2. Decodificar:

```bash
ID_TOKEN="<colar_token_aqui>"

PAYLOAD=$(echo "$ID_TOKEN" | cut -d '.' -f2 | base64 -d 2>/dev/null || echo "err")
echo "$PAYLOAD" | jq .
```

Esperado:

```json
"workspace_ids": ["acme-erp"],
"tenant_id": "tenant-global"
```

(dependendo de como o usuário foi configurado no Keycloak).

### 5.5 Verificar modelo OpenFGA (checagem básica)

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

### 5.6 midPoint operacional

* Acessar `/midpoint`.
* Verificar se:

  * `system-configuration.xml` foi carregado;
  * Recurso Keycloak está visível (mesmo que em modo placeholder).

---

## 6. Erros comuns

1. **Ausência de `tenant-id` após retrofit**

   * Sintoma: OpenCost/FinOps não mostram Keycloak/midPoint atribuídos ao tenant global.
   * Causa: labels não aplicadas em todos os Deployments/Services.
   * Correção: revisar manifests conforme este módulo e fazer `argocd app sync core-identity`.

2. **OOMKill em Keycloak/midPoint**

   * Sintoma: pods reiniciando com `OOMKilled`.
   * Causas:

     * `JAVA_OPTS` incompatíveis com `limits.memory`.
     * Carga maior do que o dimensionado.
   * Correção:

     * Ajustar `JAVA_OPTS` (Xms/Xmx) para valores compatíveis com o `limit`.
     * Aumentar `limits.memory` conforme necessidade, mantendo FinOps consciente.

3. **Token sem `tenant_id`**

   * Sintoma: claim `tenant_id` ausente.
   * Causas:

     * Atributo `tenant_id` não configurado no usuário.
     * Client scope `appgear-workspace` não associado ao client.
   * Correção:

     * Configurar atributo no usuário.
     * Associar o client scope ao client relevante.

4. **Jobs do OpenFGA não completam**

   * Sintoma: Job `core-openfga-bootstrap-identity-model` fica em `Error`.
   * Causas:

     * Endpoint do `core-openfga` incorreto.
     * Falta de `jq` na imagem (depende da implementação).
   * Correção:

     * Ajustar endpoint.
     * Usar imagem com `jq` ou adequar o script.

5. **Configuração do midPoint não efetiva**

   * Sintoma: midPoint sobe, mas não reconhece o recurso Keycloak.
   * Causas:

     * Pasta de config montada incorretamente.
   * Correção:

     * Verificar `volumeMounts` e conteúdo do ConfigMap.

6. **Diferença entre topologia de laboratório (A) e produção (B)**

   * Sintoma: comportamento diferente entre `localhost` e `core.dev.appgear.local`.
   * Causas:

     * Falta de Traefik/Istio na Topologia A.
   * Correção:

     * Considerar Topologia A apenas para testes rápidos de Keycloak/midPoint, não para validar a malha de serviço.

---

## 7. Onde salvar

1. **Repositório GitOps Core – `webapp-ia-gitops-core`**

   * `apps/core/identity/`

     * `kustomization.yaml`
     * `openfga-model/`

       * `kustomization.yaml`
       * `configmap-openfga-identity-model.yaml`
       * `job-openfga-bootstrap-model.yaml`

   * `apps/core/keycloak/`

     * `namespace.yaml`
     * `kustomization.yaml`
     * `deployment.yaml`
     * `service.yaml`
     * `ingressroute.yaml`
     * `configmap-realm-appgear.json.yaml`

   * `apps/core/midpoint/`

     * `kustomization.yaml`
     * `deployment.yaml`
     * `service.yaml`
     * `ingressroute.yaml`
     * `configmap-midpoint-config.xml.yaml`

   * Em `clusters/ag-<regiao>-core-<env>/apps-core.yaml` (Módulo 1), garantir o Application:

   ```yaml
   - apiVersion: argoproj.io/v1alpha1
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
         repoURL: https://github.com/appgear/webapp-ia-gitops-core.git
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

2. **Repositório de documentação/contrato**

   * Salvar este arquivo como:
     `Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC-ReBAC) v0.1.md`.
   * Referenciá-lo em `1 - Desenvolvimento v0.md` como a versão vigente do Módulo 06.

3. **Topologia A (laboratório)**

   * Servidor Linux:

     * `/opt/webapp-ia/sso/.env`
     * `/opt/webapp-ia/sso/docker-compose.sso.yml`
     * `/opt/webapp-ia/data/postgres-sso/` (dados locais).

Com este retrofit, o **Módulo 06** passa a estar **conforme** em:

* Forma Canônica (Markdown);
* Governança de FinOps (tenant-id);
* Governança de Performance (resources + JAVA_OPTS),

mantendo a arquitetura lógica de Identidade e SSO alinhada ao contrato e preparada para integrar Backstage (M7), Workspaces (M13) e os demais módulos.
