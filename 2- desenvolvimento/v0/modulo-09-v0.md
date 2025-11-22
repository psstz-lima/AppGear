Segue o \*\*Módulo 09 reescrito\*\* já como \*\*v0.1 em Markdown\*\*, corrigindo:



\* formato (Markdown, não .py);

\* borda (sem IngressRoute/Traefik direto – agora \*\*Ingress com `ingressClassName: kong`\*\*);

\* FinOps (inclusão da label obrigatória \*\*`appgear.io/tenant-id`\*\* em todos os recursos);

\* mantendo o uso de \*\*Ceph Filesystem\*\* para CDE (✅ M04) e \*\*Airbyte compartilhado\*\* (✅ Escalabilidade).



Use como base para o arquivo `Módulo 09 v0.1.md`.



---



\# Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer) – v0.1



---



\## 1. O que é



A \*\*Suíte Factory\*\* é a Suíte 1 da plataforma (Núcleo de Construção) e entrega, na v0:



1\. \*\*CDEs – VS Code Server (addon-factory-vscode)\*\*



&nbsp;  \* Ambientes de desenvolvimento em nuvem, isolados por workspace (`ws-<workspace\_id>-factory`), com:



&nbsp;    \* storage persistente em \*\*Ceph Filesystem\*\* (`storageClassName: ceph-filesystem`);

&nbsp;    \* segredos via \*\*Vault\*\* (sem `.env` sensível);

&nbsp;    \* autenticação centralizada via \*\*Kong + Keycloak\*\* (cadeia Traefik → Coraza → Kong → Istio);

&nbsp;    \* \*\*Scale-to-Zero\*\* com \*\*KEDA\*\*.



2\. \*\*Airbyte – Pipelines de Dados / Legacy Migration (addon-factory-airbyte)\*\*



&nbsp;  \* Instância \*\*multi-tenant lógica\*\* por ambiente (`factory-data`), com:



&nbsp;    \* conectores e pipelines compartilhados;

&nbsp;    \* isolamentos lógicos por `workspace\_id` e `tenant\_id`;

&nbsp;    \* recursos limitados (`resources.requests/limits`) para evitar consumo excessivo de memória.



3\. \*\*Build Nativo – React Native / Tauri (addon-factory-tauri-builder)\*\*



&nbsp;  \* Serviço de build nativo \*\*on-demand\*\* por workspace:



&nbsp;    \* recebe pedidos de build via N8n/Portal;

&nbsp;    \* gera builds mobile/desktop e sobe artefatos para Ceph/S3;

&nbsp;    \* escala com KEDA conforme a fila de builds.



4\. \*\*Multiplayer – Colaboração em Tempo Real (addon-factory-multiplayer)\*\*



&nbsp;  \* Gateway WebSocket para colaboração simultânea:



&nbsp;    \* presença, edição simultânea, locks;

&nbsp;    \* backplane em \*\*Redis/Redpanda\*\*;

&nbsp;    \* tráfego sempre passando por \*\*Kong\*\* (Ingress com `ingressClassName: kong`).



5\. \*\*Topologias\*\*



\* \*\*Topologia B (Kubernetes / Produção)\*\*



&nbsp; \* Suíte Factory declarada via \*\*GitOps/Argo CD\*\* no repo `webapp-ia-gitops-suites`.

&nbsp; \* CDEs/Builder/Multiplayer rodando em `ws-<workspace\_id>-factory` (vClusters).

&nbsp; \* Airbyte único por ambiente em `factory-data`.



\* \*\*Topologia A (Docker / Legado)\*\*



&nbsp; \* Compose mínimo para \*\*CDE local\*\* atrás do Traefik (somente PoC/dev).

&nbsp; \* Airbyte/Build/Multiplayer apenas na Topologia B.



---



\## 2. Por que



1\. \*\*Atender ao Contrato v0 – Suíte 1 (Factory)\*\*



&nbsp;  \* Entregar infraestrutura para:



&nbsp;    \* \*\*CDEs seguros\*\* (VS Code);

&nbsp;    \* \*\*Build Nativo\*\* (React Native, Tauri);

&nbsp;    \* \*\*Multiplayer\*\*;

&nbsp;    \* \*\*Legacy Migration\*\* (Airbyte).



2\. \*\*Corrigir os problemas identificados no Diagnóstico v0\*\*



\* \*\*G15 – Forma Canônica\*\*



&nbsp; \* v0 estava em `.py`; padrão obrigatório é Markdown (`Módulo 09 v0.1.md`).



\* \*\*G05 – Segurança de Borda (Bypass)\*\*



&nbsp; \* v0 expunha VS Code/Airbyte via \*\*IngressRoute/Traefik\*\*, quebrando a cadeia:



&nbsp;   \* correto: \*\*Traefik → Coraza (WAF) → Kong (APIGW) → Istio → serviços\*\*;

&nbsp;   \* este módulo passa a usar \*\*Ingress (`networking.k8s.io/v1`) com `ingressClassName: kong`\*\*, sem criar IngressRoute direto para os serviços.



\* \*\*M00-3 – FinOps (tenant-id)\*\*



&nbsp; \* v0 usava apenas `workspace-id`; sem `appgear.io/tenant-id` não há rastreio de custo por cliente;

&nbsp; \* v0.1 define explicitamente:



&nbsp;   \* CDEs/Builder/Multiplayer: `appgear.io/tenant-id: <tenant\_id>`;

&nbsp;   \* Airbyte compartilhado: `appgear.io/tenant-id: global`.



3\. \*\*Alinhamento com M02 (Rede) e M05 (Segurança)\*\*



&nbsp;  \* M02 define a cadeia de borda e que \*\*Kong é o API Gateway oficial\*\*;

&nbsp;  \* M05 define Vault e políticas OPA; CDEs usam apenas segredos injetados de Vault, auditáveis.



4\. \*\*Interoperabilidade com M13 (Workspaces)\*\*



&nbsp;  \* M09 define os \*\*templates dos recursos\*\* que rodam dentro de `ws-<workspace\_id>-factory`;

&nbsp;  \* M13 usará esses templates para instanciar dinamicamente ambientes por cliente/tenant;

&nbsp;  \* por isso as labels (`appgear.io/tenant-id`, `workspace-id`, `suite`, `tier`) são críticas para M13/FinOps.



5\. \*\*Decisão de Airbyte Compartilhado – Limitações\*\*



&nbsp;  \* v0 usa Airbyte \*\*multi-tenant lógico\*\* (um por ambiente) pela economia de recursos;

&nbsp;  \* isso implica:



&nbsp;    \* isolamento lógico (não físico);

&nbsp;    \* necessidade de rigor em credenciais, DBs e RBAC internos ao Airbyte;

&nbsp;  \* essas limitações são documentadas aqui e deverão ser endereçadas em versões futuras (ex.: Airbyte por tenant crítico).



---



\## 3. Pré-requisitos



\### 3.1 Contratuais / Governança



\* \*\*0 - Contrato v0\*\* já aprovado;

\* Módulos 0 a 8 especificados e aplicados:



&nbsp; \* M0 – Convenções, Repositórios, Labels (`appgear.io/\*`);

&nbsp; \* M1 – Argo CD / App-of-Apps;

&nbsp; \* M2 – Rede e Borda (Traefik, Coraza, Kong, Istio);

&nbsp; \* M3 – Observabilidade/FinOps (Prometheus, Grafana, Loki, OpenCost, Lago);

&nbsp; \* M4 – Storage e Bancos (Ceph, Postgres, Redis, Qdrant, RabbitMQ, Redpanda);

&nbsp; \* M5 – Segurança/Segredos (Vault, OPA, Falco, OpenFGA);

&nbsp; \* M6 – Identidade/SSO (Keycloak/midPoint);

&nbsp; \* M7 – Portal Backstage;

&nbsp; \* M8 – Serviços de Aplicação (Flowise, N8n, Directus, Appsmith, etc.).



\### 3.2 Infraestrutura – Topologia B



\* Cluster `ag-<regiao>-core-<env>` com:



&nbsp; \* `core-traefik`, `core-coraza`, `core-kong`, `core-istio`;

&nbsp; \* `core-argocd`, `core-keda`;

&nbsp; \* `core-vault`;

&nbsp; \* `core-ceph` com StorageClasses:



&nbsp;   \* `ceph-block` (RWO);

&nbsp;   \* `ceph-filesystem` (RWX);

&nbsp; \* `core-postgres`, `core-redis`, `core-rabbitmq`, `core-redpanda`.



\* vClusters por workspace:



&nbsp; \* `vcl-ws-<workspace\_id>` com namespaces:



&nbsp;   \* `ws-<workspace\_id>-core`;

&nbsp;   \* `ws-<workspace\_id>-factory`.



\* Namespaces globais:



&nbsp; \* `factory-data` (Airbyte compartilhado);

&nbsp; \* `observability`, `security`, `backstage`, `argocd`, `appgear-core`.



\* Vault:



&nbsp; \* `auth/kubernetes` configurado para cluster/vClusters;

&nbsp; \* paths:



&nbsp;   \* `kv/appgear/addon-factory-vscode/config`;

&nbsp;   \* `kv/appgear/addon-factory-tauri/config`;

&nbsp;   \* `database/creds/postgres-role-airbyte`, etc.



\### 3.3 Ferramentas



\* CLI: `git`, `kubectl`, `kustomize`, `argocd`;

\* Repositórios:



&nbsp; \* `webapp-ia-gitops-core`;

&nbsp; \* `webapp-ia-gitops-suites`.



\### 3.4 Topologia A



\* Host Ubuntu LTS com Docker + docker-compose;

\* Estrutura `/opt/webapp-ia` criada:



&nbsp; \* `.env`;

&nbsp; \* `docker-compose.yml`;

&nbsp; \* `config/`, `data/`, `logs/`.



---



\## 4. Como fazer (comandos)



\### 4.1 Estrutura GitOps da Suíte Factory



No repo `webapp-ia-gitops-suites`:



```bash

cd webapp-ia-gitops-suites



mkdir -p apps/factory/{vscode,airbyte,tauri,multiplayer}

```



`apps/factory/kustomization.yaml`:



```bash

cat > apps/factory/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - vscode/

&nbsp; - airbyte/

&nbsp; - tauri/

&nbsp; - multiplayer/

EOF

```



Adicionar a Application da Suíte Factory no cluster (ex.: `ag-br-core-dev`):



```bash

cat >> clusters/ag-br-core-dev/apps-suites.yaml << 'EOF'

---

apiVersion: argoproj.io/v1alpha1

kind: Application

metadata:

&nbsp; name: suite-factory

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; project: default

&nbsp; source:

&nbsp;   repoURL: https://git.example.com/webapp-ia-gitops-suites.git

&nbsp;   targetRevision: main

&nbsp;   path: apps/factory

&nbsp; destination:

&nbsp;   server: https://kubernetes.default.svc

&nbsp;   namespace: argocd

&nbsp; syncPolicy:

&nbsp;   automated:

&nbsp;     prune: true

&nbsp;     selfHeal: true

EOF

```



---



\### 4.2 CDE – VS Code Server por workspace (addon-factory-vscode)



\#### 4.2.1 Kustomization



```bash

cat > apps/factory/vscode/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



\# Substituído por overlay/template (M13)

namespace: ws-<workspace\_id>-factory



resources:

&nbsp; - pvc-workspace.yaml

&nbsp; - deployment-vscode.yaml

&nbsp; - service-vscode.yaml

&nbsp; - ingress-vscode-kong.yaml

&nbsp; - scaledobject-vscode.yaml

EOF

```



\#### 4.2.2 PVC – Ceph Filesystem (RWX)



```bash

cat > apps/factory/vscode/pvc-workspace.yaml << 'EOF'

apiVersion: v1

kind: PersistentVolumeClaim

metadata:

&nbsp; name: cde-workspace

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-vscode

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp;   appgear.io/backup-enabled: "true"

&nbsp;   appgear.io/backup-profile: "factory-cde"

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; accessModes:

&nbsp;   - ReadWriteMany

&nbsp; storageClassName: ceph-filesystem

&nbsp; resources:

&nbsp;   requests:

&nbsp;     storage: 20Gi

EOF

```



> Corrige o risco do `emptyDir`: o workspace do desenvolvedor persiste entre kills do pod pelo KEDA.



\#### 4.2.3 Deployment – VS Code Server



```bash

cat > apps/factory/vscode/deployment-vscode.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-factory-vscode

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-vscode

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   sidecar.istio.io/inject: "true"

&nbsp;   vault.hashicorp.com/agent-inject: "true"

&nbsp;   vault.hashicorp.com/role: "ws-<workspace\_id>-factory"

&nbsp;   vault.hashicorp.com/agent-inject-secret-cde-config: "kv/data/appgear/addon-factory-vscode/config"

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-factory-vscode

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-factory-vscode

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: factory

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: <workspace\_id>

&nbsp;       appgear.io/tenant-id: <tenant\_id>

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;       vault.hashicorp.com/agent-inject: "true"

&nbsp;       vault.hashicorp.com/role: "ws-<workspace\_id>-factory"

&nbsp;       vault.hashicorp.com/agent-inject-secret-cde-config: "kv/data/appgear/addon-factory-vscode/config"

&nbsp;   spec:

&nbsp;     serviceAccountName: core-services

&nbsp;     containers:

&nbsp;       - name: code-server

&nbsp;         image: codercom/code-server:latest

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 8080

&nbsp;         env:

&nbsp;           - name: WORKSPACE\_ID

&nbsp;             value: "<workspace\_id>"

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "250m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "4Gi"

&nbsp;         volumeMounts:

&nbsp;           - name: workspace

&nbsp;             mountPath: /home/coder/project

&nbsp;     volumes:

&nbsp;       - name: workspace

&nbsp;         persistentVolumeClaim:

&nbsp;           claimName: cde-workspace

EOF

```



\#### 4.2.4 Service



```bash

cat > apps/factory/vscode/service-vscode.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-factory-vscode

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-vscode

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-factory-vscode

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 80

&nbsp;     targetPort: http

EOF

```



\#### 4.2.5 Ingress – Kong (`ingressClassName: kong`, rota `/vscode`)



```bash

cat > apps/factory/vscode/ingress-vscode-kong.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: addon-factory-vscode

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-vscode

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   konghq.com/strip-path: "true"

&nbsp;   konghq.com/protocols: "http,https"

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: factory.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /vscode

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: addon-factory-vscode

&nbsp;               port:

&nbsp;                 number: 80

EOF

```



> Aqui o tráfego externo segue a cadeia definida: Traefik → Coraza → Kong → VS Code (sem IngressRoute de Traefik direto no workspace).



\#### 4.2.6 KEDA ScaledObject



```bash

cat > apps/factory/vscode/scaledobject-vscode.yaml << 'EOF'

apiVersion: keda.sh/v1alpha1

kind: ScaledObject

metadata:

&nbsp; name: addon-factory-vscode

&nbsp; namespace: ws-<workspace\_id>-factory

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-vscode

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; scaleTargetRef:

&nbsp;   kind: Deployment

&nbsp;   name: addon-factory-vscode

&nbsp; minReplicaCount: 0

&nbsp; maxReplicaCount: 3

&nbsp; cooldownPeriod: 300

&nbsp; pollingInterval: 60

&nbsp; triggers:

&nbsp;   - type: prometheus

&nbsp;     metadata:

&nbsp;       serverAddress: http://core-prometheus.observability.svc.cluster.local:9090

&nbsp;       metricName: addon\_factory\_vscode\_active\_sessions

&nbsp;       threshold: "1"

&nbsp;       query: |

&nbsp;         sum(addon\_factory\_vscode\_active\_sessions{workspace\_id="<workspace\_id>"})

EOF

```



---



\### 4.3 Airbyte – Instância Compartilhada (factory-data) com limits



\#### 4.3.1 Application (Helm) – Argo CD



```bash

cat > apps/factory/airbyte/application-airbyte.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: Application

metadata:

&nbsp; name: addon-factory-airbyte

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-airbyte

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; project: default

&nbsp; source:

&nbsp;   repoURL: https://airbytehq.github.io/helm-charts

&nbsp;   chart: airbyte

&nbsp;   targetRevision: 0.52.0

&nbsp;   helm:

&nbsp;     values: |

&nbsp;       global:

&nbsp;         edition: "oss"

&nbsp;       webapp:

&nbsp;         service:

&nbsp;           type: ClusterIP

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

&nbsp;       server:

&nbsp;         service:

&nbsp;           type: ClusterIP

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "500m"

&nbsp;             memory: "1Gi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "2Gi"

&nbsp;       worker:

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "500m"

&nbsp;             memory: "1Gi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "2Gi"

&nbsp;       scheduler:

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

&nbsp;       database:

&nbsp;         external:

&nbsp;           enabled: true

&nbsp;           host: core-postgres.appgear-core.svc.cluster.local

&nbsp;           port: 5432

&nbsp;           database: airbyte\_factory

&nbsp;           userFromSecret:

&nbsp;             name: addon-factory-airbyte-db

&nbsp;             key: username

&nbsp;           passwordFromSecret:

&nbsp;             name: addon-factory-airbyte-db

&nbsp;             key: password

&nbsp; destination:

&nbsp;   server: https://kubernetes.default.svc

&nbsp;   namespace: factory-data

&nbsp; syncPolicy:

&nbsp;   automated:

&nbsp;     prune: true

&nbsp;     selfHeal: true

EOF

```



`apps/factory/airbyte/kustomization.yaml`:



```bash

cat > apps/factory/airbyte/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - application-airbyte.yaml

&nbsp; - scaledobject-airbyte-workers.yaml

&nbsp; - ingress-airbyte-kong.yaml

EOF

```



\#### 4.3.2 KEDA ScaledObject – workers



```bash

cat > apps/factory/airbyte/scaledobject-airbyte-workers.yaml << 'EOF'

apiVersion: keda.sh/v1alpha1

kind: ScaledObject

metadata:

&nbsp; name: addon-factory-airbyte-workers

&nbsp; namespace: factory-data

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-airbyte

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; scaleTargetRef:

&nbsp;   kind: Deployment

&nbsp;   name: airbyte-worker

&nbsp; minReplicaCount: 0

&nbsp; maxReplicaCount: 10

&nbsp; cooldownPeriod: 300

&nbsp; pollingInterval: 30

&nbsp; triggers:

&nbsp;   - type: prometheus

&nbsp;     metadata:

&nbsp;       serverAddress: http://core-prometheus.observability.svc.cluster.local:9090

&nbsp;       metricName: airbyte\_pending\_jobs

&nbsp;       threshold: "1"

&nbsp;       query: |

&nbsp;         sum(airbyte\_pending\_jobs)

EOF

```



\#### 4.3.3 Ingress – Airbyte UI via Kong



```bash

cat > apps/factory/airbyte/ingress-airbyte-kong.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: addon-factory-airbyte

&nbsp; namespace: factory-data

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-airbyte

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   konghq.com/strip-path: "true"

&nbsp;   konghq.com/protocols: "http,https"

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: factory.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /airbyte

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: airbyte-webapp

&nbsp;               port:

&nbsp;                 number: 80

EOF

```



> Limitações de isolamento: a instância é única (`tenant-id: global`); isolamento entre tenants ocorre em nível de credencial/conexão/tabelas. Este fato deve constar no runbook de segurança/FinOps.



---



\### 4.4 Build Nativo – Serviço de Builder (addon-factory-tauri-builder)



\#### 4.4.1 Kustomization



```bash

cat > apps/factory/tauri/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: ws-<workspace\_id>-factory



resources:

&nbsp; - deployment-builder.yaml

&nbsp; - service-builder.yaml

&nbsp; - scaledobject-builder.yaml

EOF

```



\#### 4.4.2 Deployment



```bash

cat > apps/factory/tauri/deployment-builder.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-factory-tauri-builder

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-tauri-builder

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   sidecar.istio.io/inject: "true"

&nbsp;   vault.hashicorp.com/agent-inject: "true"

&nbsp;   vault.hashicorp.com/role: "ws-<workspace\_id>-factory"

&nbsp;   vault.hashicorp.com/agent-inject-secret-builder-config: "kv/data/appgear/addon-factory-tauri/config"

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-factory-tauri-builder

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-factory-tauri-builder

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: factory

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: <workspace\_id>

&nbsp;       appgear.io/tenant-id: <tenant\_id>

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;       vault.hashicorp.com/agent-inject: "true"

&nbsp;       vault.hashicorp.com/role: "ws-<workspace\_id>-factory"

&nbsp;       vault.hashicorp.com/agent-inject-secret-builder-config: "kv/data/appgear/addon-factory-tauri/config"

&nbsp;   spec:

&nbsp;     serviceAccountName: core-services

&nbsp;     containers:

&nbsp;       - name: builder-api

&nbsp;         image: appgear/tauri-reactnative-builder:latest

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 8080

&nbsp;         env:

&nbsp;           - name: BUILDER\_WORKSPACE\_ID

&nbsp;             value: "<workspace\_id>"

&nbsp;           - name: S3\_ENDPOINT

&nbsp;             value: "http://ceph-rgw.appgear-core.svc.cluster.local"

&nbsp;           - name: S3\_BUCKET

&nbsp;             value: "factory-artifacts"

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "500m"

&nbsp;             memory: "1Gi"

&nbsp;           limits:

&nbsp;             cpu: "4"

&nbsp;             memory: "8Gi"

EOF

```



\#### 4.4.3 Service



```bash

cat > apps/factory/tauri/service-builder.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-factory-tauri-builder

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-tauri-builder

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-factory-tauri-builder

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 80

&nbsp;     targetPort: http

EOF

```



\#### 4.4.4 KEDA ScaledObject



```bash

cat > apps/factory/tauri/scaledobject-builder.yaml << 'EOF'

apiVersion: keda.sh/v1alpha1

kind: ScaledObject

metadata:

&nbsp; name: addon-factory-tauri-builder

&nbsp; namespace: ws-<workspace\_id>-factory

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-tauri-builder

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; scaleTargetRef:

&nbsp;   kind: Deployment

&nbsp;   name: addon-factory-tauri-builder

&nbsp; minReplicaCount: 0

&nbsp; maxReplicaCount: 5

&nbsp; cooldownPeriod: 600

&nbsp; pollingInterval: 60

&nbsp; triggers:

&nbsp;   - type: prometheus

&nbsp;     metadata:

&nbsp;       serverAddress: http://core-prometheus.observability.svc.cluster.local:9090

&nbsp;       metricName: builder\_pending\_jobs

&nbsp;       threshold: "1"

&nbsp;       query: |

&nbsp;         sum(builder\_pending\_jobs{workspace\_id="<workspace\_id>"})

EOF

```



---



\### 4.5 Multiplayer – Gateway WebSocket (addon-factory-multiplayer)



\#### 4.5.1 Kustomization



```bash

cat > apps/factory/multiplayer/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: ws-<workspace\_id>-factory



resources:

&nbsp; - deployment-multiplayer.yaml

&nbsp; - service-multiplayer.yaml

&nbsp; - ingress-multiplayer-kong.yaml

&nbsp; - scaledobject-multiplayer.yaml

EOF

```



\#### 4.5.2 Deployment



```bash

cat > apps/factory/multiplayer/deployment-multiplayer.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-factory-multiplayer

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-multiplayer

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   sidecar.istio.io/inject: "true"

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-factory-multiplayer

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-factory-multiplayer

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: factory

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: <workspace\_id>

&nbsp;       appgear.io/tenant-id: <tenant\_id>

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;   spec:

&nbsp;     serviceAccountName: core-services

&nbsp;     containers:

&nbsp;       - name: multiplayer

&nbsp;         image: appgear/multiplayer-gateway:latest

&nbsp;         ports:

&nbsp;           - name: ws

&nbsp;             containerPort: 8080

&nbsp;         env:

&nbsp;           - name: WORKSPACE\_ID

&nbsp;             value: "<workspace\_id>"

&nbsp;           - name: REDIS\_HOST

&nbsp;             value: core-redis.appgear-core.svc.cluster.local

&nbsp;           - name: REDPANDA\_BROKER

&nbsp;             value: core-redpanda.appgear-core.svc.cluster.local:9092

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "250m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "4Gi"

EOF

```



\#### 4.5.3 Service



```bash

cat > apps/factory/multiplayer/service-multiplayer.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-factory-multiplayer

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-multiplayer

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-factory-multiplayer

&nbsp; ports:

&nbsp;   - name: ws

&nbsp;     port: 80

&nbsp;     targetPort: ws

EOF

```



\#### 4.5.4 Ingress – WebSocket via Kong



```bash

cat > apps/factory/multiplayer/ingress-multiplayer-kong.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: addon-factory-multiplayer

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-multiplayer

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   konghq.com/strip-path: "true"

&nbsp;   konghq.com/protocols: "http,https"

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: factory.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /multiplayer

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: addon-factory-multiplayer

&nbsp;               port:

&nbsp;                 number: 80

EOF

```



\#### 4.5.5 KEDA ScaledObject



```bash

cat > apps/factory/multiplayer/scaledobject-multiplayer.yaml << 'EOF'

apiVersion: keda.sh/v1alpha1

kind: ScaledObject

metadata:

&nbsp; name: addon-factory-multiplayer

&nbsp; namespace: ws-<workspace\_id>-factory

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-factory-multiplayer

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: factory

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: <workspace\_id>

&nbsp;   appgear.io/tenant-id: <tenant\_id>

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod9-suite-factory"

spec:

&nbsp; scaleTargetRef:

&nbsp;   kind: Deployment

&nbsp;   name: addon-factory-multiplayer

&nbsp; minReplicaCount: 0

&nbsp; maxReplicaCount: 5

&nbsp; cooldownPeriod: 300

&nbsp; pollingInterval: 30

&nbsp; triggers:

&nbsp;   - type: prometheus

&nbsp;     metadata:

&nbsp;       serverAddress: http://core-prometheus.observability.svc.cluster.local:9090

&nbsp;       metricName: multiplayer\_active\_sessions

&nbsp;       threshold: "1"

&nbsp;       query: |

&nbsp;         sum(multiplayer\_active\_sessions{workspace\_id="<workspace\_id>"})

EOF

```



---



\### 4.6 Topologia A – CDE mínimo em Docker



No host:



```bash

sudo mkdir -p /opt/webapp-ia/config/cde

cd /opt/webapp-ia

```



No `.env`:



```env

FACTORY\_VSCODE\_PORT=8443

```



Trecho de `docker-compose.yml`:



```yaml

services:

&nbsp; core-traefik:

&nbsp;   image: traefik:v3.0

&nbsp;   command:

&nbsp;     - "--providers.docker=true"

&nbsp;     - "--entrypoints.websecure.address=:443"

&nbsp;   ports:

&nbsp;     - "443:443"

&nbsp;   volumes:

&nbsp;     - /var/run/docker.sock:/var/run/docker.sock:ro



&nbsp; addon-factory-vscode:

&nbsp;   image: codercom/code-server:latest

&nbsp;   container\_name: addon-factory-vscode

&nbsp;   environment:

&nbsp;     - DOCKER\_USER=coder

&nbsp;   volumes:

&nbsp;     - ./config/cde:/home/coder/project

&nbsp;   labels:

&nbsp;     - "traefik.enable=true"

&nbsp;     - "traefik.http.routers.factory-vscode.rule=PathPrefix(`/vscode`)"

&nbsp;     - "traefik.http.routers.factory-vscode.entrypoints=websecure"

&nbsp;     - "traefik.http.services.factory-vscode.loadbalancer.server.port=8080"

```



> Airbyte/Builder/Multiplayer permanecem apenas na Topologia B.



---



\## 5. Como verificar



1\. \*\*Estrutura GitOps\*\*



&nbsp;  ```bash

&nbsp;  cd webapp-ia-gitops-suites

&nbsp;  tree apps/factory

&nbsp;  ```



&nbsp;  Esperado: diretórios `vscode`, `airbyte`, `tauri`, `multiplayer` com os YAMLs descritos.



2\. \*\*Argo CD – Suíte Factory\*\*



&nbsp;  ```bash

&nbsp;  argocd app list | grep suite-factory

&nbsp;  argocd app get suite-factory

&nbsp;  ```



&nbsp;  Deve estar `Healthy` e `Synced`.



3\. \*\*Namespaces / objetos por workspace\*\*



&nbsp;  ```bash

&nbsp;  kubectl get ns | grep ws-<workspace\_id>-factory



&nbsp;  kubectl get deploy,svc,ingress,scaledobject,pvc \\

&nbsp;    -n ws-<workspace\_id>-factory

&nbsp;  ```



&nbsp;  Verificar:



&nbsp;  \* `addon-factory-vscode`, `addon-factory-tauri-builder`, `addon-factory-multiplayer`;

&nbsp;  \* `cde-workspace` (PVC) `Bound`.



4\. \*\*Labels FinOps (`tenant-id`)\*\*



&nbsp;  ```bash

&nbsp;  kubectl get deploy addon-factory-vscode \\

&nbsp;    -n ws-<workspace\_id>-factory -o jsonpath='{.metadata.labels}'

&nbsp;  ```



&nbsp;  Verificar presença de `appgear.io/tenant-id: <tenant\_id>`.



&nbsp;  Para Airbyte:



&nbsp;  ```bash

&nbsp;  kubectl get deploy -n factory-data | grep airbyte

&nbsp;  kubectl get deploy airbyte-server -n factory-data -o jsonpath='{.metadata.labels}'

&nbsp;  ```



&nbsp;  Esperado: `appgear.io/tenant-id: global`.



5\. \*\*Ingress com Kong\*\*



&nbsp;  ```bash

&nbsp;  kubectl get ingress -A | grep kong

&nbsp;  ```



&nbsp;  Validar que:



&nbsp;  \* CDE/Multiplayer têm `ingressClassName: kong` em `ws-<workspace\_id>-factory`;

&nbsp;  \* Airbyte tem `ingressClassName: kong` em `factory-data`.



6\. \*\*KEDA – Scale-to-Zero\*\*



&nbsp;  CDE:



&nbsp;  ```bash

&nbsp;  kubectl get scaledobject addon-factory-vscode -n ws-<workspace\_id>-factory -o yaml | yq '.spec'

&nbsp;  kubectl get deploy addon-factory-vscode -n ws-<workspace\_id>-factory -w

&nbsp;  ```



&nbsp;  Em idle: `replicas: 0`; sob carga: escala.



&nbsp;  Airbyte workers e Multiplayer de forma análoga.



7\. \*\*Rotas externas (cadeia completa)\*\*



&nbsp;  Depois de apontar DNS/hosts para o Traefik da borda:



&nbsp;  ```bash

&nbsp;  curl -k https://factory.dev.appgear.local/vscode -I

&nbsp;  curl -k https://factory.dev.appgear.local/airbyte -I

&nbsp;  curl -k https://factory.dev.appgear.local/multiplayer -I

&nbsp;  ```



&nbsp;  \* Esperado: redirecionamento/autenticação via SSO (Kong/Keycloak) e, após login, `200`.



---



\## 6. Erros comuns



1\. \*\*Expor VS Code/Airbyte via IngressRoute (Traefik) – Bypass da cadeia\*\*



&nbsp;  \* Efeito: tráfego pula Coraza/Kong, violando M02 e abrindo vetor crítico em CDE.

&nbsp;  \* Correção: usar somente `Ingress` com `ingressClassName: kong` definidas aqui; a configuração de Traefik/Coraza é responsabilidade do Módulo 02.



2\. \*\*Falta de `appgear.io/tenant-id`\*\*



&nbsp;  \* Efeito: custos dos CDEs/Airbyte não são atribuíveis por tenant; M13/FinOps não funcionam.

&nbsp;  \* Correção: garantir `appgear.io/tenant-id` em TODOS os recursos deste módulo (inclusive pods), com:



&nbsp;    \* `<tenant\_id>` para workspaces;

&nbsp;    \* `global` para Airbyte.



3\. \*\*Uso de `emptyDir` em CDEs\*\*



&nbsp;  \* Efeito: perda de código não commitado quando o KEDA escala para zero.

&nbsp;  \* Correção: sempre PVC com `storageClassName: ceph-filesystem` (RWX).



4\. \*\*Airbyte sem `resources.limits` e sem KEDA\*\*



&nbsp;  \* Efeito: consumo descontrolado de memória/CPU, especialmente em clusters com muitos jobs.

&nbsp;  \* Correção: configurar `resources` no Helm e KEDA apenas para `airbyte-worker`.



5\. \*\*Ingress do Multiplayer sem suporte WebSocket no Kong\*\*



&nbsp;  \* Efeito: timeouts e falha de upgrade.

&nbsp;  \* Correção: usar protocolos `http,https` e garantir que a configuração global do Kong permita WebSocket (camada de M02).



6\. \*\*Ignorar validação OPA (M05)\*\*



&nbsp;  \* Efeito: CDEs podem quebrar políticas de segurança (imagens, capabilities, etc.).

&nbsp;  \* Correção: validar os Deployments deste módulo contra as políticas OPA definidas em M05 antes de aplicar em produção.



7\. \*\*Misturar artefatos Core e Suíte Factory no mesmo repo\*\*



&nbsp;  \* Efeito: confusão de responsabilidade e risco de rollback errado.

&nbsp;  \* Correção: manter este módulo apenas em `webapp-ia-gitops-suites` na pasta `apps/factory`.



---



\## 7. Onde salvar



1\. \*\*Documento de desenvolvimento (Markdown)\*\*



&nbsp;  \* Este texto completo deve ser salvo como:



&nbsp;    \* `Módulo 09 v0.1.md`



&nbsp;  \* E referenciado dentro de:



&nbsp;    \* `appgear-contracts/1 - Desenvolvimento v0.md`



&nbsp;      \* seção: \*\*“Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer) – v0.1”\*\*.



2\. \*\*Repositório GitOps – Suítes\*\*



&nbsp;  No repo `webapp-ia-gitops-suites`:



&nbsp;  \* `apps/factory/kustomization.yaml`;

&nbsp;  \* `apps/factory/vscode/\*.yaml`;

&nbsp;  \* `apps/factory/airbyte/\*.yaml`;

&nbsp;  \* `apps/factory/tauri/\*.yaml`;

&nbsp;  \* `apps/factory/multiplayer/\*.yaml`;

&nbsp;  \* `clusters/<cluster>/apps-suites.yaml` com a `Application` `suite-factory`.



3\. \*\*Topologia A (Docker)\*\*



&nbsp;  No host de desenvolvimento/legado:



&nbsp;  \* `/opt/webapp-ia/.env`;

&nbsp;  \* `/opt/webapp-ia/docker-compose.yml`;

&nbsp;  \* `/opt/webapp-ia/config/cde/`.



Com estes ajustes, o \*\*Módulo 09 – Suíte Factory v0.1\*\* atende às correções do diagnóstico: está em formato Markdown, não faz bypass da cadeia Traefik → Coraza → Kong, inclui `appgear.io/tenant-id` para FinOps e preserva o design aprovado para CDEs (Ceph Filesystem) e Airbyte compartilhado.



