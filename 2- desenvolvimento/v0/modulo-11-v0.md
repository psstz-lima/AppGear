Vou te devolver o \*\*Módulo 11 v0.1 (Retrofit)\*\* já corrigido conforme o diagnóstico profundo que você mandou, fechando explicitamente:



\* Forma canônica (Markdown, não mais `.py`).

\* Borda IoT (MQTT/CoAP) com \*\*TCP/UDP dedicados\*\*, fora do WAF HTTP.

\* Conectividade KubeEdge (CloudCore) via \*\*Service LoadBalancer com VIP\*\*.

\* Labels de FinOps, incluindo \*\*`appgear.io/tenant-id`\*\*.

\* `resources` robustos para ThingsBoard, CloudCore e RPA.

\* Mapeamento \*\*tenant ↔ workspace ↔ devices\*\* (interoperabilidade com M13).



Você pode usar o texto abaixo como `Módulo 11 v0.1.md`.



---



\# Módulo 11 – Suíte Operations (IoT, Digital Twins, RPA, KubeEdge) – v0.1 (Retrofit)



Suíte 3 – AppGear Operations (Digital Twins \& Geo-Ops, Real-Time Action Center, RPA, Edge)



> Este artefato substitui o antigo `Módulo 11 v0.py` e atende às não conformidades encontradas no diagnóstico (G15, G05, M00-3).



---



\## 1. O que é



A \*\*Suíte Operations\*\* é a suíte responsável por conectar o mundo físico e os processos operacionais da organização ao ecossistema da plataforma, com quatro pilares:



1\. \*\*IoT \& Digital Twins / Geo-Ops\*\*



&nbsp;  \* Plataforma IoT e gêmeos digitais baseada em:



&nbsp;    \* \*\*ThingsBoard\*\* para telemetria, devices, assets e dashboards.

&nbsp;    \* \*\*Postgres + PostGIS\*\* (Módulo 4) como storage geoespacial e metadados.

&nbsp;  \* Oferece:



&nbsp;    \* Gestão de dispositivos, ativos, tenants e regras.

&nbsp;    \* Geo-Ops (visualização e ações por mapa, regiões, rotas).



2\. \*\*Real-Time Action Center (Eventos / Streaming)\*\*



&nbsp;  \* Serviço `addon-ops-action-center` que:



&nbsp;    \* Consome eventos de telemetria de \*\*Redpanda\*\* (M4).

&nbsp;    \* Aplica regras de decisão (integrando com N8n/BPMN e Brain).

&nbsp;    \* Dispara ações (RPA, webhooks, APIs, notificações).



3\. \*\*RPA (Robocorp)\*\*



&nbsp;  \* `addon-ops-robocorp` para robôs que operam sobre sistemas sem API.

&nbsp;  \* Jobs de RPA chegam por fila/stream (`ops.rpa.jobs` em Redpanda).

&nbsp;  \* Workers escalam de \*\*0 a N\*\* via \*\*KEDA\*\*, controlando custo.



4\. \*\*Edge / KubeEdge\*\*



&nbsp;  \* `addon-ops-kubeedge-cloudcore` no cluster central.

&nbsp;  \* `edgecore` em nós remotos (sites físicos).

&nbsp;  \* Permite rodar workloads (IoT/RPA) próximos dos dispositivos, com:



&nbsp;    \* Controle centralizado (GitOps, SSO, Observabilidade).

&nbsp;    \* Execução distribuída no Edge.



A Suíte Operations opera em:



\* \*\*Topologia B (produção)\*\*

&nbsp; Kubernetes, GitOps, namespaces dedicados:



&nbsp; \* `ops-iot` (ThingsBoard + Action Center).

&nbsp; \* `ops-rpa` (runners RPA).

&nbsp; \* `ops-edge` (KubeEdge / cloudcore).

&nbsp; \* `ws-<workspace\_id>-ops` (recursos por workspace).



\* \*\*Topologia A (dev/demo)\*\*

&nbsp; Compose mínimo com Traefik + Postgres+PostGIS + ThingsBoard, para demonstrações locais, \*\*não recomendado\*\* para produção.



---



\## 2. Por que



1\. \*\*Endereçar as não conformidades do diagnóstico\*\*



&nbsp;  \* \*\*G15 / Forma Canônica:\*\*

&nbsp;    Saída em \*\*Markdown\*\* (`Módulo 11 v0.1.md`), não mais script `.py`.

&nbsp;  \* \*\*G05 / Segurança de Borda IoT:\*\*

&nbsp;    Entrada de \*\*MQTT/CoAP\*\* e \*\*CloudCore\*\* explicitada como:



&nbsp;    \* \*\*Borda TCP/UDP dedicada\*\*, fora do WAF HTTP.

&nbsp;    \* Com \*\*mTLS/autenticação\*\* forte, firewall e IP/VIP controlado.

&nbsp;  \* \*\*M00-3 / FinOps:\*\*

&nbsp;    Inclusão de `appgear.io/tenant-id` em todos os recursos, permitindo:



&nbsp;    \* Rastreamento de custo por tenant.

&nbsp;    \* Rate limiting e políticas de cobrança.

&nbsp;  \* \*\*M00-3 / Resources:\*\*

&nbsp;    Definição de `resources` para componentes pesados (ThingsBoard, CloudCore, RPA), evitando “roubar” recursos do Core.



2\. \*\*Cadeia de rede coerente com o Módulo 2\*\*



&nbsp;  \* HTTP (UIs e APIs de gestão):



&nbsp;    \* Continua passando pela cadeia \*\*Traefik → Coraza → Kong → Istio\*\*.

&nbsp;  \* Protocolos binários / não HTTP (MQTT, CoAP, CloudCore WS):



&nbsp;    \* Entram via \*\*borda TCP/UDP dedicada\*\*, documentada como exceção:



&nbsp;      \* Não faz sentido WAF HTTP em MQTT/CoAP.

&nbsp;      \* Proteção vem de mTLS, firewall e limitação de origem.



3\. \*\*FinOps em ambientes de alto volume de dados\*\*



&nbsp;  \* IoT gera grande volume de telemetria (séries temporais).

&nbsp;  \* Sem `tenant-id` em pods, PVCs, topics e bancos:



&nbsp;    \* Não há como refaturar por cliente.

&nbsp;  \* Este módulo passa a:



&nbsp;    \* Rotular recursos com `appgear.io/tenant-id`.

&nbsp;    \* Alinhar ThingsBoard (tenant interno) com `workspace-id` e `tenant-id` da AppGear.



4\. \*\*Interoperabilidade com M04 (Dados) e M13 (Workspaces)\*\*



&nbsp;  \* \*\*M04:\*\*

&nbsp;    Usa \*\*Postgres Core com PostGIS\*\*;

&nbsp;    Cassandra/Timescale podem ser plugados depois (v1) se custo de telemetria exigir.

&nbsp;  \* \*\*M13:\*\*

&nbsp;    Cada \*\*workspace\*\* representa um cliente ou subdomínio;

&nbsp;    Devices de IoT em ThingsBoard estão vinculados a:



&nbsp;    \* `workspace-id` (AppGear) ↔ tenant interno do ThingsBoard ↔ `tenant-id`.



5\. \*\*Edge como extensão controlada da plataforma\*\*



&nbsp;  \* Workloads de IoT e RPA podem ser deslocados para sites remotos via KubeEdge:



&nbsp;    \* Reduz latência.

&nbsp;    \* Evita tráfego desnecessário até o cluster central.

&nbsp;  \* Ao mesmo tempo, mantém governança:



&nbsp;    \* Config declarativa (GitOps).

&nbsp;    \* SSO/Segurança central.

&nbsp;    \* Observabilidade e FinOps.



---



\## 3. Pré-requisitos



\### 3.1 Contratuais / Organizacionais



\* \*\*0 - Contrato v0\*\* como fonte de verdade.

\* Padrões do Módulo 00:



&nbsp; \* Nomes: `core-\*` (Core), `addon-\*` (Suítes).

&nbsp; \* Labels/annotations `appgear.io/\*`.

&nbsp; \* `.env` central para segredos sensíveis (Topologia A).

\* Módulos anteriores implementados (Core completo):



&nbsp; \* M1 (GitOps/Argo CD), M2 (Rede e Borda), M3 (Observabilidade/FinOps),

&nbsp;   M4 (Storage/Bancos), M5 (Segurança/Segredos), M6 (Identidade/SSO),

&nbsp;   M7 (Backstage), M8 (Serviços Core), M9 (Factory), M10 (Brain).



\### 3.2 Infra – Topologia B



\* Cluster Kubernetes `ag-<regiao>-core-<env>` com:



&nbsp; \* Malha: Traefik, Coraza, Kong, Istio.

&nbsp; \* Core DBs (Postgres, Redis, Qdrant, Redpanda, RabbitMQ, Ceph).

&nbsp; \* Observabilidade (Prometheus, Grafana, Loki).

&nbsp; \* FinOps (OpenCost, Lago).

&nbsp; \* KEDA ativo (para autoscaling baseado em eventos).



\* Capacidade para novos namespaces:



&nbsp; \* `ops-iot`, `ops-rpa`, `ops-edge`.



\* Regras de firewall / segurança:



&nbsp; \* Permitir conexões:



&nbsp;   \* MQTT/1883 (ou 8883 TLS) para devices.

&nbsp;   \* CoAP/5683 (UDP) se usado.

&nbsp;   \* CloudCore/10000–10001 para nós Edge.



\### 3.3 Ferramentas



\* `git`, `kubectl`, `kustomize`, `argocd`, `yq`, `helm`, `keadm`.

\* Acesso aos repositórios:



&nbsp; \* `webapp-ia-gitops-core`

&nbsp; \* `webapp-ia-gitops-suites`

&nbsp; \* Repositórios de serviços `appgear/ops-\*`.



\### 3.4 Topologia A (dev/demo)



\* Host Ubuntu LTS com Docker + docker-compose.

\* Traefik como reverse proxy.

\* Postgres+PostGIS.

\* ThingsBoard em container.



---



\## 4. Como fazer (comandos)



\### 4.1 Estrutura GitOps da Suíte Operations



```bash

cd webapp-ia-gitops-suites



mkdir -p apps/operations

mkdir -p apps/operations/thingsboard

mkdir -p apps/operations/rpa-robocorp

mkdir -p apps/operations/kubeedge

```



\#### 4.1.1 Kustomization da suíte



```bash

cat > apps/operations/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - thingsboard

&nbsp; - rpa-robocorp

&nbsp; - kubeedge

EOF

```



\#### 4.1.2 Application Argo CD da suíte



```bash

cat >> clusters/ag-br-core-dev/apps-suites.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: Application

metadata:

&nbsp; name: suite-operations

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: suite-operations

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; project: default

&nbsp; source:

&nbsp;   repoURL: https://git.example.com/webapp-ia-gitops-suites.git

&nbsp;   targetRevision: main

&nbsp;   path: apps/operations

&nbsp; destination:

&nbsp;   server: https://kubernetes.default.svc

&nbsp;   namespace: ops-iot

&nbsp; syncPolicy:

&nbsp;   automated:

&nbsp;     selfHeal: true

&nbsp;     prune: true

&nbsp;   syncOptions:

&nbsp;     - CreateNamespace=true

EOF

```



> Ajustar `repoURL`, cluster e namespace conforme ambiente.



---



\### 4.2 IoT \& Digital Twins – ThingsBoard + Action Center + Borda MQTT/CoAP



\#### 4.2.1 Namespace e kustomization



```bash

cat > apps/operations/thingsboard/namespace.yaml << 'EOF'

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: ops-iot

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: ops-iot

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

EOF

```



```bash

cat > apps/operations/thingsboard/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: ops-iot



resources:

&nbsp; - namespace.yaml

&nbsp; - pvc-thingsboard.yaml

&nbsp; - deployment-thingsboard.yaml

&nbsp; - service-thingsboard-http.yaml

&nbsp; - ingressroute-thingsboard-http.yaml

&nbsp; - service-thingsboard-mqtt.yaml

&nbsp; - ingressroute-tcp-mqtt.yaml

&nbsp; - service-thingsboard-coap.yaml

&nbsp; - lb-coap.yaml

&nbsp; - deployment-action-center.yaml

&nbsp; - service-action-center.yaml

&nbsp; - ingressroute-action-center-http.yaml

EOF

```



\#### 4.2.2 PVC + Deployment ThingsBoard (com resources)



```bash

cat > apps/operations/thingsboard/pvc-thingsboard.yaml << 'EOF'

apiVersion: v1

kind: PersistentVolumeClaim

metadata:

&nbsp; name: pvc-ops-thingsboard-data

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; accessModes:

&nbsp;   - ReadWriteOnce

&nbsp; storageClassName: ceph-block

&nbsp; resources:

&nbsp;   requests:

&nbsp;     storage: 50Gi

EOF

```



```bash

cat > apps/operations/thingsboard/deployment-thingsboard.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-ops-thingsboard

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-ops-thingsboard

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-ops-thingsboard

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: operations

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: thingsboard

&nbsp;         image: thingsboard/tb-postgres:latest

&nbsp;         ports:

&nbsp;           - containerPort: 8080

&nbsp;             name: http

&nbsp;           - containerPort: 1883

&nbsp;             name: mqtt

&nbsp;           - containerPort: 5683

&nbsp;             name: coap

&nbsp;         envFrom:

&nbsp;           - secretRef:

&nbsp;               name: ops-thingsboard-db

&nbsp;         volumeMounts:

&nbsp;           - name: data

&nbsp;             mountPath: /data

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "500m"

&nbsp;             memory: "2Gi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "4Gi"

&nbsp;     volumes:

&nbsp;       - name: data

&nbsp;         persistentVolumeClaim:

&nbsp;           claimName: pvc-ops-thingsboard-data

EOF

```



\#### 4.2.3 HTTP (UI e APIs) – mantém cadeia Traefik → Coraza → Kong → Istio



Service HTTP:



```bash

cat > apps/operations/thingsboard/service-thingsboard-http.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-ops-thingsboard-http

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard-http

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 80

&nbsp;     targetPort: 8080

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard

EOF

```



IngressRoute HTTP (ex.: `/iot`):



```bash

cat > apps/operations/thingsboard/ingressroute-thingsboard-http.yaml << 'EOF'

apiVersion: traefik.containo.us/v1alpha1

kind: IngressRoute

metadata:

&nbsp; name: addon-ops-thingsboard-http

&nbsp; namespace: ops-iot

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard-http

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; entryPoints:

&nbsp;   - websecure

&nbsp; routes:

&nbsp;   - match: PathPrefix(`/iot`)

&nbsp;     kind: Rule

&nbsp;     services:

&nbsp;       - name: addon-ops-thingsboard-http

&nbsp;         port: 80

&nbsp;     middlewares:

&nbsp;       - name: core-traefik-forward-auth-sso

&nbsp;         namespace: appgear-core

EOF

```



> O tráfego HTTP entra pela cadeia padrão WAF/API Gateway. Somente UIs/APIs administrativas.



\#### 4.2.4 MQTT – Borda TCP dedicada (sem WAF HTTP, com mTLS)



Service interno para MQTT:



```bash

cat > apps/operations/thingsboard/service-thingsboard-mqtt.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-ops-thingsboard-mqtt

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard-mqtt

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; ports:

&nbsp;   - name: mqtt

&nbsp;     port: 1883

&nbsp;     targetPort: 1883

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard

EOF

```



IngressRouteTCP MQTT (entrada dedicada em Traefik):



> Requer configuração prévia de `entryPoints.mqtt.address=:1883` no Traefik (Módulo 2).



```bash

cat > apps/operations/thingsboard/ingressroute-tcp-mqtt.yaml << 'EOF'

apiVersion: traefik.containo.us/v1alpha1

kind: IngressRouteTCP

metadata:

&nbsp; name: addon-ops-thingsboard-mqtt

&nbsp; namespace: ops-iot

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard-mqtt

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; entryPoints:

&nbsp;   - mqtt

&nbsp; routes:

&nbsp;   - match: HostSNI(`\*`)

&nbsp;     services:

&nbsp;       - name: addon-ops-thingsboard-mqtt

&nbsp;         port: 1883

&nbsp; tls:

&nbsp;   passthrough: true

EOF

```



Pontos importantes:



\* WAF (Coraza) não é aplicado a esse fluxo (não faz sentido para MQTT).

\* Segurança vem de:



&nbsp; \* \*\*mTLS\*\* (client cert nos devices).

&nbsp; \* Firewall/SG controlando quem pode atingir a porta 1883.

&nbsp; \* Limitação de IPs/origens se necessário.



\#### 4.2.5 CoAP – LB UDP dedicado (se usado)



Service CoAP:



```bash

cat > apps/operations/thingsboard/service-thingsboard-coap.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-ops-thingsboard-coap

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard-coap

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; type: ClusterIP

&nbsp; ports:

&nbsp;   - name: coap

&nbsp;     port: 5683

&nbsp;     targetPort: 5683

&nbsp;     protocol: UDP

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard

EOF

```



Service LoadBalancer UDP (borda CoAP):



```bash

cat > apps/operations/thingsboard/lb-coap.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-ops-thingsboard-coap-lb

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard-coap-lb

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; type: LoadBalancer

&nbsp; externalTrafficPolicy: Local

&nbsp; ports:

&nbsp;   - name: coap

&nbsp;     port: 5683

&nbsp;     targetPort: 5683

&nbsp;     protocol: UDP

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-ops-thingsboard

EOF

```



> O provedor de cloud atribui um IP externo (VIP) a esse LB, que deve ser registrado no DNS e liberado no firewall. Segurança: DTLS/mTLS na aplicação + firewall.



\#### 4.2.6 Action Center (HTTP, integra com Redpanda)



```bash

cat > apps/operations/thingsboard/deployment-action-center.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-ops-action-center

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-action-center

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-ops-action-center

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-ops-action-center

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: operations

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: action-center

&nbsp;         image: appgear/ops-action-center:latest

&nbsp;         ports:

&nbsp;           - containerPort: 8080

&nbsp;             name: http

&nbsp;         env:

&nbsp;           - name: REDPANDA\_BROKERS

&nbsp;             value: core-redpanda.appgear-core.svc.cluster.local:9092

&nbsp;           - name: TELEMETRY\_TOPICS

&nbsp;             value: "iot.telemetry.\*,ops.alerts.\*"

&nbsp;           - name: WORKSPACE\_MAPPING\_STRATEGY

&nbsp;             value: "tenantId=appgear.io/tenant-id"

&nbsp;         envFrom:

&nbsp;           - secretRef:

&nbsp;               name: ops-action-center-secrets

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "250m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

EOF

```



Service + IngressRoute HTTP:



```bash

cat > apps/operations/thingsboard/service-action-center.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-ops-action-center

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-action-center

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 80

&nbsp;     targetPort: 8080

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-ops-action-center

EOF

```



```bash

cat > apps/operations/thingsboard/ingressroute-action-center-http.yaml << 'EOF'

apiVersion: traefik.containo.us/v1alpha1

kind: IngressRoute

metadata:

&nbsp; name: addon-ops-action-center-http

&nbsp; namespace: ops-iot

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-action-center-http

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; entryPoints:

&nbsp;   - websecure

&nbsp; routes:

&nbsp;   - match: PathPrefix(`/ops-center`)

&nbsp;     kind: Rule

&nbsp;     services:

&nbsp;       - name: addon-ops-action-center

&nbsp;         port: 80

&nbsp;     middlewares:

&nbsp;       - name: core-traefik-forward-auth-sso

&nbsp;         namespace: appgear-core

EOF

```



---



\### 4.3 RPA – Robocorp com Scale-to-Zero



\#### 4.3.1 Namespace e kustomization



```bash

cat > apps/operations/rpa-robocorp/namespace.yaml << 'EOF'

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: ops-rpa

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: ops-rpa

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

EOF

```



```bash

cat > apps/operations/rpa-robocorp/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: ops-rpa



resources:

&nbsp; - namespace.yaml

&nbsp; - deployment-robocorp-runner.yaml

&nbsp; - service-robocorp-runner.yaml

&nbsp; - scaledobject-robocorp.yaml

EOF

```



\#### 4.3.2 Deployment Robocorp



```bash

cat > apps/operations/rpa-robocorp/deployment-robocorp-runner.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-ops-robocorp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-robocorp

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; replicas: 0

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-ops-robocorp

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-ops-robocorp

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: operations

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: rpa-runner

&nbsp;         image: robocorp/rcc:latest

&nbsp;         command: \["rcc"]

&nbsp;         args: \["run", "--task", "Main"]

&nbsp;         envFrom:

&nbsp;           - secretRef:

&nbsp;               name: ops-robocorp-credentials

&nbsp;         env:

&nbsp;           - name: RPA\_JOBS\_BROKERS

&nbsp;             value: core-redpanda.appgear-core.svc.cluster.local:9092

&nbsp;           - name: RPA\_JOBS\_TOPIC

&nbsp;             value: "ops.rpa.jobs"

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "250m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "2Gi"

EOF

```



Service:



```bash

cat > apps/operations/rpa-robocorp/service-robocorp-runner.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-ops-robocorp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-robocorp

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; ports:

&nbsp;   - name: http

&nbsp;     port: 8080

&nbsp;     targetPort: 8080

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-ops-robocorp

EOF

```



KEDA ScaledObject:



```bash

cat > apps/operations/rpa-robocorp/scaledobject-robocorp.yaml << 'EOF'

apiVersion: keda.sh/v1alpha1

kind: ScaledObject

metadata:

&nbsp; name: addon-ops-robocorp

&nbsp; namespace: ops-rpa

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-robocorp

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; scaleTargetRef:

&nbsp;   kind: Deployment

&nbsp;   name: addon-ops-robocorp

&nbsp; minReplicaCount: 0

&nbsp; maxReplicaCount: 10

&nbsp; cooldownPeriod: 300

&nbsp; pollingInterval: 30

&nbsp; triggers:

&nbsp;   - type: kafka

&nbsp;     metadata:

&nbsp;       bootstrapServers: core-redpanda.appgear-core.svc.cluster.local:9092

&nbsp;       consumerGroup: ops-rpa-runners

&nbsp;       topic: ops.rpa.jobs

&nbsp;       lagThreshold: "1"

EOF

```



---



\### 4.4 Edge – KubeEdge CloudCore com VIP dedicado



\#### 4.4.1 Namespace e kustomization



```bash

cat > apps/operations/kubeedge/namespace.yaml << 'EOF'

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: ops-edge

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: ops-edge

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

EOF

```



```bash

cat > apps/operations/kubeedge/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: ops-edge



resources:

&nbsp; - namespace.yaml

&nbsp; - configmap-cloudcore.yaml

&nbsp; - deployment-cloudcore.yaml

&nbsp; - service-cloudcore-lb.yaml

EOF

```



\#### 4.4.2 ConfigMap + Deployment CloudCore (com resources)



```bash

cat > apps/operations/kubeedge/configmap-cloudcore.yaml << 'EOF'

apiVersion: v1

kind: ConfigMap

metadata:

&nbsp; name: kubeedge-cloudcore-config

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-kubeedge-cloudcore

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

data:

&nbsp; cloudcore.yaml: |

&nbsp;   apiVersion: cloudcore.config.kubeedge.io/v1alpha2

&nbsp;   kind: CloudCoreConfiguration

&nbsp;   kubeAPIConfig:

&nbsp;     master: ""

&nbsp;     kubeConfig: ""

&nbsp;   cloudHub:

&nbsp;     address: 0.0.0.0

&nbsp;     port: 10000

&nbsp;     nodeLimit: 1000

&nbsp;   edgeController:

&nbsp;     nodeUpdateFrequency: 10

EOF

```



```bash

cat > apps/operations/kubeedge/deployment-cloudcore.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-ops-kubeedge-cloudcore

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-kubeedge-cloudcore

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-ops-kubeedge-cloudcore

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-ops-kubeedge-cloudcore

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: operations

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: cloudcore

&nbsp;         image: kubeedge/cloudcore:latest

&nbsp;         ports:

&nbsp;           - containerPort: 10000

&nbsp;             name: cloudhub

&nbsp;           - containerPort: 10001

&nbsp;             name: cloudstream

&nbsp;         volumeMounts:

&nbsp;           - name: kubeedge-config

&nbsp;             mountPath: /etc/kubeedge

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "250m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "2Gi"

&nbsp;     volumes:

&nbsp;       - name: kubeedge-config

&nbsp;         configMap:

&nbsp;           name: kubeedge-cloudcore-config

EOF

```



\#### 4.4.3 Service LoadBalancer CloudCore (VIP)



```bash

cat > apps/operations/kubeedge/service-cloudcore-lb.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-ops-kubeedge-cloudcore

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-ops-kubeedge-cloudcore

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; type: LoadBalancer

&nbsp; externalTrafficPolicy: Local

&nbsp; # loadBalancerIP pode ser definido dependendo do provedor

&nbsp; # loadBalancerIP: 203.0.113.10

&nbsp; ports:

&nbsp;   - name: cloudhub

&nbsp;     port: 10000

&nbsp;     targetPort: 10000

&nbsp;     protocol: TCP

&nbsp;   - name: cloudstream

&nbsp;     port: 10001

&nbsp;     targetPort: 10001

&nbsp;     protocol: TCP

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-ops-kubeedge-cloudcore

EOF

```



> Esse VIP será o endpoint que \*\*edgecore\*\* (nos nós Edge) enxergará. Deve estar liberado no firewall e no DNS (ex.: `cloudcore.edge.appgear.local`).



\#### 4.4.4 Join de nós Edge (fora do cluster)



Em cada host Edge:



```bash

\# Exemplo - ajustar IP/DNS e token

sudo keadm join \\

&nbsp; --cloudcore-ipport=cloudcore.edge.appgear.local:10000 \\

&nbsp; --edgenode-name=edge-site-01 \\

&nbsp; --token=<TOKEN\_KUBEEDGE>

```



O `token` deve ser:



\* Gerado/obtido durante a instalação do KubeEdge.

\* Armazenado/rotacionado via \*\*Vault\*\* (Módulo 5).



---



\### 4.5 Recursos por workspace (ws-<workspace\_id>-ops)



Exemplo simplificado de adapter de telemetria por workspace (mapeando `workspace-id` ↔ `tenant-id`):



```bash

cat > apps/ops/telemetry-adapter/deployment.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: ws-ops-telemetry-adapter

&nbsp; namespace: ws-<workspace\_id>-ops

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: ws-ops-telemetry-adapter

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: operations

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: "<workspace\_id>"

&nbsp;   appgear.io/tenant-id: "<tenant\_id>"

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod11-suite-operations"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: ws-ops-telemetry-adapter

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: ws-ops-telemetry-adapter

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: operations

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: "<workspace\_id>"

&nbsp;       appgear.io/tenant-id: "<tenant\_id>"

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: adapter

&nbsp;         image: appgear/ops-telemetry-adapter:latest

&nbsp;         env:

&nbsp;           - name: THINGSBOARD\_URL

&nbsp;             value: https://core.dev.appgear.local/iot

&nbsp;           - name: REDPANDA\_BROKERS

&nbsp;             value: core-redpanda.appgear-core.svc.cluster.local:9092

&nbsp;           - name: WORKSPACE\_ID

&nbsp;             value: "<workspace\_id>"

&nbsp;           - name: TENANT\_ID

&nbsp;             value: "<tenant\_id>"

EOF

```



> O Módulo 13 define como `<workspace\_id>` e `<tenant\_id>` são criados; este módulo só usa esses IDs.



---



\### 4.6 Topologia A – Compose (demo IoT/DT com MQTT)



```bash

mkdir -p /opt/webapp-ia/operations



cat > /opt/webapp-ia/operations/docker-compose.operations.yml << 'EOF'

version: "3.9"



services:

&nbsp; traefik:

&nbsp;   image: traefik:v2.11

&nbsp;   command:

&nbsp;     - "--providers.docker=true"

&nbsp;     - "--entrypoints.web.address=:80"

&nbsp;     - "--entrypoints.mqtt.address=:1883"

&nbsp;   ports:

&nbsp;     - "80:80"

&nbsp;     - "1883:1883"

&nbsp;   volumes:

&nbsp;     - /var/run/docker.sock:/var/run/docker.sock



&nbsp; postgres\_postgis:

&nbsp;   image: postgis/postgis:latest

&nbsp;   environment:

&nbsp;     POSTGRES\_DB: thingsboard

&nbsp;     POSTGRES\_USER: thingsboard

&nbsp;     POSTGRES\_PASSWORD: ${OPS\_THINGSBOARD\_DB\_PASSWORD}

&nbsp;   volumes:

&nbsp;     - ./data/postgis:/var/lib/postgresql/data



&nbsp; thingsboard:

&nbsp;   image: thingsboard/tb-postgres:latest

&nbsp;   environment:

&nbsp;     TB\_POSTGRES\_HOST: postgres\_postgis

&nbsp;     TB\_POSTGRES\_DB: thingsboard

&nbsp;     TB\_POSTGRES\_USERNAME: thingsboard

&nbsp;     TB\_POSTGRES\_PASSWORD: ${OPS\_THINGSBOARD\_DB\_PASSWORD}

&nbsp;   depends\_on:

&nbsp;     - postgres\_postgis

&nbsp;   labels:

&nbsp;     - "traefik.enable=true"

&nbsp;     - "traefik.http.routers.iot.rule=PathPrefix(`/iot`)"

&nbsp;     - "traefik.http.services.iot.loadbalancer.server.port=8080"

&nbsp;     - "traefik.tcp.routers.iot-mqtt.rule=HostSNI(`\*`)"

&nbsp;     - "traefik.tcp.routers.iot-mqtt.entrypoints=mqtt"

&nbsp;     - "traefik.tcp.services.iot-mqtt.loadbalancer.server.port=1883"

&nbsp;   volumes:

&nbsp;     - ./data/thingsboard:/data

EOF

```



`.env` central:



```bash

cat >> /opt/webapp-ia/.env << 'EOF'

OPS\_THINGSBOARD\_DB\_PASSWORD=trocar-para-senha-segura

EOF

```



> Reforço: esta topologia é apenas de \*\*desenvolvimento/demo\*\*.



---



\## 5. Como verificar



1\. \*\*GitOps da suíte\*\*



&nbsp;  ```bash

&nbsp;  cd webapp-ia-gitops-suites

&nbsp;  tree apps/operations

&nbsp;  ```



2\. \*\*Argo CD\*\*



&nbsp;  ```bash

&nbsp;  argocd app list | grep suite-operations

&nbsp;  argocd app get suite-operations

&nbsp;  ```



&nbsp;  \* STATUS: `Healthy`

&nbsp;  \* SYNC: `Synced`.



3\. \*\*Namespaces\*\*



&nbsp;  ```bash

&nbsp;  kubectl get ns | egrep 'ops-iot|ops-rpa|ops-edge'

&nbsp;  ```



4\. \*\*ThingsBoard e Action Center\*\*



&nbsp;  ```bash

&nbsp;  kubectl get deploy,svc -n ops-iot

&nbsp;  ```



&nbsp;  \* `addon-ops-thingsboard`, `addon-ops-thingsboard-http`, `addon-ops-thingsboard-mqtt`, `addon-ops-action-center`.



&nbsp;  Testes HTTP (cadeia WAF):



&nbsp;  ```bash

&nbsp;  curl -k https://core.dev.appgear.local/iot -I

&nbsp;  curl -k https://core.dev.appgear.local/ops-center -I

&nbsp;  ```



5\. \*\*Borda MQTT/CoAP\*\*



&nbsp;  Verificar entrypoint MQTT no Traefik:



&nbsp;  ```bash

&nbsp;  kubectl get ingressroutetcp -A | grep thingsboard-mqtt

&nbsp;  ```



&nbsp;  Testar MQTT (client):



&nbsp;  ```bash

&nbsp;  mosquitto\_pub -h <ip\_ou\_dns\_mqtt> -p 1883 -t test/topic -m "hello"

&nbsp;  ```



&nbsp;  Para CoAP, usar `coap-client` apontando para o VIP do LB UDP.



6\. \*\*KubeEdge CloudCore\*\*



&nbsp;  ```bash

&nbsp;  kubectl get deploy,svc -n ops-edge

&nbsp;  ```



&nbsp;  \* Service `addon-ops-kubeedge-cloudcore` deve ter `EXTERNAL-IP` (VIP).



&nbsp;  Nos nodes:



&nbsp;  ```bash

&nbsp;  kubectl get nodes | grep edge-

&nbsp;  ```



&nbsp;  \* Nós Edge aparecem em `Ready`.



7\. \*\*RPA + KEDA\*\*



&nbsp;  ```bash

&nbsp;  kubectl get scaledobject -n ops-rpa

&nbsp;  kubectl get deploy -n ops-rpa

&nbsp;  ```



&nbsp;  \* ScaledObject presente.

&nbsp;  \* Deployment com `replicas: 0` em idle.

&nbsp;  \* Publicar jobs no tópico `ops.rpa.jobs` e observar escala automática.



8\. \*\*Labels de FinOps\*\*



&nbsp;  ```bash

&nbsp;  kubectl get deploy -n ops-iot -o jsonpath='{.items\[\*].metadata.labels.appgear\\.io/tenant-id}'

&nbsp;  ```



&nbsp;  \* Deve retornar `global` (para recursos globais).

&nbsp;  \* Para workspaces, fazer o mesmo em `ws-<workspace\_id>-ops`.



9\. \*\*Observabilidade / Custos\*\*



&nbsp;  \* Grafana: dashboards com métricas de ThingsBoard, Action Center, RPA, CloudCore.

&nbsp;  \* Lago/OpenCost: filtros por `appgear.io/suite=operations` e `appgear.io/tenant-id`.



---



\## 6. Erros comuns (e como este retrofit evita)



1\. \*\*Usar WAF HTTP para MQTT/CoAP\*\*



&nbsp;  \* Antes: tentava expor IoT via Ingress HTTP.

&nbsp;  \* Agora:



&nbsp;    \* HTTP UIs continuam na cadeia WAF.

&nbsp;    \* MQTT/CoAP usam borda TCP/UDP dedicada com mTLS/firewall.



2\. \*\*CloudCore sem VIP claro\*\*



&nbsp;  \* Antes: Service indefinido quanto à exposição real para Edge.

&nbsp;  \* Agora:



&nbsp;    \* `Service type: LoadBalancer` com `externalTrafficPolicy: Local` e possibilidade de `loadBalancerIP`.

&nbsp;    \* Documentação de DNS/Firewall.



3\. \*\*Ausência de `appgear.io/tenant-id`\*\*



&nbsp;  \* Antes: custos de IoT/Edge invisíveis por tenant.

&nbsp;  \* Agora:



&nbsp;    \* Todos os manifests incluem `appgear.io/tenant-id` (`global` ou `<tenant\_id>`).



4\. \*\*ThingsBoard sem `resources`\*\*



&nbsp;  \* Antes: risco de saturar o cluster.

&nbsp;  \* Agora:



&nbsp;    \* Requests/limits definidos (CPU/Mem) para ThingsBoard, CloudCore, RPA.



5\. \*\*Expor Compose como produção\*\*



&nbsp;  \* Explicitamente marcado como \*\*dev/demo\*\*.

&nbsp;  \* Topologia B é a única recomendada para produção.



---



\## 7. Onde salvar



1\. \*\*Contrato de Desenvolvimento\*\*



&nbsp;  \* `appgear-contracts/1 - Desenvolvimento v0.md`

&nbsp;    Seção:

&nbsp;    `### Módulo 11 – Suíte Operations (IoT, Digital Twins, RPA, KubeEdge) – v0.1 (Retrofit)`



2\. \*\*Repositórios GitOps\*\*



&nbsp;  \* `webapp-ia-gitops-suites/apps/operations/\*\*`

&nbsp;    contendo todos os YAMLs mostrados neste módulo.

&nbsp;  \* `clusters/ag-<regiao>-core-<env>/apps-suites.yaml`

&nbsp;    com a Application `suite-operations`.



3\. \*\*Topologia A (compose)\*\*



&nbsp;  \* `/opt/webapp-ia/.env` (central).

&nbsp;  \* `/opt/webapp-ia/operations/docker-compose.operations.yml` e subpastas `data/`.



Se quiser, no próximo passo posso gerar o arquivo `Módulo 11 v0.1.md` pronto para download com exatamente este conteúdo.



