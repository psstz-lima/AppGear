# M10 – Suíte Brain (RAG, Agentes, AutoML) (v0.3)

> [!IMPORTANT]
> Este documento define o **Módulo 10 (M10)** da arquitetura AppGear na linha v0.3.  
> Deve ser lido em conjunto com:
> - `docs/architecture/contract/contract-v0.md`
> - `docs/architecture/audit/audit-v0.md`
> - `docs/architecture/interoperability/interoperability-v0.md`
> - `docs/architecture/interoperability/resources/fluxos-ai-first.md`
> - `docs/architecture/interoperability/resources/mapa-global.md`

Versão do módulo: v0.3  
Compatibilidade: linha v0 / v0.3  

---

> **Metadados v0.3**  
> version: v0.3 — schema: appgear-stack — compatibility: full  
> baseline: `development/v0.3/stack-unificada-v0.3.yaml`

## Contexto v0.3

### Padronização v0.3

- `.env` centralizado em `/opt/appgear/.env` (Topologia A) ou segredos via Vault/ExternalSecrets (Topologia B); apenas `.env.example` permanece versionado.
- Cadeia obrigatória `Traefik (TLS passthrough SNI) → Coraza WAF → Kong → Istio IngressGateway → Service Mesh` com mTLS **STRICT**, registrando exceções no quadro de monitoramento.
- Stack integrada sob controle GitOps via ArgoCD com **ApplicationSet list-generator** e labels `appgear.io/*`; App-of-Apps fica restrito ao bootstrap do Argo CD.
- Trilha CI/CD v1.1 com MAPA_NC → PLANO_CORRECAO → MODULO_REESCRITO → CHECKLIST e artefatos em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` com hash SHA-256 de SBOM.

---

# Módulo 10 – Suíte Brain

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

- Brain: consolida RAG/LLM com Qdrant/Meilisearch + LiteLLM/Flowise e AutoML JupyterHub/MLflow.


### Premissas padrão (v0.3)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Camada de IA e conhecimento: RAG, vetorização, modelos, prompts, orquestração de LLMs.
Centraliza Qdrant, Tika, Gotenberg, LiteLLM/Flowise e serviços de embeddings para construção de experiências AI-first.

---

## 1. O que é

A **Suíte Brain** é a suíte de inteligência da AppGear, composta por três blocos principais:

1. **Corporate Brain (RAG / Busca Semântica)**

   * RAG híbrido:

     * Vetorial no **Core Qdrant** (M04);
     * Texto full-text no **addon-brain-meilisearch** (Meilisearch, neste módulo).
   * Orquestrado via **Flowise + LiteLLM** (M08), usando LiteLLM como gateway único de LLM.
   * Exposto como APIs para:

     * Directus, Appsmith, PWA, Backstage, N8n, Workspaces e demais módulos.

2. **AI Workforce (Agentes Autônomos)**

   * Serviço `addon-brain-agents-crewai` **por workspace**:

     * Agentes CrewAI/AutoGen;
     * Consomem contexto do RAG (Qdrant + Meilisearch);
     * Chamam somente **core-litellm** (M08) para modelos LLM;
     * Podem acionar fluxos no N8n/BPMN (M08).

3. **AutoML Studio (No-Code AutoML)**

   * Composto por:

     * **JupyterHub** (`addon-brain-jupyterhub`) – notebooks por usuário;
     * **MLflow** (`addon-brain-mlflow`) – tracking + model registry.
   * Armazenamento:

     * Metadados em **Postgres Core** (M04);
     * Artefatos em **Ceph S3** (M04 – RGW ou MinIO gateway).
   * Modelos treinados podem ser:

     * “Ferramentas” de agentes;
     * Serviços publicados via N8n/Flowise.

4. **Topologias**

   * **Topologia B (produção em Kubernetes)**:

     * Implementada via GitOps em `appgear-gitops-suites/apps/brain`;
     * Exposição externa **sempre** passa por:

       * Traefik → Coraza (WAF) → Kong (Ingress Controller/API Gateway) → Istio (mTLS STRICT STRICT);
     * Este módulo **não** cria `IngressRoute` de Traefik, apenas `Ingress` com `ingressClassName: kong`.
   * **Topologia A (Docker – dev / laboratório)**:

     * Compose com Meilisearch + Agentes + Jupyter + MLflow;
     * Uso estritamente dev/lab, sem cobertura de WAF/Zero-Trust.

---

## 2. Por que

1. **Correção de violações de segurança (G05)** 

   * No v0, JupyterHub, MLflow e Meilisearch eram expostos via `IngressRoute` direto no Traefik:

     * Quebrando a cadeia Traefik → Coraza → Kong → Istio;
     * Expondo serviços de **execução de código arbitrário** sem WAF/API Gateway.
   * No v0.1:

     * Apenas recursos `Ingress` de `networking.k8s.io/v1` com `ingressClassName: kong` são criados;
     * A lógica de Traefik/Coraza continua centralizada no M02 (Rede/Borda).

2. **Atender FinOps e multi-tenant (M00-3)**

   * IA/ML (Jupyter, Agentes, Treinos) tendem a ser os maiores consumidores de CPU/GPU/memória.
   * Sem `appgear.io/tenant-id`, custos não são atribuídos a clientes/workspaces.
   * v0.1 inclui:

     * `appgear.io/tenant-id: global` para serviços compartilhados (ex.: Meilisearch, JupyterHub, MLflow);
     * `appgear.io/tenant-id: <tenant_id>` para workloads por cliente/workspace (Agentes).

3. **Governança de recursos (T-shirt sizing)**

   * No v0, pods de usuário JupyterHub não tinham `requests/limits` definidos ⇒ risco de um único usuário derrubar o nó.
   * v0.1 define **perfis S/M/L**:

     * Em `singleuser.profileList` do JupyterHub, com `cpu_guarantee/limit` e `mem_guarantee/limit`;
     * Nos agentes CrewAI, com perfil S por padrão (podendo haver variações M/L futuras).

4. **Interoperabilidade RAG híbrido preservada**

   * Mantém a integração:

     * Vetorial no Qdrant (Core, M04);
     * Texto no Meilisearch (Brain, M10);
     * LiteLLM como Gateway AI (M08);
     * Ceph/S3 e Postgres (M04) para Jupyter/MLflow.

5. **Alinhamento com a arquitetura AppGear**

   * Integra-se com:

     * M03 (Observabilidade/FinOps) para métricas e custos;
     * M07 (Portal Backstage) como interface de governança e catálogo;
     * M08 (Flowise + LiteLLM + N8n) para orquestração de pipelines de IA;
     * M09 (Factory) para uso dos modelos/Agentes em Workspaces/CDEs.

---

## 3. Pré-requisitos

### Organizacionais

* **0 – Contrato v0** como fonte de verdade para a arquitetura. 
* Módulos anteriores publicados/aplicados:

  * **M00** – Convenções, nomenclatura, labels `appgear.io/*` e FinOps;
  * **M01** – Bootstrap GitOps/Argo CD;
  * **M02** – Borda, WAF, Gateway, Istio (cadeia Traefik → Coraza → Kong → Istio, mTLS STRICT STRICT);
  * **M03** – Observabilidade & FinOps (Prometheus, Grafana, Loki, OpenCost, Lago);
  * **M04** – Armazenamento & Bancos (Ceph, Postgres, Redis, Qdrant, Redpanda, etc.);
  * **M05** – Segurança & Segredos (Vault, OPA, Falco, OpenFGA);
  * **M06** – Identidade & SSO (Keycloak, midPoint, RBAC/ReBAC);
  * **M07** – Portal Backstage integrado a FinOps e Observabilidade;
  * **M08** – Serviços Core (Flowise, LiteLLM, Directus, Appsmith, N8n, etc.);
  * **M09** – Factory (CDEs, Airbyte, Build).

### Infraestrutura – Topologia B (Kubernetes)

* Cluster `ag-<regiao>-core-<env>` com:

  * `core-qdrant`, `core-postgres`, `core-redis`, `core-ceph`, `core-keda`;
  * `core-prometheus`, `core-grafana`, `core-litellm`, `core-flowise`;
  * Istio com `PeerAuthentication` STRICT;
  * Kong instalado como Ingress Controller (integrado ao M02).

* Namespaces:

  * `brain-data` – Corporate Brain / Meilisearch;
  * `brain-ml` – AutoML Studio (JupyterHub + MLflow);
  * `ws-<workspace_id>-brain` – AI Workforce por workspace.

### Ferramentas

* `git`, `kubectl`, `kustomize`, `argocd` CLI;
* Acesso aos repositórios:

  * `appgear-gitops-suites` (Suítes);
  * `appgear-gitops-core` (Core).

### Topologia A (Dev Docker)

* Host Linux com Docker + docker-compose;
* Diretório base `/opt/appgear/brain`;
* `.env` central pode ser compartilhado com outros módulos de dev.

---

## 4. Como fazer (comandos)

> Toda a parte Kubernetes assume uso de GitOps via **`appgear-gitops-suites`**.

### 1. Estrutura GitOps da Suíte Brain

```bash
cd appgear-gitops-suites

mkdir -p apps/brain
mkdir -p apps/brain/meilisearch apps/brain/jupyterhub apps/brain/mlflow apps/brain/agents-crewai
```

`apps/brain/kustomization.yaml`:

```bash
cat > apps/brain/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - meilisearch
  - jupyterhub
  - mlflow
  - agents-crewai
EOF
```

Commit inicial:

```bash
git add apps/brain
git commit -m "mod10 v0.1: estrutura inicial da Suíte Brain"
git push origin main
```

---

### 2. Corporate Brain – Meilisearch (Add-on Texto)

#### 2.1 Namespace + PVC + Deployment + Service

`apps/brain/meilisearch/kustomization.yaml`:

```bash
cat > apps/brain/meilisearch/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: brain-data

resources:
  - namespace.yaml
  - pvc-meilisearch.yaml
  - deployment-meilisearch.yaml
  - service-meilisearch.yaml
  - ingress-meilisearch.yaml
  - scaledobject-meilisearch.yaml
EOF
```

`apps/brain/meilisearch/namespace.yaml`:

```bash
cat > apps/brain/meilisearch/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: brain-data
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod10-suite-brain"
EOF
```

`apps/brain/meilisearch/pvc-meilisearch.yaml`:

```bash
cat > apps/brain/meilisearch/pvc-meilisearch.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: meilisearch-data
  labels:
    app.kubernetes.io/name: addon-brain-meilisearch
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ceph-block
  resources:
    requests:
      storage: 50Gi
EOF
```

`apps/brain/meilisearch/deployment-meilisearch.yaml`:

```bash
cat > apps/brain/meilisearch/deployment-meilisearch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-brain-meilisearch
  labels:
    app.kubernetes.io/name: addon-brain-meilisearch
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-brain-meilisearch
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-brain-meilisearch
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: brain
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: meilisearch
          image: getmeili/meilisearch:v1.10
          ports:
            - name: http
              containerPort: 7700
          env:
            - name: MEILI_ENV
              value: "production"
            - name: MEILI_NO_ANALYTICS
              value: "true"
            - name: MEILI_MASTER_KEY
              valueFrom:
                secretKeyRef:
                  name: brain-meilisearch-keys
                  key: master_key
          volumeMounts:
            - name: data
              mountPath: /meili_data
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "2"
              memory: "4Gi"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: meilisearch-data
EOF
```

`apps/brain/meilisearch/service-meilisearch.yaml`:

```bash
cat > apps/brain/meilisearch/service-meilisearch.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-brain-meilisearch
  labels:
    app.kubernetes.io/name: addon-brain-meilisearch
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
spec:
  selector:
    app.kubernetes.io/name: addon-brain-meilisearch
  ports:
    - name: http
      port: 7700
      targetPort: http
EOF
```

#### 2.2 Ingress via Kong (sem Traefik IngressRoute)

`apps/brain/meilisearch/ingress-meilisearch.yaml`:

```bash
cat > apps/brain/meilisearch/ingress-meilisearch.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: addon-brain-meilisearch
  labels:
    app.kubernetes.io/name: addon-brain-meilisearch
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
  annotations:
    konghq.com/plugins: "oidc-keycloak,rate-limit"
spec:
  ingressClassName: kong
  rules:
    - host: brain.dev.appgear.local
      http:
        paths:
          - path: /search
            pathType: Prefix
            backend:
              service:
                name: addon-brain-meilisearch
                port:
                  number: 7700
EOF
```

#### 2.3 KEDA ScaledObject

`apps/brain/meilisearch/scaledobject-meilisearch.yaml`:

```bash
cat > apps/brain/meilisearch/scaledobject-meilisearch.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: addon-brain-meilisearch
  labels:
    app.kubernetes.io/name: addon-brain-meilisearch
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
spec:
  scaleTargetRef:
    kind: Deployment
    name: addon-brain-meilisearch
  minReplicaCount: 0
  maxReplicaCount: 5
  cooldownPeriod: 300
  pollingInterval: 60
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://core-prometheus.observability.svc.cluster.local:9090
        metricName: http_requests_meilisearch
        threshold: "1"
        query: |
          sum(rate(meilisearch_http_requests_total[1m]))
EOF
```

---

### 3. AutoML Studio – JupyterHub + MLflow

#### 3.1 JupyterHub – Application Argo CD + T-shirt sizing

`apps/brain/jupyterhub/kustomization.yaml`:

```bash
cat > apps/brain/jupyterhub/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - application-jupyterhub.yaml
EOF
```

`apps/brain/jupyterhub/namespace.yaml`:

```bash
cat > apps/brain/jupyterhub/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: brain-ml
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod10-suite-brain"
EOF
```

`apps/brain/jupyterhub/application-jupyterhub.yaml` (trecho principal com perfis S/M/L):

```bash
cat > apps/brain/jupyterhub/application-jupyterhub.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: addon-brain-jupyterhub
  namespace: argocd
  labels:
    app.kubernetes.io/name: addon-brain-jupyterhub
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod10-suite-brain"
spec:
  project: appgear-suites
  source:
    repoURL: https://jupyterhub.github.io/helm-chart
    chart: jupyterhub
    targetRevision: 2.0.0
    helm:
      values: |
        proxy:
          service:
            type: ClusterIP

        hub:
          extraLabels:
            app.kubernetes.io/name: addon-brain-jupyterhub
            appgear.io/tier: addon
            appgear.io/suite: brain
            appgear.io/topology: B
            appgear.io/workspace-id: global
            appgear.io/tenant-id: global
          db:
            type: postgres
            url: postgresql://$(JUPYTERHUB_DB_USER):$(JUPYTERHUB_DB_PASS)@core-postgres.appgear-core.svc.cluster.local:5432/jupyterhub

        singleuser:
          extraLabels:
            app.kubernetes.io/name: addon-brain-jupyterhub-user
            appgear.io/tier: addon
            appgear.io/suite: brain
            appgear.io/topology: B
            appgear.io/workspace-id: global
            appgear.io/tenant-id: global
          storage:
            dynamic:
              storageClass: ceph-filesystem
              capacity: 20Gi
          extraEnv:
            LITELLM_BASE_URL: "http://core-litellm.appgear-core.svc.cluster.local"
            LITELLM_API_KEY: "$(LITELLM_API_KEY)"
          profileList:
            - display_name: "S - Exploração leve"
              description: "Notebooks de análise e prototipagem."
              slug: "size-s"
              kubespawner_override:
                cpu_guarantee: 0.25
                cpu_limit: 1
                mem_guarantee: "512Mi"
                mem_limit: "2Gi"
            - display_name: "M - Treino moderado"
              description: "Experimentos de treino de porte médio."
              slug: "size-m"
              kubespawner_override:
                cpu_guarantee: 1
                cpu_limit: 2
                mem_guarantee: "2Gi"
                mem_limit: "4Gi"
            - display_name: "L - Treino pesado controlado"
              description: "Treinos mais pesados (com aprovação)."
              slug: "size-l"
              kubespawner_override:
                cpu_guarantee: 2
                cpu_limit: 4
                mem_guarantee: "4Gi"
                mem_limit: "8Gi"

        auth:
          type: custom
          custom:
            className: "keycloak"  # integração com M06

        ingress:
          enabled: true
          ingressClassName: kong
          hosts:
            - brain.dev.appgear.local
          pathSuffix: ""
          annotations:
            konghq.com/plugins: "oidc-keycloak,rate-limit"
          paths:
            - /jupyter
  destination:
    server: https://kubernetes.default.svc
    namespace: brain-ml
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

#### 3.2 MLflow – Deployment + Service + Ingress (Kong)

`apps/brain/mlflow/kustomization.yaml`:

```bash
cat > apps/brain/mlflow/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: brain-ml

resources:
  - deployment-mlflow.yaml
  - service-mlflow.yaml
  - ingress-mlflow.yaml
EOF
```

`apps/brain/mlflow/deployment-mlflow.yaml`:

```bash
cat > apps/brain/mlflow/deployment-mlflow.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-brain-mlflow
  labels:
    app.kubernetes.io/name: addon-brain-mlflow
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-brain-mlflow
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-brain-mlflow
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: brain
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: mlflow
          image: appgear/mlflow-server:latest
          ports:
            - name: http
              containerPort: 5000
          env:
            - name: MLFLOW_BACKEND_STORE_URI
              valueFrom:
                secretKeyRef:
                  name: brain-mlflow-db
                  key: backend_uri
            - name: MLFLOW_ARTIFACT_ROOT
              value: s3://brain-mlflow-artifacts/
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: ceph-s3-mlflow
                  key: access_key
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: ceph-s3-mlflow
                  key: secret_key
            - name: MLFLOW_S3_ENDPOINT_URL
              value: http://core-ceph-rgw.appgear-core.svc.cluster.local:8080
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "2"
              memory: "2Gi"
EOF
```

`apps/brain/mlflow/service-mlflow.yaml`:

```bash
cat > apps/brain/mlflow/service-mlflow.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-brain-mlflow
  labels:
    app.kubernetes.io/name: addon-brain-mlflow
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
spec:
  selector:
    app.kubernetes.io/name: addon-brain-mlflow
  ports:
    - name: http
      port: 5000
      targetPort: http
EOF
```

`apps/brain/mlflow/ingress-mlflow.yaml`:

```bash
cat > apps/brain/mlflow/ingress-mlflow.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: addon-brain-mlflow
  labels:
    app.kubernetes.io/name: addon-brain-mlflow
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
    appgear.io/module: "mod10-suite-brain"
  annotations:
    konghq.com/plugins: "oidc-keycloak,rate-limit"
spec:
  ingressClassName: kong
  rules:
    - host: brain.dev.appgear.local
      http:
        paths:
          - path: /mlflow
            pathType: Prefix
            backend:
              service:
                name: addon-brain-mlflow
                port:
                  number: 5000
EOF
```

---

### 4. AI Workforce – Agents CrewAI (por workspace)

`apps/brain/agents-crewai/kustomization.yaml` (modelo; M13 poderá gerar overlays por workspace):

```bash
cat > apps/brain/agents-crewai/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment-agents.yaml
  - service-agents.yaml
  - ingress-agents.yaml
  - scaledobject-agents.yaml
EOF
```

`apps/brain/agents-crewai/deployment-agents.yaml` (parâmetros `<workspace_id>`, `<tenant_id>`):

```bash
cat > apps/brain/agents-crewai/deployment-agents.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-brain-agents-crewai
  namespace: ws-<workspace_id>-brain
  labels:
    app.kubernetes.io/name: addon-brain-agents-crewai
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
    appgear.io/module: "mod10-suite-brain"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-brain-agents-crewai
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-brain-agents-crewai
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: brain
        appgear.io/topology: B
        appgear.io/workspace-id: <workspace_id>
        appgear.io/tenant-id: <tenant_id>
      annotations:
        sidecar.istio.io/inject: "true"
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "ws-<workspace_id>-brain"
        vault.hashicorp.com/agent-inject-secret-agents-config: "kv/data/appgear/addon-brain-agents-crewai/config"
    spec:
      serviceAccountName: core-services
      containers:
        - name: agents
          image: appgear/agents-crewai:latest
          ports:
            - name: http
              containerPort: 8080
          env:
            - name: WORKSPACE_ID
              value: "<workspace_id>"
            - name: TENANT_ID
              value: "<tenant_id>"
            - name: LITELLM_BASE_URL
              value: "http://core-litellm.appgear-core.svc.cluster.local"
            - name: LITELLM_API_KEY
              valueFrom:
                secretKeyRef:
                  name: litellm-api-key
                  key: api_key
            - name: QDRANT_URL
              value: "http://core-qdrant.appgear-core.svc.cluster.local:6333"
            - name: MEILISEARCH_URL
              value: "http://addon-brain-meilisearch.brain-data.svc.cluster.local:7700"
          resources:       # Perfil S por default; M/L podem ser variações futuras
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "2"
              memory: "4Gi"
EOF
```

`apps/brain/agents-crewai/service-agents.yaml`:

```bash
cat > apps/brain/agents-crewai/service-agents.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-brain-agents-crewai
  namespace: ws-<workspace_id>-brain
  labels:
    app.kubernetes.io/name: addon-brain-agents-crewai
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
    appgear.io/module: "mod10-suite-brain"
spec:
  selector:
    app.kubernetes.io/name: addon-brain-agents-crewai
  ports:
    - name: http
      port: 80
      targetPort: http
EOF
```

`apps/brain/agents-crewai/ingress-agents.yaml`:

```bash
cat > apps/brain/agents-crewai/ingress-agents.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: addon-brain-agents-crewai
  namespace: ws-<workspace_id>-brain
  labels:
    app.kubernetes.io/name: addon-brain-agents-crewai
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
    appgear.io/module: "mod10-suite-brain"
  annotations:
    konghq.com/plugins: "oidc-keycloak,rate-limit"
spec:
  ingressClassName: kong
  rules:
    - host: brain.dev.appgear.local
      http:
        paths:
          - path: /agents/ws-<workspace_id>
            pathType: Prefix
            backend:
              service:
                name: addon-brain-agents-crewai
                port:
                  number: 80
EOF
```

`apps/brain/agents-crewai/scaledobject-agents.yaml`:

```bash
cat > apps/brain/agents-crewai/scaledobject-agents.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: addon-brain-agents-crewai
  namespace: ws-<workspace_id>-brain
  labels:
    app.kubernetes.io/name: addon-brain-agents-crewai
    appgear.io/tier: addon
    appgear.io/suite: brain
    appgear.io/topology: B
    appgear.io/workspace-id: <workspace_id>
    appgear.io/tenant-id: <tenant_id>
    appgear.io/module: "mod10-suite-brain"
spec:
  scaleTargetRef:
    kind: Deployment
    name: addon-brain-agents-crewai
  minReplicaCount: 0
  maxReplicaCount: 5
  cooldownPeriod: 300
  pollingInterval: 30
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://core-prometheus.observability.svc.cluster.local:9090
        metricName: brain_agents_active_tasks
        threshold: "1"
        query: |
          sum(brain_agents_active_tasks{workspace_id="<workspace_id>",tenant_id="<tenant_id>"})
EOF
```

---

### 5. Integração Flowise ↔ Brain (RAG + Agentes)

* No `core-flowise` (M08), configurar:

  * `FLOWISE_CUSTOM_NODES=/data/custom-nodes`;
  * Diretório `custom-nodes/brain` com:

    * Node “RAG Qdrant + Meilisearch”;
    * Node “Agents CrewAI” chamando `/agents/ws-<workspace_id>`.

* Todos os nodes de LLM no Flowise usam **LiteLLM**:

  * `LITELLM_BASE_URL` e `LITELLM_API_KEY` vindos de `Secret`/ENV (não definidos neste módulo, apenas referenciados).

---

### 6. Topologia A – Docker Compose (Dev-only)

Em `/opt/appgear/brain`:

```bash
mkdir -p /opt/appgear/brain
cd /opt/appgear/brain
```

`.env` (não usar em produção):

```bash
cat > .env << 'EOF'
MEILI_MASTER_KEY=dev-master-key
LITELLM_BASE_URL=http://litellm:4000
LITELLM_API_KEY=dev-key
QDRANT_URL=http://qdrant:6333
EOF
```

`docker-compose.brain.yml` (apenas laboratório):

```bash
cat > docker-compose.brain.yml << 'EOF'
version: "3.8"
services:
  meilisearch:
    image: getmeili/meilisearch:v1.10
    env_file: .env
    environment:
      MEILI_MASTER_KEY: ${MEILI_MASTER_KEY}
    volumes:
      - ./data/meili:/meili_data
    ports:
      - "7700:7700"

  agents:
    image: appgear/agents-crewai:latest
    env_file: .env
    environment:
      LITELLM_BASE_URL: ${LITELLM_BASE_URL}
      LITELLM_API_KEY: ${LITELLM_API_KEY}
      QDRANT_URL: ${QDRANT_URL}
      MEILISEARCH_URL: http://meilisearch:7700
    depends_on:
      - meilisearch
    ports:
      - "8085:8080"

  jupyter:
    image: jupyter/datascience-notebook:latest
    volumes:
      - ./notebooks:/home/jovyan/work
    ports:
      - "8888:8888"

  mlflow:
    image: appgear/mlflow-server:latest
    environment:
      MLFLOW_BACKEND_STORE_URI: sqlite:///mlflow.db
      MLFLOW_ARTIFACT_ROOT: /mlruns
    volumes:
      - ./mlruns:/mlruns
    ports:
      - "5000:5000"
EOF
```

Subir:

```bash
docker compose -f docker-compose.brain.yml up -d
```

> Topologia A é **apenas dev/lab**, sem garantia de Zero-Trust.

---

## 5. Como verificar

1. **Estrutura GitOps**

```bash
cd appgear-gitops-suites
tree apps/brain
```

Esperado:

* `apps/brain/kustomization.yaml`;
* Subpastas `meilisearch`, `jupyterhub`, `mlflow`, `agents-crewai` com os manifests.

2. **Argo CD**

```bash
argocd app list | grep suites-brain
argocd app get suites-brain
argocd app get addon-brain-jupyterhub
```

* STATUS: `Healthy`;
* SYNC: `Synced`.

3. **Namespaces e workloads**

```bash
kubectl get ns | egrep 'brain-data|brain-ml|ws-.*-brain'

kubectl get deploy,svc,ingress -n brain-data
kubectl get deploy,svc,ingress -n brain-ml
kubectl get deploy,svc,ingress -n ws-<workspace_id>-brain
```

4. **Cadeia de rede (sem IngressRoute)**

```bash
kubectl get ingress -A | egrep 'brain'

kubectl get ingressroute -A | egrep 'brain' || echo "OK: nenhum IngressRoute de Brain"
```

* Deve haver apenas `Ingress` com `ingressClassName: kong`.

5. **JupyterHub – Perfis S/M/L**

Na UI, o usuário deve conseguir escolher perfis S/M/L.
Para validar via `kubectl`:

```bash
kubectl get pod -n brain-ml \
  -l app.kubernetes.io/name=addon-brain-jupyterhub-user \
  -o yaml | grep -A5 'resources:'
```

6. **MLflow + Ceph S3**

```bash
kubectl logs deploy/addon-brain-mlflow -n brain-ml | tail
```

* Sem erros de S3;
* UI acessível em `https://brain.dev.appgear.local/mlflow` (via Kong/Keycloak).

7. **Agentes**

```bash
kubectl get deploy,svc,ingress,scaledobject -n ws-<workspace_id>-brain

curl -k https://brain.dev.appgear.local/agents/ws-<workspace_id>/health \
  -H "Authorization: Bearer <token>"
```

* Deve retornar 200 (health ok), após autenticação via Keycloak/Kong.

8. **FinOps**

No OpenCost/Lago:

* Filtrar por:

  * `appgear.io/suite=brain`;
  * `appgear.io/tenant-id` (global ou `<tenant_id>`).
* Conferir custo de:

  * Meilisearch;
  * JupyterHub/MLflow;
  * Agentes por workspace.

9. **Topologia A (Docker)**

```bash
cd /opt/appgear/brain
docker ps
```

* Containers `meilisearch`, `agents`, `jupyter`, `mlflow` devem estar `Up`;
* Acessar:

  * `http://localhost:7700` (Meilisearch);
  * `http://localhost:8085` (Agents);
  * `http://localhost:8888` (Jupyter);
  * `http://localhost:5000` (MLflow).

---

## 6. Erros comuns

1. **Criar IngressRoute de Traefik neste módulo**

   * Quebra o M02 e bypassa WAF/Gateway.
   * Correção: somente `Ingress` com `ingressClassName: kong` aqui; Traefik/Coraza são tratados no M02.

2. **Esquecer `appgear.io/tenant-id`**

   * FinOps não consegue atribuir custos a tenant/workspace.
   * Correção: garantir `appgear.io/tenant-id` em:

     * Namespace, Deployment, Service, Ingress, ScaledObject.

3. **Não configurar perfis S/M/L do JupyterHub**

   * Um único usuário pode derrubar o nó.
   * Correção: `singleuser.profileList` com `cpu_guarantee/limit` e `mem_guarantee/limit` para S/M/L.

4. **Agentes chamando LLM direto (sem LiteLLM)**

   * Viola o contrato de Gateway de IA (M08).
   * Correção: sempre usar `LITELLM_BASE_URL` + `LITELLM_API_KEY` nos agentes/nodes.

5. **Configuração inconsistente de Ceph para MLflow**

   * Artefatos não são salvos corretamente, erros 5xx na UI.
   * Correção: validar:

     * endpoint `core-ceph-rgw`;
     * credenciais S3 (Secrets);
     * bucket `brain-mlflow-artifacts`.

6. **Ausência de labels em pods de usuário JupyterHub**

   * Backstage/FinOps não conseguem rastrear notebooks.
   * Correção: usar `singleuser.extraLabels` nos values do Helm (como neste módulo).

7. **Usar Topologia A como se fosse produção**

   * Sem WAF, sem Zero-Trust, sem políticas de segurança/FinOps equivalentes.
   * Correção: limitar Topologia A a dev/lab; produção sempre na Topologia B.

---

## 7. Onde salvar

1. **Documento de contrato/desenvolvimento**

* Repositório: `appgear-contracts` ou `appgear-docs`;
* Arquivo:

  * `Módulo 10 – Suíte Brain (RAG, Agentes, AutoML) v0.1.md`;
* Referenciar em:

  * `1 - Desenvolvimento v0.md`, seção “Módulo 10 – Suíte Brain (RAG, Agentes, AutoML) – v0.1”.

2. **Repositório GitOps – Suítes**

* Repositório: `appgear-gitops-suites`;
* Estrutura:

```text
apps/brain/kustomization.yaml
apps/brain/meilisearch/*.yaml
apps/brain/jupyterhub/*.yaml
apps/brain/mlflow/*.yaml
apps/brain/agents-crewai/*.yaml

clusters/ag-<regiao>-core-<env>/apps-suites.yaml
  # contém a Application suites-brain / addon-brain-jupyterhub, conforme M01
```

3. **Topologia A (Docker)**

* Host de desenvolvimento:

```text
/opt/appgear/brain/.env
/opt/appgear/brain/docker-compose.brain.yml
/opt/appgear/brain/data
/opt/appgear/brain/notebooks
/opt/appgear/brain/mlruns
```

---

## 8. Dependências entre os módulos

A posição da Suíte Brain (Módulo 10) na arquitetura da AppGear é:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Define:

    * forma canônica de documentação (`.md`);
    * convenções de repositório (`appgear-gitops-core`, `appgear-gitops-suites`, `appgear-docs`);
    * labels `appgear.io/*` (incluindo `appgear.io/tenant-id`, `appgear.io/workspace-id`, `appgear.io/suite`);
    * diretrizes de FinOps aplicadas a todos os manifests deste módulo.

* **Módulo 01 – GitOps e Argo CD**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD como controlador GitOps;
    * `clusters/ag-<regiao>-core-<env>/apps-suites.yaml`, onde é registrada a Application da Suíte Brain (`suites-brain`, `addon-brain-jupyterhub`, etc.).

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * cadeia de borda **Traefik → Coraza → Kong → Istio**;
    * Kong como Ingress Controller/API Gateway, consumido neste módulo via `Ingress` (`/search`, `/jupyter`, `/mlflow`, `/agents/ws-<workspace_id>`);
    * Istio com mTLS STRICT entre pods da Suíte Brain e os serviços Core.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * **Dependência mútua.**
  * M03:

    * coleta métricas e custos de Meilisearch, JupyterHub, MLflow e Agentes;
  * M10:

    * expõe métricas específicas (ex.: `http_requests_meilisearch`, `brain_agents_active_tasks`) para KEDA e FinOps;
    * usa labels `appgear.io/tenant-id` e `appgear.io/suite=brain` para atribuição de custos.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, etc.)**

  * **Pré-requisito técnico.**
  * Fornece:

    * Qdrant (vetores) e Postgres (metadados) para RAG/ML;
    * Ceph (block e S3) para dados de Meilisearch e artefatos de MLflow;
    * Redis/Redpanda, caso usados por pipelines de treino/agentes.

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * **Pré-requisito direto.**
  * Fornece:

    * Vault como SSoT de segredos (chaves de Meilisearch, bancos, S3, LiteLLM, configs de agentes), consumidos via `secretKeyRef` e Vault Agent;
    * OPA para validar manifests (labels obrigatórias, ausência de segredos inline, proibição de `:latest`, etc.);
    * Falco monitorando runtime dos pods da Suíte Brain;
    * OpenFGA sendo consumido por camadas superiores para controle fino de acesso a notebooks/experimentos.

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * **Pré-requisito funcional.**
  * Fornece:

    * SSO (Keycloak) para acesso a JupyterHub, MLflow e APIs de agentes via Kong (`oidc-keycloak`);
    * atributos de identidade (tenant, workspace) usados para autorização e roteamento lógico.

* **Módulo 07 – Portal Backstage e Integrações Core**

  * **Consumidor da Suíte Brain.**
  * Fornece:

    * Portal onde usuários podem:

      * descobrir e consumir endpoints de RAG/Agentes;
      * acessar notebooks (Jupyter) e experimentos (MLflow);
    * templates de Scaffolder que combinam Brain com demais módulos (N8n, Factory, etc.).

* **Módulo 08 – Serviços de Aplicação Core (LiteLLM, Flowise, N8n, Directus, Appsmith, Metabase)**

  * **Altamente acoplado a este módulo.**
  * Fornece:

    * Flowise como orquestrador de pipelines de IA, consumindo Meilisearch, Qdrant, Agentes e LiteLLM;
    * LiteLLM como Gateway único de IA, utilizado por Jupyter/Agentes/Flowise;
    * N8n como motor de automação que pode acionar Agentes e pipelines de treino/inferência.

* **Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer)**

  * **Complementar à Suíte Brain.**
  * Fornece:

    * CDEs e Builders que podem usar modelos RAG/Agentes produzidos pela Brain;
    * pipelines de dados (Airbyte) para alimentar o Corporate Brain.

* **Módulo 10 – Suíte Brain (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06, M07, M08, M09**;
  * Entrega:

    * RAG híbrido (Qdrant + Meilisearch), AI Workforce por workspace e AutoML Studio (JupyterHub + MLflow) para toda a plataforma.

* **Módulos posteriores (ex.: Workspaces/vClusters, Suítes adicionais, PWA, Orquestração avançada)**

  * **Dependem deste módulo** para:

    * consumir RAG/Agentes como serviços de inteligência;
    * usar notebooks e modelos treinados como parte de fluxos de negócio e experiências de produto.

Em fluxo:

* **M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → M09 → M10 → (Workspaces, Suítes adicionais, PWA, etc.)**

Sem o Módulo 10, a AppGear não dispõe de uma camada padronizada de **RAG, Agentes e AutoML**, dificultando a construção de experiências inteligentes e a evolução de modelos de forma governada, multi-tenant e alinhada a FinOps.

---

## 9. Metadados
- Gerado automaticamente por CodeGPT
- Versão do módulo: v0.3
- Compatibilidade: full
- Data de geração: 2025-11-24
