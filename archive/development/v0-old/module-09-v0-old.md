# Módulo 09 – Suíte Factory

Versão: v0

Foca na “fábrica” de aplicações e integrações: pipelines de build/deploy, scaffolding, geradores de apps low-code/no-code.
Une Git, N8n, Appsmith, Directus e ferramentas de dev para acelerar criação de soluções. 

---

## O que é

A **Suíte Factory** é a **Suíte 1 (Núcleo de Construção)** da plataforma AppGear. Na v0.1, ela entrega:

1. **CDEs – VS Code Server (`addon-factory-vscode`)**

   * Ambientes de desenvolvimento em nuvem, isolados por workspace (`ws-<workspace_id>-factory`), com:

     * storage persistente em **Ceph Filesystem** (`storageClassName: ceph-filesystem`);
     * segredos via **Vault** (sem `.env` sensível no cluster);
     * autenticação centralizada via **Kong + Keycloak** (cadeia Traefik → Coraza → Kong → Istio);
     * **scale-to-zero** usando **KEDA**.

2. **Airbyte – Pipelines de Dados / Legacy Migration (`addon-factory-airbyte`)**

   * Instância **multi-tenant lógica** por ambiente (`factory-data`):

     * pipelines e conectores compartilhados;
     * isolamento lógico por `workspace_id` e `tenant_id`;
     * `resources.requests/limits` para evitar consumo descontrolado de CPU/memória.

3. **Build Nativo – React Native / Tauri (`addon-factory-tauri-builder`)**

   * Serviço de build nativo **on-demand** por workspace:

     * recebe pedidos de build via N8n/Portal;
     * gera builds mobile/desktop e publica artefatos em Ceph/S3;
     * escala com KEDA conforme a fila de builds.

4. **Multiplayer – Colaboração em Tempo Real (`addon-factory-multiplayer`)**

   * Gateway WebSocket para colaboração simultânea:

     * presença, edição simultânea, locks;
     * backplane em **Redis/Redpanda**;
     * tráfego sempre passando por **Kong** (`Ingress` com `ingressClassName: kong`).

5. **Topologias**

   * **Topologia B (Kubernetes / Produção)**:

     * Suíte Factory declarada via **GitOps/Argo CD** no repositório `appgear-gitops-suites`;
     * CDEs/Builder/Multiplayer em `ws-<workspace_id>-factory` (vClusters);
     * Airbyte único por ambiente no namespace `factory-data`.

   * **Topologia A (Docker / Legado)**:

     * Compose mínimo para **CDE local** atrás do Traefik (apenas dev/PoC);
     * Airbyte/Build/Multiplayer apenas em Topologia B.

---

## Por que

1. **Atender ao Contrato v0 – Suíte 1 (Factory)** 

   * Entregar infraestrutura para:

     * **CDEs seguros** (VS Code);
     * **Build Nativo** (React Native, Tauri);
     * **Multiplayer**;
     * **Legacy Migration** (Airbyte).

2. **Corrigir problemas do diagnóstico v0**

   * **G15 – Forma Canônica**

     * Versão anterior estava em `.py`; o padrão é documento Markdown (`Módulo 09 v0.1.md`).

   * **G05 – Segurança de Borda (Bypass)**

     * A versão anterior expunha VS Code/Airbyte via **IngressRoute/Traefik**, quebrando a cadeia:

       * correto: **Traefik → Coraza (WAF) → Kong (APIGW) → Istio → serviços**;
     * v0.1 passa a usar **Ingress (`networking.k8s.io/v1`) com `ingressClassName: kong`**, sem IngressRoute direto para serviços.

   * **M00-3 – FinOps (tenant-id)**

     * v0 usava só `workspace-id`; sem `appgear.io/tenant-id` não há rastreio de custo por cliente;
     * v0.1 define:

       * CDEs/Builder/Multiplayer: `appgear.io/tenant-id: <tenant_id>`;
       * Airbyte compartilhado: `appgear.io/tenant-id: global`.

3. **Alinhamento com M02 (Rede) e M05 (Segurança)**

   * M02 define cadeia de borda e que **Kong é o API Gateway oficial**;
   * M05 define Vault e políticas OPA; CDEs, Builder, Airbyte e Multiplayer usam apenas segredos injetados de Vault e respeitam policies (sem segredos em YAML).

4. **Interoperabilidade com M13 (Workspaces)**

   * M09 define os **templates de recursos** que rodam dentro de `ws-<workspace_id>-factory`;
   * M13 instanciará dinamicamente estes recursos por workspace/tenant;
   * labels (`appgear.io/tenant-id`, `appgear.io/workspace-id`, `appgear.io/suite`, `appgear.io/tier`) são fundamentais para Governança e FinOps.

5. **Decisão de Airbyte compartilhado – trade-offs**

   * Um Airbyte por ambiente (multi-tenant lógico) economiza recursos, mas:

     * isolamento é lógico, não físico;
     * exige rigor em credenciais, DBs e RBAC internos;
   * Essas limitações ficam documentadas e podem levar, no futuro, a instâncias Airbyte por tenant crítico.

---

## Pré-requisitos

### Contratuais / Governança

* **0 – Contrato v0** aprovado; 
* Módulos 0 a 8 especificados e aplicados:

  * **M00** – Convenções, Repositórios, Labels (`appgear.io/*`);
  * **M01** – Argo CD / App-of-Apps;
  * **M02** – Rede/Borda (Traefik, Coraza, Kong, Istio);
  * **M03** – Observabilidade/FinOps (Prometheus, Grafana, Loki, OpenCost, Lago);
  * **M04** – Storage e Bancos (Ceph, Postgres, Redis, Qdrant, RabbitMQ, Redpanda);
  * **M05** – Segurança/Segredos (Vault, OPA, Falco, OpenFGA);
  * **M06** – Identidade/SSO (Keycloak/midPoint);
  * **M07** – Portal Backstage;
  * **M08** – Serviços de Aplicação (Flowise, N8n, Directus, Appsmith, etc.).

### Infraestrutura – Topologia B

* Cluster `ag-<regiao>-core-<env>` com:

  * `core-traefik`, `core-coraza`, `core-kong`, `core-istio`;
  * `core-argocd`, `core-keda`;
  * `core-vault`;
  * `core-ceph` com StorageClasses:

    * `ceph-block` (RWO);
    * `ceph-filesystem` (RWX);
  * `core-postgres`, `core-redis`, `core-rabbitmq`, `core-redpanda`.

* vClusters por workspace:

  * `vcl-ws-<workspace_id>` com namespaces:

    * `ws-<workspace_id>-core`;
    * `ws-<workspace_id>-factory`.

* Namespaces globais:

  * `factory-data` (Airbyte compartilhado);
  * `observability`, `security`, `backstage`, `argocd`, `appgear-core`.

* Vault:

  * `auth/kubernetes` configurado para cluster/vClusters;
  * paths:

    * `kv/appgear/addon-factory-vscode/config`;
    * `kv/appgear/addon-factory-tauri/config`;
    * `database/creds/postgres-role-airbyte`, etc.

### Ferramentas

* CLI: `git`, `kubectl`, `kustomize`, `argocd`;
* Repositórios:

  * `appgear-gitops-core`;
  * `appgear-gitops-suites`.

### Topologia A (Dev/PoC)

* Host Ubuntu LTS com Docker + docker-compose;
* Estrutura `/opt/appgear` criada:

  * `.env`;
  * `docker-compose.yml`;
  * `config/`, `data/`, `logs/`.

---

## Como fazer (comandos)

### 1. Estrutura GitOps da Suíte Factory

No repositório `appgear-gitops-suites`:

```bash
cd appgear-gitops-suites

mkdir -p apps/factory/{vscode,airbyte,tauri,multiplayer}
```

`apps/factory/kustomization.yaml`:

```bash
cat > apps/factory/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - vscode/
  - airbyte/
  - tauri/
  - multiplayer/
EOF
```

Application da Suíte Factory para o cluster (ex.: `ag-br-core-dev`):

```bash
cat >> clusters/ag-br-core-dev/apps-suites.yaml << 'EOF'
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: suite-factory
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  project: default
  source:
    repoURL: https://git.example.com/appgear-gitops-suites.git
    targetRevision: main
    path: apps/factory
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

---

### 2. CDE – VS Code Server por workspace (`addon-factory-vscode`)

> Os manifests a seguir são templates; M13 cuidará da substituição de `<workspace_id>` e `<tenant_id>` por valores reais.

#### 2.1 Kustomization

```bash
cat > apps/factory/vscode/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Substituído por overlay/template (M13)
namespace: ws-<workspace_id>-factory

resources:
  - pvc-workspace.yaml
  - deployment-vscode.yaml
  - service-vscode.yaml
  - ingress-vscode-kong.yaml
  - scaledobject-vscode.yaml
EOF
```

#### 2.2 PVC – Ceph Filesystem (RWX)

```bash
cat > apps/factory/vscode/pvc-workspace.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cde-workspace
  labels:
    app.kubernetes.io/name: addon-factory-vscode
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
    appgear.io/backup-enabled: "true"
    appgear.io/backup-profile: "factory-cde"
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ceph-filesystem
  resources:
    requests:
      storage: 20Gi
EOF
```

#### 2.3 Deployment – VS Code Server

```bash
cat > apps/factory/vscode/deployment-vscode.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-factory-vscode
  labels:
    app.kubernetes.io/name: addon-factory-vscode
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    sidecar.istio.io/inject: "true"
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "ws-<workspace_id>-factory"
    vault.hashicorp.com/agent-inject-secret-cde-config: "kv/data/appgear/addon-factory-vscode/config"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-factory-vscode
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-factory-vscode
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: factory
        appgear.io/topology: B
        appgear.io/workspace-id: <workspace_id>
        appgear.io/tenant-id: <tenant_id>
      annotations:
        sidecar.istio.io/inject: "true"
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "ws-<workspace_id>-factory"
        vault.hashicorp.com/agent-inject-secret-cde-config: "kv/data/appgear/addon-factory-vscode/config"
    spec:
      serviceAccountName: core-services
      containers:
        - name: code-server
          image: codercom/code-server:latest
          ports:
            - name: http
              containerPort: 8080
          env:
            - name: WORKSPACE_ID
              value: "<workspace_id>"
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "2"
              memory: "4Gi"
          volumeMounts:
            - name: workspace
              mountPath: /home/coder/project
      volumes:
        - name: workspace
          persistentVolumeClaim:
            claimName: cde-workspace
EOF
```

#### 2.4 Service

```bash
cat > apps/factory/vscode/service-vscode.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-factory-vscode
  labels:
    app.kubernetes.io/name: addon-factory-vscode
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  selector:
    app.kubernetes.io/name: addon-factory-vscode
  ports:
    - name: http
      port: 80
      targetPort: http
EOF
```

#### 2.5 Ingress – Kong (`/vscode`)

```bash
cat > apps/factory/vscode/ingress-vscode-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: addon-factory-vscode
  labels:
    app.kubernetes.io/name: addon-factory-vscode
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    konghq.com/strip-path: "true"
    konghq.com/protocols: "http,https"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  ingressClassName: kong
  rules:
    - host: factory.dev.appgear.local
      http:
        paths:
          - path: /vscode
            pathType: Prefix
            backend:
              service:
                name: addon-factory-vscode
                port:
                  number: 80
EOF
```

#### 2.6 KEDA ScaledObject

```bash
cat > apps/factory/vscode/scaledobject-vscode.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: addon-factory-vscode
  namespace: ws-<workspace_id>-factory
  labels:
    app.kubernetes.io/name: addon-factory-vscode
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  scaleTargetRef:
    kind: Deployment
    name: addon-factory-vscode
  minReplicaCount: 0
  maxReplicaCount: 3
  cooldownPeriod: 300
  pollingInterval: 60
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://core-prometheus.observability.svc.cluster.local:9090
        metricName: addon_factory_vscode_active_sessions
        threshold: "1"
        query: |
          sum(addon_factory_vscode_active_sessions{workspace_id="<workspace_id>"})
EOF
```

---

### 3. Airbyte – Instância compartilhada (`factory-data`)

#### 3.1 Application (Helm) – Argo CD

```bash
cat > apps/factory/airbyte/application-airbyte.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: addon-factory-airbyte
  namespace: argocd
  labels:
    app.kubernetes.io/name: addon-factory-airbyte
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  project: default
  source:
    repoURL: https://airbytehq.github.io/helm-charts
    chart: airbyte
    targetRevision: 0.52.0
    helm:
      values: |
        global:
          edition: "oss"
        webapp:
          service:
            type: ClusterIP
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
        server:
          service:
            type: ClusterIP
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "2Gi"
        worker:
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "2Gi"
        scheduler:
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
        database:
          external:
            enabled: true
            host: core-postgres.appgear-core.svc.cluster.local
            port: 5432
            database: airbyte_factory
            userFromSecret:
              name: addon-factory-airbyte-db
              key: username
            passwordFromSecret:
              name: addon-factory-airbyte-db
              key: password
  destination:
    server: https://kubernetes.default.svc
    namespace: factory-data
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

`apps/factory/airbyte/kustomization.yaml`:

```bash
cat > apps/factory/airbyte/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - application-airbyte.yaml
  - scaledobject-airbyte-workers.yaml
  - ingress-airbyte-kong.yaml
EOF
```

#### 3.2 KEDA ScaledObject – workers

```bash
cat > apps/factory/airbyte/scaledobject-airbyte-workers.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: addon-factory-airbyte-workers
  namespace: factory-data
  labels:
    app.kubernetes.io/name: addon-factory-airbyte
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  scaleTargetRef:
    kind: Deployment
    name: airbyte-worker
  minReplicaCount: 0
  maxReplicaCount: 10
  cooldownPeriod: 300
  pollingInterval: 30
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://core-prometheus.observability.svc.cluster.local:9090
        metricName: airbyte_pending_jobs
        threshold: "1"
        query: |
          sum(airbyte_pending_jobs)
EOF
```

#### 3.3 Ingress – Airbyte UI via Kong

```bash
cat > apps/factory/airbyte/ingress-airbyte-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: addon-factory-airbyte
  namespace: factory-data
  labels:
    app.kubernetes.io/name: addon-factory-airbyte
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    konghq.com/strip-path: "true"
    konghq.com/protocols: "http,https"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  ingressClassName: kong
  rules:
    - host: factory.dev.appgear.local
      http:
        paths:
          - path: /airbyte
            pathType: Prefix
            backend:
              service:
                name: airbyte-webapp
                port:
                  number: 80
EOF
```

---

### 4. Build Nativo – Serviço de Builder (`addon-factory-tauri-builder`)

#### 4.1 Kustomization

```bash
cat > apps/factory/tauri/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ws-<workspace_id>-factory

resources:
  - deployment-builder.yaml
  - service-builder.yaml
  - scaledobject-builder.yaml
EOF
```

#### 4.2 Deployment

```bash
cat > apps/factory/tauri/deployment-builder.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-factory-tauri-builder
  labels:
    app.kubernetes.io/name: addon-factory-tauri-builder
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    sidecar.istio.io/inject: "true"
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "ws-<workspace_id>-factory"
    vault.hashicorp.com/agent-inject-secret-builder-config: "kv/data/appgear/addon-factory-tauri/config"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-factory-tauri-builder
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-factory-tauri-builder
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: factory
        appgear.io/topology: B
        appgear.io/workspace-id: <workspace_id>
        appgear.io/tenant-id: <tenant_id>
      annotations:
        sidecar.istio.io/inject: "true"
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "ws-<workspace_id>-factory"
        vault.hashicorp.com/agent-inject-secret-builder-config: "kv/data/appgear/addon-factory-tauri/config"
    spec:
      serviceAccountName: core-services
      containers:
        - name: builder-api
          image: appgear/tauri-reactnative-builder:latest
          ports:
            - name: http
              containerPort: 8080
          env:
            - name: BUILDER_WORKSPACE_ID
              value: "<workspace_id>"
            - name: S3_ENDPOINT
              value: "http://ceph-rgw.appgear-core.svc.cluster.local"
            - name: S3_BUCKET
              value: "factory-artifacts"
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "4"
              memory: "8Gi"
EOF
```

#### 4.3 Service

```bash
cat > apps/factory/tauri/service-builder.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-factory-tauri-builder
  labels:
    app.kubernetes.io/name: addon-factory-tauri-builder
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  selector:
    app.kubernetes.io/name: addon-factory-tauri-builder
  ports:
    - name: http
      port: 80
      targetPort: http
EOF
```

#### 4.4 KEDA ScaledObject

```bash
cat > apps/factory/tauri/scaledobject-builder.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: addon-factory-tauri-builder
  namespace: ws-<workspace_id>-factory
  labels:
    app.kubernetes.io/name: addon-factory-tauri-builder
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  scaleTargetRef:
    kind: Deployment
    name: addon-factory-tauri-builder
  minReplicaCount: 0
  maxReplicaCount: 5
  cooldownPeriod: 600
  pollingInterval: 60
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://core-prometheus.observability.svc.cluster.local:9090
        metricName: builder_pending_jobs
        threshold: "1"
        query: |
          sum(builder_pending_jobs{workspace_id="<workspace_id>"})
EOF
```

---

### 5. Multiplayer – Gateway WebSocket (`addon-factory-multiplayer`)

#### 5.1 Kustomization

```bash
cat > apps/factory/multiplayer/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ws-<workspace_id>-factory

resources:
  - deployment-multiplayer.yaml
  - service-multiplayer.yaml
  - ingress-multiplayer-kong.yaml
  - scaledobject-multiplayer.yaml
EOF
```

#### 5.2 Deployment

```bash
cat > apps/factory/multiplayer/deployment-multiplayer.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-factory-multiplayer
  labels:
    app.kubernetes.io/name: addon-factory-multiplayer
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-factory-multiplayer
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-factory-multiplayer
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: factory
        appgear.io/topology: B
        appgear.io/workspace-id: <workspace_id>
        appgear.io/tenant-id: <tenant_id>
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: multiplayer
          image: appgear/multiplayer-gateway:latest
          ports:
            - name: ws
              containerPort: 8080
          env:
            - name: WORKSPACE_ID
              value: "<workspace_id>"
            - name: REDIS_HOST
              value: core-redis.appgear-core.svc.cluster.local
            - name: REDPANDA_BROKER
              value: core-redpanda.appgear-core.svc.cluster.local:9092
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "2"
              memory: "4Gi"
EOF
```

#### 5.3 Service

```bash
cat > apps/factory/multiplayer/service-multiplayer.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-factory-multiplayer
  labels:
    app.kubernetes.io/name: addon-factory-multiplayer
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  selector:
    app.kubernetes.io/name: addon-factory-multiplayer
  ports:
    - name: ws
      port: 80
      targetPort: ws
EOF
```

#### 5.4 Ingress – WebSocket via Kong

```bash
cat > apps/factory/multiplayer/ingress-multiplayer-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: addon-factory-multiplayer
  labels:
    app.kubernetes.io/name: addon-factory-multiplayer
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    konghq.com/strip-path: "true"
    konghq.com/protocols: "http,https"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  ingressClassName: kong
  rules:
    - host: factory.dev.appgear.local
      http:
        paths:
          - path: /multiplayer
            pathType: Prefix
            backend:
              service:
                name: addon-factory-multiplayer
                port:
                  number: 80
EOF
```

#### 5.5 KEDA ScaledObject

```bash
cat > apps/factory/multiplayer/scaledobject-multiplayer.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: addon-factory-multiplayer
  namespace: ws-<workspace_id>-factory
  labels:
    app.kubernetes.io/name: addon-factory-multiplayer
    appgear.io/tier: addon
    appgear.io/suite: factory
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod9-suite-factory"
spec:
  scaleTargetRef:
    kind: Deployment
    name: addon-factory-multiplayer
  minReplicaCount: 0
  maxReplicaCount: 5
  cooldownPeriod: 300
  pollingInterval: 30
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://core-prometheus.observability.svc.cluster.local:9090
        metricName: multiplayer_active_sessions
        threshold: "1"
        query: |
          sum(multiplayer_active_sessions{workspace_id="<workspace_id>"})
EOF
```

---

### 6. Topologia A – CDE mínimo em Docker

No host:

```bash
sudo mkdir -p /opt/appgear/config/cde
cd /opt/appgear
```

`.env`:

```env
FACTORY_VSCODE_PORT=8443
```

Trecho de `docker-compose.yml`:

```yaml
services:
  core-traefik:
    image: traefik:v3.0
    command:
      - "--providers.docker=true"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  addon-factory-vscode:
    image: codercom/code-server:latest
    container_name: addon-factory-vscode
    environment:
      - DOCKER_USER=coder
    volumes:
      - ./config/cde:/home/coder/project
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.factory-vscode.rule=PathPrefix(`/vscode`)"
      - "traefik.http.routers.factory-vscode.entrypoints=websecure"
      - "traefik.http.services.factory-vscode.loadbalancer.server.port=8080"
```

> Airbyte/Builder/Multiplayer permanecem apenas na Topologia B (Kubernetes).

---

## Como verificar

1. **Estrutura GitOps**

   ```bash
   cd appgear-gitops-suites
   tree apps/factory
   ```

   * Esperado: diretórios `vscode`, `airbyte`, `tauri`, `multiplayer` com os YAMLs descritos.

2. **Argo CD – Suíte Factory**

   ```bash
   argocd app list | grep suite-factory
   argocd app get suite-factory
   ```

   * Deve estar `Healthy` e `Synced`.

3. **Namespaces / objetos por workspace**

   ```bash
   kubectl get ns | grep ws-<workspace_id>-factory

   kubectl get deploy,svc,ingress,scaledobject,pvc \
     -n ws-<workspace_id>-factory
   ```

   * Esperado:

     * `addon-factory-vscode`, `addon-factory-tauri-builder`, `addon-factory-multiplayer`;
     * PVC `cde-workspace` em estado `Bound`.

4. **Labels de FinOps (`tenant-id`)**

   ```bash
   kubectl get deploy addon-factory-vscode \
     -n ws-<workspace_id>-factory -o jsonpath='{.metadata.labels}'
   ```

   * Verificar presença de `appgear.io/tenant-id: <tenant_id>`.

   Para Airbyte:

   ```bash
   kubectl get deploy -n factory-data | grep airbyte
   kubectl get deploy airbyte-server -n factory-data -o jsonpath='{.metadata.labels}'
   ```

   * Esperado: `appgear.io/tenant-id: global`.

5. **Ingress com Kong**

   ```bash
   kubectl get ingress -A | grep factory
   ```

   * Validar:

     * CDE/Multiplayer com `ingressClassName: kong` em `ws-<workspace_id>-factory`;
     * Airbyte com `ingressClassName: kong` em `factory-data`.

6. **KEDA – Scale-to-zero**

   CDE:

   ```bash
   kubectl get scaledobject addon-factory-vscode -n ws-<workspace_id>-factory -o yaml | yq '.spec'
   kubectl get deploy addon-factory-vscode -n ws-<workspace_id>-factory -w
   ```

   * Em idle: `replicas: 0`; sob uso: escala para 1+.

   Airbyte workers e Multiplayer de forma análoga.

7. **Rotas externas (cadeia completa)**

   Com DNS/hosts apontando para Traefik de borda:

   ```bash
   curl -k https://factory.dev.appgear.local/vscode -I
   curl -k https://factory.dev.appgear.local/airbyte -I
   curl -k https://factory.dev.appgear.local/multiplayer -I
   ```

   * Esperado: autenticação via cadeia Traefik → Coraza → Kong + SSO; após login, `200`.

---

## Erros comuns

1. **Expor VS Code/Airbyte via IngressRoute (Traefik) – bypass da cadeia**

   * Efeito: tráfego pula Coraza/Kong, violando M02 e abrindo vetor crítico nos CDEs.
   * Correção: usar apenas `Ingress` com `ingressClassName: kong` conforme este módulo; Traefik/Coraza são responsabilidade do M02.

2. **Falta de `appgear.io/tenant-id`**

   * Efeito: custos de CDEs/Airbyte não são atribuíveis por tenant; M13/FinOps ficam inconsistentes.
   * Correção: garantir `appgear.io/tenant-id` em todos os recursos:

     * `<tenant_id>` para workspaces;
     * `global` para Airbyte.

3. **Uso de `emptyDir` em CDEs**

   * Efeito: perda de código não commitado quando KEDA escala para zero.
   * Correção: sempre PVC com `storageClassName: ceph-filesystem` (RWX).

4. **Airbyte sem `resources.limits` e sem KEDA**

   * Efeito: consumo descontrolado de memória/CPU com muitos jobs.
   * Correção: manter `resources` no Helm e KEDA apenas para `airbyte-worker`.

5. **Ingress do Multiplayer sem suporte WebSocket**

   * Efeito: timeouts/falhas de upgrade de conexão.
   * Correção: manter `konghq.com/protocols: "http,https"` e garantir configuração global do Kong para WebSocket (M02).

6. **Ignorar validação OPA (M05)**

   * Efeito: CDEs/Builders podem violar políticas de segurança (imagens, capabilities, etc.).
   * Correção: validar Deployments deste módulo contra policies OPA antes de produção.

7. **Misturar artefatos Core e Suíte Factory no mesmo repositório**

   * Efeito: confusão de responsabilidades, risco em rollbacks.
   * Correção: manter este módulo somente em `appgear-gitops-suites` na pasta `apps/factory`.

---

## Onde salvar

1. **Documento (governança/desenvolvimento)**

   * Repositório: `appgear-docs` ou `appgear-contracts`;
   * Arquivo: `Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer) v0.1.md`;
   * Referência em:

     * `1 - Desenvolvimento v0.md`, seção “Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer) – v0.1”.

2. **Repositório GitOps – Suítes**

   * Repositório: `appgear-gitops-suites`;
   * Estrutura:

     ```text
     apps/factory/kustomization.yaml
     apps/factory/vscode/*.yaml
     apps/factory/airbyte/*.yaml
     apps/factory/tauri/*.yaml
     apps/factory/multiplayer/*.yaml

     clusters/ag-<regiao>-core-<env>/apps-suites.yaml
       # contém a Application suite-factory
     ```

3. **Topologia A (Docker)**

   * Host de desenvolvimento/legado:

     ```text
     /opt/appgear/.env
     /opt/appgear/docker-compose.yml
     /opt/appgear/config/cde/
     ```

---

## Dependências entre os módulos

A Suíte Factory (Módulo 09) se encaixa na arquitetura AppGear da seguinte forma:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Define:

    * padrão de documentação (`.md`);
    * convenções de repositório (`appgear-gitops-core`, `appgear-gitops-suites`, `appgear-docs`);
    * labels `appgear.io/*` (incluindo `appgear.io/tenant-id` e `appgear.io/workspace-id`);
    * diretrizes de FinOps e governança aplicadas a todos os YAMLs deste módulo.

* **Módulo 01 – GitOps e Argo CD**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD como controlador GitOps;
    * `clusters/ag-<regiao>-core-<env>/apps-suites.yaml`, onde é registrada a `Application suite-factory`.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * cadeia de borda **Traefik → Coraza → Kong → Istio**;
    * Kong como API Gateway oficial, consumido por este módulo via `Ingress` (`/vscode`, `/airbyte`, `/multiplayer`);
    * Istio com mTLS entre pods de Factory e serviços Core.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * **Dependência mútua.**
  * M03:

    * coleta métricas e custos dos CDEs, Builders, Multiplayer e Airbyte;
  * M09:

    * expõe métricas específicas (ex.: `addon_factory_vscode_active_sessions`, `builder_pending_jobs`, `multiplayer_active_sessions`, `airbyte_pending_jobs`) para KEDA e FinOps;
    * usa labels `appgear.io/tenant-id` e `appgear.io/suite=factory` para atribuir custos corretamente.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, etc.)**

  * **Pré-requisito técnico.**
  * Fornece:

    * Ceph Filesystem (`ceph-filesystem`) para armazenamento persistente dos CDEs;
    * `core-postgres` para Airbyte;
    * `core-redis` e `core-redpanda` para Multiplayer e fluxos de eventos.

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * **Pré-requisito direto.**
  * Fornece:

    * Vault como SSoT de segredos dos CDEs e Builders (`kv/appgear/addon-factory-*` e `database/creds/*`);
    * OPA para validar manifests deste módulo (labels, ausência de segredos, proibição de `:latest`, etc.);
    * Falco monitorando runtime dos pods da Suíte Factory.

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * **Pré-requisito funcional.**
  * Fornece:

    * SSO centralizado para acesso a CDEs/Airbyte/Multiplayer via Kong;
    * atributos de identidade (tenant, workspace) usados por fluxos de Factory e Workspaces.

* **Módulo 07 – Portal Backstage e Integrações Core**

  * **Consumidor deste módulo.**
  * Fornece:

    * Portal onde usuários podem criar/gerenciar CDEs, Builds, pipelines Airbyte e sessões multiplayer;
    * templates de Scaffolder que orquestram criação de recursos da Suíte Factory em conjunto com M13.

* **Módulo 08 – Serviços de Aplicação Core (LiteLLM, Flowise, N8n, Directus, Appsmith, Metabase)**

  * **Complementar a este módulo.**
  * Fornece:

    * N8n e serviços de AI/automação que disparam builds, pipelines de dados e operações da Factory;
    * Directus/Appsmith/Metabase como base de dados/UI sobre resultados de builds e pipelines.

* **Módulo 09 – Suíte Factory (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06, M07, M08**;
  * Entrega:

    * CDEs, Airbyte, Builder e Multiplayer por workspace/tenant, prontos para serem orquestrados pelo M13 (Workspaces) e pelo Portal (M07).

* **Módulo 13 – Workspaces e vClusters (futuro)**

  * **Dependente direto deste módulo.**
  * Usará os templates de YAML do M09 para instanciar a Suíte Factory em cada `ws-<workspace_id>-factory`, garantindo que:

    * labels de FinOps/tenant sejam consistentes;
    * CDEs/Builders/Multiplayer sejam criados e destruídos conforme ciclo de vida do workspace.

Em fluxo:

* **M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → M09 → (M13, Suites adicionais, PWA, etc.)**

Sem o Módulo 09, a AppGear não dispõe de uma camada padronizada de **CDEs, pipelines de dados, build nativo e colaboração em tempo real**, tornando inviável a experiência de desenvolvimento orientada a Workspaces e Suítes prevista nos módulos superiores.
