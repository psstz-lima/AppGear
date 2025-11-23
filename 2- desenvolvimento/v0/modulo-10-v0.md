Perfeito, vamos considerar esse diagnóstico como a “ordem de retrofit” e já entregar o \*\*Módulo 10 v0.1\*\* pronto, corrigindo:



\* Formato (.py → .md)

\* Cadeia de segurança (sem bypass de WAF/Kong)

\* FinOps (label `appgear.io/tenant-id`)

\* Resources/T-shirt sizing para JupyterHub e Agentes



Abaixo está o \*\*Módulo 10 v0.1.md – Suíte Brain (RAG, Agentes, AutoML)\*\* já no padrão canônico.



---



\# Módulo 10 v0.1 – Suíte Brain (RAG, Agentes, AutoML)



Retrofit do \*\*Módulo 10 v0.py\*\*, corrigindo:



\* G15 – Forma Canônica (Markdown);

\* G05 – Segurança de Borda (sem IngressRoute direto, uso de `Ingress` com `ingressClassName: kong`);

\* M00-3 – FinOps (`appgear.io/tenant-id` em todos os recursos);

\* M00-3 – Resources (perfis T-shirt S/M/L para notebooks e agentes).



---



\## 1. O que é



A \*\*Suíte Brain\*\* é a suíte de inteligência da plataforma, composta por três blocos:



1\. \*\*Corporate Brain (RAG / Busca Semântica)\*\*



&nbsp;  \* RAG híbrido:



&nbsp;    \* Vetorial no \*\*Core Qdrant\*\*;

&nbsp;    \* Texto full-text no \*\*addon-brain-meilisearch\*\*;

&nbsp;  \* Orquestrado via \*\*Flowise + LiteLLM\*\* (gate de LLM único).

&nbsp;  \* Exposto como APIs para demais apps (Directus, Appsmith, PWA, Backstage, N8n).



2\. \*\*AI Workforce (Agentes Autônomos)\*\*



&nbsp;  \* Serviço `addon-brain-agents-crewai` por workspace:



&nbsp;    \* Agentes CrewAI/AutoGen;

&nbsp;    \* Consomem contexto do RAG (Qdrant + Meilisearch);

&nbsp;    \* Chamam apenas \*\*core-litellm\*\* (M08) para LLMs;

&nbsp;    \* Podem disparar fluxos no N8n/BPMN (M08).



3\. \*\*AutoML Studio (No-Code AutoML)\*\*



&nbsp;  \* Composto por:



&nbsp;    \* \*\*JupyterHub\*\* (`addon-brain-jupyterhub`) – notebooks por usuário;

&nbsp;    \* \*\*MLflow\*\* (`addon-brain-mlflow`) – tracking + registry;

&nbsp;    \* Armazenamento:



&nbsp;      \* Metadados em \*\*Postgres Core\*\* (M04);

&nbsp;      \* Artefatos em \*\*Ceph S3\*\* (M04 – RGW ou MinIO gateway).

&nbsp;  \* Provisiona modelos que podem virar “tools” de agentes ou serviços consumidos via N8n/Flowise.



4\. \*\*Topologias\*\*



\* \*\*Topologia B (produção em Kubernetes)\*\*



&nbsp; \* Implementada via GitOps em `appgear-gitops-suites/apps/brain`;

&nbsp; \* Exposição externa SEMPRE passa por:



&nbsp;   \* Traefik → Coraza (WAF) → Kong (Ingress controller/API Gateway) → Istio (mTLS STRICT)

&nbsp;   \* Este módulo \*\*não\*\* cria `IngressRoute` de Traefik.

&nbsp;   \* Este módulo cria apenas `Ingress` com `ingressClassName: kong`.



\* \*\*Topologia A (dev / laboratório Docker)\*\*



&nbsp; \* Compose com Meilisearch + Agentes + Jupyter + MLflow;

&nbsp; \* Dev-only, sem WAF/Zero-Trust; explicitamente NÃO recomendada para produção.



---



\## 2. Por que



1\. \*\*Corrigir violações de segurança (G05)\*\*



&nbsp;  \* O módulo v0 expunha \*\*JupyterHub, MLflow, Meilisearch\*\* via `IngressRoute` do Traefik, quebrando a cadeia Traefik → Coraza → Kong → Istio e expondo ferramentas de execução de código arbitrário sem WAF/Gateway.

&nbsp;  \* O v0.1 passa a:



&nbsp;    \* Usar apenas recursos \*\*`Ingress` (networking.k8s.io/v1)`com`ingressClassName: kong`\*\*;

&nbsp;    \* Deixar a lógica de Traefik/Coraza a cargo do M02 (Rede).



2\. \*\*Atender FinOps e multi-tenant (M00-3)\*\*



&nbsp;  \* IA/ML (Jupyter, Agentes, Treinos) são os maiores consumidores de CPU/GPU/memória.

&nbsp;  \* Sem `appgear.io/tenant-id`, os custos não são atribuídos aos clientes/workspaces.

&nbsp;  \* v0.1 adiciona:



&nbsp;    \* `appgear.io/tenant-id: global` para serviços compartilhados;

&nbsp;    \* `appgear.io/tenant-id: <tenant\_id>` para workloads por cliente/workspace.



3\. \*\*Governança de recursos (Resources / T-shirt sizing)\*\*



&nbsp;  \* No v0, pods de usuário JupyterHub não tinham limits/requests ⇒ um usuário podia derrubar o nó.

&nbsp;  \* v0.1 define \*\*perfis S/M/L\*\*:



&nbsp;    \* Em `singleuser.profileList` do JupyterHub (S/M/L) com CPU/mem requests/limits;

&nbsp;    \* Em `agents-crewai` com limits S por padrão, podendo escalar vertical/horizontal.



4\. \*\*Interoperabilidade confirmada (RAG híbrido)\*\*



&nbsp;  \* Mantém a integração correta:



&nbsp;    \* Vetorial no Qdrant (Core);

&nbsp;    \* Texto no Meilisearch (Brain);

&nbsp;    \* LiteLLM como gateway AI (M08);

&nbsp;    \* Ceph/S3 + Postgres (M04) para Jupyter/MLflow.



---



\## 3. Pré-requisitos



\### 3.1 Organizacionais



\* \*\*0 - Contrato v0.md\*\* como fonte de verdade.

\* Módulos anteriores publicados e aplicados:



&nbsp; \* M00 – Convenções, nomenclatura, labels e FinOps;

&nbsp; \* M01 – Bootstrap GitOps/Argo CD;

&nbsp; \* M02 – Borda, WAF, Gateway, Istio (cadeia Traefik → Coraza → Kong → Istio, mTLS STRICT);

&nbsp; \* M03 – Observabilidade \& FinOps (Prometheus, Grafana, Loki, OpenCost, Lago);

&nbsp; \* M04 – Armazenamento \& Bancos (Ceph, Postgres, Redis, Qdrant, Redpanda, etc.);

&nbsp; \* M05 – Segurança \& Segredos (Vault, OPA, Falco, OpenFGA);

&nbsp; \* M06 – Identidade \& SSO (Keycloak, midPoint, RBAC/ReBAC);

&nbsp; \* M07 – Backstage (portal) integrado a FinOps e Observabilidade;

&nbsp; \* M08 – Serviços Core (Flowise, LiteLLM, Directus, Appsmith, N8n, etc.);

&nbsp; \* M09 – Factory (CDEs, Airbyte, Build).



\### 3.2 Infraestrutura – Topologia B (Kubernetes)



\* Cluster `ag-<regiao>-core-<env>` com:



&nbsp; \* `core-qdrant`, `core-postgres`, `core-redis`, `core-ceph`, `core-keda`, `core-prometheus`, `core-grafana`, `core-litellm`, `core-flowise`;

&nbsp; \* Istio com `PeerAuthentication` STRICT;

&nbsp; \* Kong instalado como Ingress Controller (integrado à cadeia de rede do M02).



\* Namespaces:



&nbsp; \* `brain-data` – Corporate Brain / Meilisearch;

&nbsp; \* `brain-ml` – AutoML Studio (JupyterHub + MLflow);

&nbsp; \* `ws-<workspace\_id>-brain` – AI Workforce por workspace.



\### 3.3 Ferramentas



\* `git`, `kubectl`, `kustomize`, `argocd` CLI;

\* Acesso aos repositórios:



&nbsp; \* `appgear-gitops-suites` (Suítes);

&nbsp; \* `appgear-gitops-core` (Core).



\### 3.4 Topologia A (Dev Docker)



\* Host Linux com Docker + docker-compose;

\* Diretório base `/opt/appgear/brain`;

\* .env central compartilhado com outros módulos (se desejado).



---



\## 4. Como fazer (comandos)



\### 4.1 Estrutura GitOps da Suíte Brain



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

&nbsp; - meilisearch

&nbsp; - jupyterhub

&nbsp; - mlflow

&nbsp; - agents-crewai

EOF

```



Commit:



```bash

git add apps/brain

git commit -m "mod10 v0.1: estrutura inicial da Suíte Brain"

git push origin main

```



---



\### 4.2 Corporate Brain – Meilisearch (Add-on Texto)



\#### 4.2.1 Namespace + PVC + Deployment + Service



`apps/brain/meilisearch/kustomization.yaml`:



```bash

cat > apps/brain/meilisearch/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: brain-data



resources:

&nbsp; - namespace.yaml

&nbsp; - pvc-meilisearch.yaml

&nbsp; - deployment-meilisearch.yaml

&nbsp; - service-meilisearch.yaml

&nbsp; - ingress-meilisearch.yaml

&nbsp; - scaledobject-meilisearch.yaml

EOF

```



`namespace.yaml`:



```bash

cat > apps/brain/meilisearch/namespace.yaml << 'EOF'

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: brain-data

&nbsp; labels:

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod10-suite-brain"

EOF

```



`pvc-meilisearch.yaml`:



```bash

cat > apps/brain/meilisearch/pvc-meilisearch.yaml << 'EOF'

apiVersion: v1

kind: PersistentVolumeClaim

metadata:

&nbsp; name: meilisearch-data

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-meilisearch

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; accessModes:

&nbsp;   - ReadWriteOnce

&nbsp; storageClassName: ceph-block

&nbsp; resources:

&nbsp;   requests:

&nbsp;     storage: 50Gi

EOF

```



`deployment-meilisearch.yaml`:



```bash

cat > apps/brain/meilisearch/deployment-meilisearch.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-brain-meilisearch

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-meilisearch

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-brain-meilisearch

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-brain-meilisearch

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: brain

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;   spec:

&nbsp;     serviceAccountName: core-services

&nbsp;     containers:

&nbsp;       - name: meilisearch

&nbsp;         image: getmeili/meilisearch:v1.10

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 7700

&nbsp;         env:

&nbsp;           - name: MEILI\_ENV

&nbsp;             value: "production"

&nbsp;           - name: MEILI\_NO\_ANALYTICS

&nbsp;             value: "true"

&nbsp;           - name: MEILI\_MASTER\_KEY

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: brain-meilisearch-keys

&nbsp;                 key: master\_key

&nbsp;         volumeMounts:

&nbsp;           - name: data

&nbsp;             mountPath: /meili\_data

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "4Gi"

&nbsp;     volumes:

&nbsp;       - name: data

&nbsp;         persistentVolumeClaim:

&nbsp;           claimName: meilisearch-data

EOF

```



`service-meilisearch.yaml`:



```bash

cat > apps/brain/meilisearch/service-meilisearch.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-brain-meilisearch

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-meilisearch

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-brain-meilisearch

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 7700

&nbsp;     targetPort: http

EOF

```



\#### 4.2.2 Ingress via Kong (sem Traefik IngressRoute)



`ingress-meilisearch.yaml`:



```bash

cat > apps/brain/meilisearch/ingress-meilisearch.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: addon-brain-meilisearch

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-meilisearch

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

&nbsp; annotations:

&nbsp;   konghq.com/plugins: "oidc-keycloak,rate-limit"

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: brain.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /search

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: addon-brain-meilisearch

&nbsp;               port:

&nbsp;                 number: 7700

EOF

```



> A entrada Traefik/Coraza que aponta para o Kong já é tratada no M02; este módulo \*\*não\*\* cria IngressRoute.



\#### 4.2.3 KEDA ScaledObject



`scaledobject-meilisearch.yaml`:



```bash

cat > apps/brain/meilisearch/scaledobject-meilisearch.yaml << 'EOF'

apiVersion: keda.sh/v1alpha1

kind: ScaledObject

metadata:

&nbsp; name: addon-brain-meilisearch

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-meilisearch

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; scaleTargetRef:

&nbsp;   kind: Deployment

&nbsp;   name: addon-brain-meilisearch

&nbsp; minReplicaCount: 0

&nbsp; maxReplicaCount: 5

&nbsp; cooldownPeriod: 300

&nbsp; pollingInterval: 60

&nbsp; triggers:

&nbsp;   - type: prometheus

&nbsp;     metadata:

&nbsp;       serverAddress: http://core-prometheus.observability.svc.cluster.local:9090

&nbsp;       metricName: http\_requests\_meilisearch

&nbsp;       threshold: "1"

&nbsp;       query: |

&nbsp;         sum(rate(meilisearch\_http\_requests\_total\[1m]))

EOF

```



---



\### 4.3 AutoML Studio – JupyterHub + MLflow



\#### 4.3.1 JupyterHub – Application Argo CD + T-shirt sizing



`apps/brain/jupyterhub/kustomization.yaml`:



```bash

cat > apps/brain/jupyterhub/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - namespace.yaml

&nbsp; - application-jupyterhub.yaml

EOF

```



`namespace.yaml`:



```bash

cat > apps/brain/jupyterhub/namespace.yaml << 'EOF'

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: brain-ml

&nbsp; labels:

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod10-suite-brain"

EOF

```



`application-jupyterhub.yaml` (trecho principal com perfis S/M/L):



```bash

cat > apps/brain/jupyterhub/application-jupyterhub.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: Application

metadata:

&nbsp; name: addon-brain-jupyterhub

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-jupyterhub

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; project: appgear-suites

&nbsp; source:

&nbsp;   repoURL: https://jupyterhub.github.io/helm-chart

&nbsp;   chart: jupyterhub

&nbsp;   targetRevision: 2.0.0

&nbsp;   helm:

&nbsp;     values: |

&nbsp;       proxy:

&nbsp;         service:

&nbsp;           type: ClusterIP



&nbsp;       hub:

&nbsp;         extraLabels:

&nbsp;           app.kubernetes.io/name: addon-brain-jupyterhub

&nbsp;           appgear.io/tier: addon

&nbsp;           appgear.io/suite: brain

&nbsp;           appgear.io/topology: B

&nbsp;           appgear.io/workspace-id: global

&nbsp;           appgear.io/tenant-id: global

&nbsp;         db:

&nbsp;           type: postgres

&nbsp;           url: postgresql://$(JUPYTERHUB\_DB\_USER):$(JUPYTERHUB\_DB\_PASS)@core-postgres.appgear-core.svc.cluster.local:5432/jupyterhub



&nbsp;       singleuser:

&nbsp;         extraLabels:

&nbsp;           app.kubernetes.io/name: addon-brain-jupyterhub-user

&nbsp;           appgear.io/tier: addon

&nbsp;           appgear.io/suite: brain

&nbsp;           appgear.io/topology: B

&nbsp;           appgear.io/workspace-id: global

&nbsp;           appgear.io/tenant-id: global

&nbsp;         storage:

&nbsp;           dynamic:

&nbsp;             storageClass: ceph-filesystem

&nbsp;             capacity: 20Gi

&nbsp;         extraEnv:

&nbsp;           LITELLM\_BASE\_URL: "http://core-litellm.appgear-core.svc.cluster.local"

&nbsp;           LITELLM\_API\_KEY: "$(LITELLM\_API\_KEY)"

&nbsp;         profileList:

&nbsp;           - display\_name: "S - Exploração leve"

&nbsp;             description: "Notebooks de análise e prototipagem."

&nbsp;             slug: "size-s"

&nbsp;             kubespawner\_override:

&nbsp;               cpu\_guarantee: 0.25

&nbsp;               cpu\_limit: 1

&nbsp;               mem\_guarantee: "512Mi"

&nbsp;               mem\_limit: "2Gi"

&nbsp;           - display\_name: "M - Treino moderado"

&nbsp;             description: "Experimentos de treino médio porte."

&nbsp;             slug: "size-m"

&nbsp;             kubespawner\_override:

&nbsp;               cpu\_guarantee: 1

&nbsp;               cpu\_limit: 2

&nbsp;               mem\_guarantee: "2Gi"

&nbsp;               mem\_limit: "4Gi"

&nbsp;           - display\_name: "L - Treino pesado controlado"

&nbsp;             description: "Treinos mais pesados (com aprovação)."

&nbsp;             slug: "size-l"

&nbsp;             kubespawner\_override:

&nbsp;               cpu\_guarantee: 2

&nbsp;               cpu\_limit: 4

&nbsp;               mem\_guarantee: "4Gi"

&nbsp;               mem\_limit: "8Gi"



&nbsp;       auth:

&nbsp;         type: custom

&nbsp;         custom:

&nbsp;           className: "keycloak"  # integração M06



&nbsp;       ingress:

&nbsp;         enabled: true

&nbsp;         ingressClassName: kong

&nbsp;         hosts:

&nbsp;           - brain.dev.appgear.local

&nbsp;         pathSuffix: ""

&nbsp;         annotations:

&nbsp;           konghq.com/plugins: "oidc-keycloak,rate-limit"

&nbsp;         paths:

&nbsp;           - /jupyter

&nbsp; destination:

&nbsp;   server: https://kubernetes.default.svc

&nbsp;   namespace: brain-ml

&nbsp; syncPolicy:

&nbsp;   automated:

&nbsp;     prune: true

&nbsp;     selfHeal: true

&nbsp;   syncOptions:

&nbsp;     - CreateNamespace=true

EOF

```



> Aqui está explicitamente resolvido o ponto de \*\*resources nos pods de usuário JupyterHub\*\* via T-shirt S/M/L.



\#### 4.3.2 MLflow – Deployment + Service + Ingress (Kong)



`apps/brain/mlflow/kustomization.yaml`:



```bash

cat > apps/brain/mlflow/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: brain-ml



resources:

&nbsp; - deployment-mlflow.yaml

&nbsp; - service-mlflow.yaml

&nbsp; - ingress-mlflow.yaml

EOF

```



`deployment-mlflow.yaml`:



```bash

cat > apps/brain/mlflow/deployment-mlflow.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-brain-mlflow

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-mlflow

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-brain-mlflow

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-brain-mlflow

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: brain

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;   spec:

&nbsp;     serviceAccountName: core-services

&nbsp;     containers:

&nbsp;       - name: mlflow

&nbsp;         image: appgear/mlflow-server:latest

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 5000

&nbsp;         env:

&nbsp;           - name: MLFLOW\_BACKEND\_STORE\_URI

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: brain-mlflow-db

&nbsp;                 key: backend\_uri

&nbsp;           - name: MLFLOW\_ARTIFACT\_ROOT

&nbsp;             value: s3://brain-mlflow-artifacts/

&nbsp;           - name: AWS\_ACCESS\_KEY\_ID

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: ceph-s3-mlflow

&nbsp;                 key: access\_key

&nbsp;           - name: AWS\_SECRET\_ACCESS\_KEY

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: ceph-s3-mlflow

&nbsp;                 key: secret\_key

&nbsp;           - name: MLFLOW\_S3\_ENDPOINT\_URL

&nbsp;             value: http://core-ceph-rgw.appgear-core.svc.cluster.local:8080

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "2Gi"

EOF

```



`service-mlflow.yaml`:



```bash

cat > apps/brain/mlflow/service-mlflow.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-brain-mlflow

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-mlflow

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-brain-mlflow

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 5000

&nbsp;     targetPort: http

EOF

```



`ingress-mlflow.yaml`:



```bash

cat > apps/brain/mlflow/ingress-mlflow.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: addon-brain-mlflow

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-mlflow

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp;   appgear.io/module: "mod10-suite-brain"

&nbsp; annotations:

&nbsp;   konghq.com/plugins: "oidc-keycloak,rate-limit"

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: brain.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /mlflow

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: addon-brain-mlflow

&nbsp;               port:

&nbsp;                 number: 5000

EOF

```



---



\### 4.4 AI Workforce – Agents CrewAI (por workspace)



`apps/brain/agents-crewai/kustomization.yaml` (modelo; M13 pode gerar overlays por workspace):



```bash

cat > apps/brain/agents-crewai/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - deployment-agents.yaml

&nbsp; - service-agents.yaml

&nbsp; - ingress-agents.yaml

&nbsp; - scaledobject-agents.yaml

EOF

```



`deployment-agents.yaml` (parâmetros <workspace\_id>, <tenant\_id>):



```bash

cat > apps/brain/agents-crewai/deployment-agents.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-brain-agents-crewai

&nbsp; namespace: ws-<workspace\_id>-brain

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-agents-crewai

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-brain-agents-crewai

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-brain-agents-crewai

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: brain

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: <workspace\_id>

&nbsp;       appgear.io/tenant-id: <tenant\_id>

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;       vault.hashicorp.com/agent-inject: "true"

&nbsp;       vault.hashicorp.com/role: "ws-<workspace\_id>-brain"

&nbsp;       vault.hashicorp.com/agent-inject-secret-agents-config: "kv/data/appgear/addon-brain-agents-crewai/config"

&nbsp;   spec:

&nbsp;     serviceAccountName: core-services

&nbsp;     containers:

&nbsp;       - name: agents

&nbsp;         image: appgear/agents-crewai:latest

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 8080

&nbsp;         env:

&nbsp;           - name: WORKSPACE\_ID

&nbsp;             value: "<workspace\_id>"

&nbsp;           - name: TENANT\_ID

&nbsp;             value: "<tenant\_id>"

&nbsp;           - name: LITELLM\_BASE\_URL

&nbsp;             value: "http://core-litellm.appgear-core.svc.cluster.local"

&nbsp;           - name: LITELLM\_API\_KEY

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: litellm-api-key

&nbsp;                 key: api\_key

&nbsp;           - name: QDRANT\_URL

&nbsp;             value: "http://core-qdrant.appgear-core.svc.cluster.local:6333"

&nbsp;           - name: MEILISEARCH\_URL

&nbsp;             value: "http://addon-brain-meilisearch.brain-data.svc.cluster.local:7700"

&nbsp;         resources:       # Perfil S por default; M/L podem ser variações futuras

&nbsp;           requests:

&nbsp;             cpu: "250m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "4Gi"

EOF

```



`service-agents.yaml`:



```bash

cat > apps/brain/agents-crewai/service-agents.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-brain-agents-crewai

&nbsp; namespace: ws-<workspace\_id>-brain

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-agents-crewai

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-brain-agents-crewai

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 80

&nbsp;     targetPort: http

EOF

```



`ingress-agents.yaml`:



```bash

cat > apps/brain/agents-crewai/ingress-agents.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: addon-brain-agents-crewai

&nbsp; namespace: ws-<workspace\_id>-brain

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-agents-crewai

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp;   appgear.io/module: "mod10-suite-brain"

&nbsp; annotations:

&nbsp;   konghq.com/plugins: "oidc-keycloak,rate-limit"

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: brain.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /agents/ws-<workspace\_id>

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: addon-brain-agents-crewai

&nbsp;               port:

&nbsp;                 number: 80

EOF

```



`scaledobject-agents.yaml`:



```bash

cat > apps/brain/agents-crewai/scaledobject-agents.yaml << 'EOF'

apiVersion: keda.sh/v1alpha1

kind: ScaledObject

metadata:

&nbsp; name: addon-brain-agents-crewai

&nbsp; namespace: ws-<workspace\_id>-brain

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-brain-agents-crewai

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: brain

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp;   appgear.io/module: "mod10-suite-brain"

spec:

&nbsp; scaleTargetRef:

&nbsp;   kind: Deployment

&nbsp;   name: addon-brain-agents-crewai

&nbsp; minReplicaCount: 0

&nbsp; maxReplicaCount: 5

&nbsp; cooldownPeriod: 300

&nbsp; pollingInterval: 30

&nbsp; triggers:

&nbsp;   - type: prometheus

&nbsp;     metadata:

&nbsp;       serverAddress: http://core-prometheus.observability.svc.cluster.local:9090

&nbsp;       metricName: brain\_agents\_active\_tasks

&nbsp;       threshold: "1"

&nbsp;       query: |

&nbsp;         sum(brain\_agents\_active\_tasks{workspace\_id="<workspace\_id>",tenant\_id="<tenant\_id>"})

EOF

```



---



\### 4.5 Integração Flowise ↔ Brain (RAG + Agentes)



\* No `core-flowise` (M08), configurar:



&nbsp; \* `FLOWISE\_CUSTOM\_NODES=/data/custom-nodes`;

&nbsp; \* Diretório `custom-nodes/brain` com:



&nbsp;   \* Node “RAG Qdrant + Meilisearch”;

&nbsp;   \* Node “Agents CrewAI” chamando `/agents/ws-<workspace\_id>`.



\* Todos os nodes de LLM no Flowise usam \*\*LiteLLM\*\*:



&nbsp; \* `LITELLM\_BASE\_URL` e `LITELLM\_API\_KEY` vindos de secrets/ENV.



---



\### 4.6 Topologia A – Docker Compose (Dev-only)



Em `/opt/appgear/brain`:



```bash

mkdir -p /opt/appgear/brain

cd /opt/appgear/brain

```



`.env` (não usar em produção):



```bash

cat > .env << 'EOF'

MEILI\_MASTER\_KEY=dev-master-key

LITELLM\_BASE\_URL=http://litellm:4000

LITELLM\_API\_KEY=dev-key

QDRANT\_URL=http://qdrant:6333

EOF

```



`docker-compose.brain.yml` (apenas para laboratório):



```bash

cat > docker-compose.brain.yml << 'EOF'

version: "3.8"

services:

&nbsp; meilisearch:

&nbsp;   image: getmeili/meilisearch:v1.10

&nbsp;   env\_file: .env

&nbsp;   environment:

&nbsp;     MEILI\_MASTER\_KEY: ${MEILI\_MASTER\_KEY}

&nbsp;   volumes:

&nbsp;     - ./data/meili:/meili\_data

&nbsp;   ports:

&nbsp;     - "7700:7700"



&nbsp; agents:

&nbsp;   image: appgear/agents-crewai:latest

&nbsp;   env\_file: .env

&nbsp;   environment:

&nbsp;     LITELLM\_BASE\_URL: ${LITELLM\_BASE\_URL}

&nbsp;     LITELLM\_API\_KEY: ${LITELLM\_API\_KEY}

&nbsp;     QDRANT\_URL: ${QDRANT\_URL}

&nbsp;     MEILISEARCH\_URL: http://meilisearch:7700

&nbsp;   depends\_on:

&nbsp;     - meilisearch

&nbsp;   ports:

&nbsp;     - "8085:8080"



&nbsp; jupyter:

&nbsp;   image: jupyter/datascience-notebook:latest

&nbsp;   volumes:

&nbsp;     - ./notebooks:/home/jovyan/work

&nbsp;   ports:

&nbsp;     - "8888:8888"



&nbsp; mlflow:

&nbsp;   image: appgear/mlflow-server:latest

&nbsp;   environment:

&nbsp;     MLFLOW\_BACKEND\_STORE\_URI: sqlite:///mlflow.db

&nbsp;     MLFLOW\_ARTIFACT\_ROOT: /mlruns

&nbsp;   volumes:

&nbsp;     - ./mlruns:/mlruns

&nbsp;   ports:

&nbsp;     - "5000:5000"

EOF

```



Subir:



```bash

docker compose -f docker-compose.brain.yml up -d

```



> Documentar explicitamente que a Topologia A é para \*\*dev/lab\*\*, sem garantir Zero-Trust.



---



\## 5. Como verificar



1\. \*\*Estrutura GitOps\*\*



```bash

cd appgear-gitops-suites

tree apps/brain

```



Esperado:



\* `apps/brain/kustomization.yaml`;

\* Subpastas `meilisearch`, `jupyterhub`, `mlflow`, `agents-crewai` com manifests.



2\. \*\*Argo CD\*\*



```bash

argocd app list | grep suites-brain

argocd app get suites-brain

argocd app get addon-brain-jupyterhub

```



\* STATUS: `Healthy`

\* SYNC: `Synced`.



3\. \*\*Namespaces e workloads\*\*



```bash

kubectl get ns | egrep 'brain-data|brain-ml|ws-.\*-brain'

kubectl get deploy,svc,ingress -n brain-data

kubectl get deploy,svc,ingress -n brain-ml

kubectl get deploy,svc,ingress -n ws-<workspace\_id>-brain

```



4\. \*\*Cadeia de rede (sem IngressRoute)\*\*



```bash

kubectl get ingress -A | egrep 'brain'

kubectl get ingressroute -A | egrep 'brain' || echo "OK: nenhum IngressRoute de Brain"

```



5\. \*\*JupyterHub – perfis S/M/L\*\*



Na UI:



\* Verificar que o usuário pode escolher perfis S/M/L;

\* Conferir via:



```bash

kubectl get pod -n brain-ml -l app.kubernetes.io/name=addon-brain-jupyterhub-user -o yaml | grep -A5 'resources:'

```



6\. \*\*MLflow + Ceph\*\*



```bash

kubectl logs deploy/addon-brain-mlflow -n brain-ml | tail

```



\* Sem erros de S3;

\* Conseguir criar um experimento via UI.



7\. \*\*Agentes\*\*



```bash

kubectl get deploy,svc,ingress,scaledobject -n ws-<workspace\_id>-brain

curl -k https://brain.dev.appgear.local/agents/ws-<workspace\_id>/health -H "Authorization: Bearer <token>"

```



8\. \*\*FinOps\*\*



\* Em OpenCost / Lago, verificar agrupamento por:



&nbsp; \* `appgear.io/suite=brain`;

&nbsp; \* `appgear.io/tenant-id`.



---



\## 6. Erros comuns



1\. \*\*Criar IngressRoute de Traefik neste módulo\*\*



&nbsp;  \* Quebra o M02, bypassa WAF/Gateway.

&nbsp;  \* Correção: apenas `Ingress` com `ingressClassName: kong`.



2\. \*\*Esquecer `appgear.io/tenant-id`\*\*



&nbsp;  \* FinOps não consegue atribuir custos à tenant/workspace.

&nbsp;  \* Correção: adicionar label em todos os objetos (Namespace, Deployment, Service, Ingress, ScaledObject).



3\. \*\*Não configurar perfis S/M/L do JupyterHub\*\*



&nbsp;  \* Usuário único pode derrubar o nó.

&nbsp;  \* Correção: `singleuser.profileList` com `cpu\_guarantee/limit` e `mem\_guarantee/limit`.



4\. \*\*Agentes chamando LLM direto (sem LiteLLM)\*\*



&nbsp;  \* Viola M08 e contrato (IA Gateway).

&nbsp;  \* Correção: sempre `LITELLM\_BASE\_URL` + `LITELLM\_API\_KEY`.



5\. \*\*Configuração inconsistente de Ceph para MLflow\*\*



&nbsp;  \* Falhas ao salvar artefatos, erros 5xx na UI.

&nbsp;  \* Correção: validar endpoint, credenciais e bucket `brain-mlflow-artifacts`.



6\. \*\*Ausência de labels em pods de usuário JupyterHub\*\*



&nbsp;  \* Backstage/FinOps não consegue rastrear notebooks.

&nbsp;  \* Correção: `singleuser.extraLabels` no Helm values.



---



\## 7. Onde salvar



1\. \*\*Documento de contrato/desenvolvimento\*\*



\* Salvar este conteúdo como:



&nbsp; \* `Módulo 10 v0.1.md`

&nbsp; \* Dentro do repositório de contratos:



&nbsp;   \* `appgear-contracts/1 - Desenvolvimento v0.md` (seção do Módulo 10)

&nbsp;   \* ou como arquivo próprio `Módulo 10 v0.1.md` referenciado pelo índice.



2\. \*\*Repositório GitOps – Suítes\*\*



\* `appgear-gitops-suites/apps/brain/\*\*` conforme comandos acima.



3\. \*\*Topologia A (Docker)\*\*



\* `/opt/appgear/brain/.env`

\* `/opt/appgear/brain/docker-compose.brain.yml`

\* `/opt/appgear/brain/data`, `/opt/appgear/brain/notebooks`, `/opt/appgear/brain/mlruns`.



---



Com isso, o \*\*Módulo 10\*\* fica \*\*em conformidade\*\* com o diagnóstico (G15, G05, M00-3 FinOps, M00-3 Resources), mantendo a interoperabilidade RAG/Agentes/AutoML e sem bypass de segurança.



