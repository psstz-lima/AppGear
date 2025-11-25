# Módulo 11 – Suíte Operations

Versão: v0.2

### Atualizações v0.2

- Operations: IoT/Geo-Ops com streaming Redpanda, PostGIS e automações n8n/BPMN/KEDA alinhadas à borda.


### Premissas padrão (v0.2)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Camada de operação contínua: automações de rotina, integrações operacionais, observabilidade de negócio, IoT/Edge quando aplicável.
Conecta pipelines, filas, webhooks e tasks recorrentes que mantêm os webapps e integrações “vivos”.

---

## O que é

A **Suíte Operations** é a Suíte 3 da AppGear, responsável por conectar o mundo físico e os processos operacionais ao ecossistema da plataforma. Ela se organiza em quatro pilares:

1. **IoT & Digital Twins / Geo-Ops**

   * Plataforma IoT e gêmeos digitais baseada em:

     * **ThingsBoard** para telemetria, devices, assets e dashboards;
     * **Postgres + PostGIS** (Módulo 4) como storage geoespacial e de metadados.
   * Entrega:

     * Gestão de dispositivos, ativos, tenants e regras;
     * Geo-Ops (visualização e ações por mapa, regiões, rotas).

2. **Real-Time Action Center (Eventos / Streaming)**

   * Serviço `addon-ops-action-center` que:

     * Consome eventos de telemetria de **Redpanda** (Módulo 4);
     * Aplica regras de decisão (integrando com N8n/BPMN e Brain);
     * Dispara ações (RPA, webhooks, APIs, notificações).

3. **RPA (Robocorp)**

   * `addon-ops-robocorp` para robôs que operam sobre sistemas sem API;
   * Jobs de RPA chegam por fila/stream (`ops.rpa.jobs` em Redpanda);
   * Workers escalam de 0 a N via **KEDA**, controlando custo.

4. **Edge / KubeEdge**

   * `addon-ops-kubeedge-cloudcore` no cluster central;
   * `edgecore` em nós remotos (sites físicos);
   * Permite rodar workloads (IoT/RPA) próximos dos dispositivos, com:

     * Controle centralizado (GitOps, SSO, Observabilidade);
     * Execução distribuída no Edge.

### Topologias

* **Topologia B (produção / Kubernetes)**
  Namespaces dedicados:

  * `ops-iot` (ThingsBoard + Action Center);
  * `ops-rpa` (runners RPA);
  * `ops-edge` (KubeEdge / CloudCore);
  * `ws-<workspace_id>-ops` (recursos específicos por workspace).

* **Topologia A (dev/demo / Docker Compose)**
  Compose mínimo com Traefik + Postgres+PostGIS + ThingsBoard para demonstrações locais, **não recomendado** para produção.

---

## Por que

1. **Endereçar não conformidades do diagnóstico (G15, G05, M00-3)** 

   * **G15 – Forma Canônica**

     * Substituição de script `.py` por documento `Módulo 11 v0.1.md` em Markdown.

   * **G05 – Segurança de Borda IoT**

     * Entrada de **MQTT/CoAP** e **CloudCore** explicitada como:

       * Borda **TCP/UDP dedicada**, fora do WAF HTTP;
       * Protegida por mTLS, firewall e IP/VIP controlado.

   * **M00-3 – FinOps**

     * Inclusão de `appgear.io/tenant-id` em todos os recursos relevantes:

       * Permite rastrear custo por tenant/cliente;
       * Suporta rate limiting e políticas de cobrança.

   * **M00-3 – Uso de Resources**

     * Definição de `resources.requests/limits` para componentes pesados:

       * ThingsBoard;
       * CloudCore;
       * Workers RPA.

2. **Cadeia de rede coerente com o Módulo 2**

   * HTTP (UIs e APIs de gestão):

     * Passa pela cadeia **Traefik → Coraza → Kong → Istio** definida em M02.
   * Protocolos não HTTP (MQTT, CoAP, CloudCore TCP):

     * Entram via borda **TCP/UDP dedicada**, documentada como exceção:

       * WAF HTTP não se aplica;
       * Segurança baseada em mTLS, firewall, limitação de origem.

3. **FinOps em ambientes de telemetria de alto volume**

   * IoT gera grande volume de séries temporais;
   * Sem `appgear.io/tenant-id` em pods, PVCs, topics e bancos:

     * Não há refaturamento por cliente;
   * Este módulo:

     * Rotula recursos com `appgear.io/tenant-id`;
     * Alinha ThingsBoard (tenant interno) com `workspace-id` e `tenant-id` da AppGear.

4. **Interoperabilidade com M04 (Dados) e M13 (Workspaces)**

   * **M04**:

     * Usa **Postgres Core com PostGIS**;
     * Futuramente, Cassandra/Timescale podem ser plugados se custos exigirem.
   * **M13**:

     * Cada workspace representa um cliente ou subdomínio;
     * Devices de IoT em ThingsBoard se vinculam a:

       * `workspace-id` (AppGear);
       * `tenant-id` da AppGear;
       * tenant interno do ThingsBoard.

5. **Edge como extensão controlada da plataforma**

   * Workloads IoT/RPA podem ser deslocados para sites remotos via KubeEdge:

     * Reduz latência e tráfego até o cluster central;
   * Mantém governança:

     * Configuração declarativa via GitOps/Argo CD;
     * SSO/Segurança central;
     * Observabilidade e FinOps.

---

## Pré-requisitos

### Contratuais / Organizacionais

* **Contrato v0** como fonte de verdade da arquitetura; 
* Padrões do **Módulo 00**:

  * Nomes: `core-*` (Core), `addon-*` (Suítes);
  * Labels/annotations `appgear.io/*`;
  * `.env` central para segredos sensíveis em Topologia A.
* Módulos Core aplicados:

  * M01 – GitOps/Argo CD;
  * M02 – Rede e Borda;
  * M03 – Observabilidade/FinOps;
  * M04 – Storage/Bancos;
  * M05 – Segurança/Segredos;
  * M06 – Identidade/SSO;
  * M07 – Backstage;
  * M08 – Serviços Core;
  * M09 – Factory;
  * M10 – Brain.

### Infraestrutura – Topologia B

* Cluster Kubernetes `ag-<regiao>-core-<env>` com:

  * Malha: Traefik, Coraza, Kong, Istio;
  * Core DBs: Postgres, Redis, Qdrant, Redpanda, RabbitMQ, Ceph;
  * Observabilidade: Prometheus, Grafana, Loki;
  * FinOps: OpenCost, Lago;
  * KEDA ativo (autoscaling baseado em eventos).

* Capacidade para novos namespaces:

  * `ops-iot`, `ops-rpa`, `ops-edge`, `ws-<workspace_id>-ops`.

* Regras de firewall / segurança:

  * Permitir conexões de entrada para:

    * MQTT/1883 (ou 8883 TLS) para devices;
    * CoAP/5683 (UDP) se utilizado;
    * CloudCore/10000–10001 para nós Edge.

### Ferramentas

* `git`, `kubectl`, `kustomize`, `argocd`, `yq`, `helm`, `keadm`;
* Acesso aos repositórios:

  * `appgear-gitops-core`;
  * `appgear-gitops-suites`;
  * Repositórios de imagens `appgear/ops-*`.

### Topologia A (dev/demo)

* Host Ubuntu LTS com Docker + docker-compose;
* Traefik como reverse proxy;
* Postgres+PostGIS;
* ThingsBoard em container.

---

## Como fazer (comandos)

### 1. Estrutura GitOps da Suíte Operations

No repositório de suítes:

```bash
cd appgear-gitops-suites

mkdir -p apps/operations
mkdir -p apps/operations/thingsboard
mkdir -p apps/operations/rpa-robocorp
mkdir -p apps/operations/kubeedge
```

#### 1.1 Kustomization da suíte

```bash
cat > apps/operations/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - thingsboard
  - rpa-robocorp
  - kubeedge
EOF
```

#### 1.2 Application Argo CD da suíte

```bash
cat >> clusters/ag-br-core-dev/apps-suites.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: suite-operations
  namespace: argocd
  labels:
    app.kubernetes.io/name: suite-operations
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: operations
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  project: default
  source:
    repoURL: https://git.example.com/appgear-gitops-suites.git
    targetRevision: main
    path: apps/operations
  destination:
    server: https://kubernetes.default.svc
    namespace: ops-iot
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
EOF
```

> Ajustar `repoURL`, cluster e namespace conforme o ambiente real.

---

### 2. IoT & Digital Twins – ThingsBoard + Action Center + Borda MQTT/CoAP

#### 2.1 Namespace e kustomization

`apps/operations/thingsboard/namespace.yaml`:

```bash
cat > apps/operations/thingsboard/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: ops-iot
  labels:
    app.kubernetes.io/name: ops-iot
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: operations
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
EOF
```

`apps/operations/thingsboard/kustomization.yaml`:

```bash
cat > apps/operations/thingsboard/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ops-iot

resources:
  - namespace.yaml
  - pvc-thingsboard.yaml
  - deployment-thingsboard.yaml
  - service-thingsboard-http.yaml
  - ingressroute-thingsboard-http.yaml
  - service-thingsboard-mqtt.yaml
  - ingressroute-tcp-mqtt.yaml
  - service-thingsboard-coap.yaml
  - lb-coap.yaml
  - deployment-action-center.yaml
  - service-action-center.yaml
  - ingressroute-action-center-http.yaml
EOF
```

#### 2.2 PVC + Deployment ThingsBoard (com resources)

`apps/operations/thingsboard/pvc-thingsboard.yaml`:

```bash
cat > apps/operations/thingsboard/pvc-thingsboard.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-ops-thingsboard-data
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard
    appgear.io/tier: addon
    appgear.io/suite: operations
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ceph-block
  resources:
    requests:
      storage: 50Gi
EOF
```

`apps/operations/thingsboard/deployment-thingsboard.yaml`:

```bash
cat > apps/operations/thingsboard/deployment-thingsboard.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-ops-thingsboard
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard
    app.kubernetes.io/part-of: appgear
    appgear.io	tier: addon
    appgear.io	suite: operations
    appgear.io	topology: B
    appgear.io	workspac e-id: global
    appgear.io	tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-ops-thingsboard
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-ops-thingsboard
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: operations
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: thingsboard
          image: thingsboard/tb-postgres:latest
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 1883
              name: mqtt
            - containerPort: 5683
              name: coap
          envFrom:
            - secretRef:
                name: ops-thingsboard-db
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            requests:
              cpu: "500m"
              memory: "2Gi"
            limits:
              cpu: "2"
              memory: "4Gi"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: pvc-ops-thingsboard-data
EOF
```

*(seu editor pode ter quebrado algumas tabs/espaces acima; ao colar, normalize os espaços)*

#### 2.3 HTTP (UI e APIs) – cadeia Traefik → Coraza → Kong → Istio

Service HTTP:

```bash
cat > apps/operations/thingsboard/service-thingsboard-http.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-ops-thingsboard-http
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard-http
    appgear.io/suite: operations
    appgear.io/tenant-id: global
spec:
  ports:
    - name: http
      port: 80
      targetPort: 8080
  selector:
    app.kubernetes.io/name: addon-ops-thingsboard
EOF
```

IngressRoute HTTP (ex.: `/iot`):

```bash
cat > apps/operations/thingsboard/ingressroute-thingsboard-http.yaml << 'EOF'
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: addon-ops-thingsboard-http
  namespace: ops-iot
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard-http
    appgear.io/suite: operations
    appgear.io/topology: B
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  entryPoints:
    - websecure
  routes:
    - match: PathPrefix(`/iot`)
      kind: Rule
      services:
        - name: addon-ops-thingsboard-http
          port: 80
      middlewares:
        - name: core-traefik-forward-auth-sso
          namespace: appgear-core
EOF
```

> O tráfego HTTP entra pela cadeia padrão WAF/API Gateway. Apenas UIs/APIs administrativas.

#### 2.4 MQTT – borda TCP dedicada (sem WAF HTTP, com mTLS)

Service interno MQTT:

```bash
cat > apps/operations/thingsboard/service-thingsboard-mqtt.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-ops-thingsboard-mqtt
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard-mqtt
    appgear.io/suite: operations
    appgear.io/tenant-id: global
spec:
  ports:
    - name: mqtt
      port: 1883
      targetPort: 1883
  selector:
    app.kubernetes.io/name: addon-ops-thingsboard
EOF
```

IngressRouteTCP MQTT (entrada dedicada em Traefik):

> Requer `entryPoints.mqtt.address=:1883` configurado no Traefik (Módulo 2).

```bash
cat > apps/operations/thingsboard/ingressroute-tcp-mqtt.yaml << 'EOF'
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: addon-ops-thingsboard-mqtt
  namespace: ops-iot
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard-mqtt
    appgear.io/suite: operations
    appgear.io/topology: B
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  entryPoints:
    - mqtt
  routes:
    - match: HostSNI(`*`)
      services:
        - name: addon-ops-thingsboard-mqtt
          port: 1883
  tls:
    passthrough: true
EOF
```

Pontos-chave:

* WAF (Coraza) não é aplicado (não faz sentido para MQTT);
* Segurança vem de:

  * **mTLS** (client cert nos devices);
  * Firewall/SG controlando quem atinge a porta 1883;
  * Limitação de IPs/origens quando necessário.

#### 2.5 CoAP – LB UDP dedicado (opcional)

Service CoAP:

```bash
cat > apps/operations/thingsboard/service-thingsboard-coap.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-ops-thingsboard-coap
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard-coap
    appgear.io/suite: operations
    appgear.io/tenant-id: global
spec:
  type: ClusterIP
  ports:
    - name: coap
      port: 5683
      targetPort: 5683
      protocol: UDP
  selector:
    app.kubernetes.io/name: addon-ops-thingsboard
EOF
```

Service LoadBalancer UDP:

```bash
cat > apps/operations/thingsboard/lb-coap.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-ops-thingsboard-coap-lb
  labels:
    app.kubernetes.io/name: addon-ops-thingsboard-coap-lb
    appgear.io/suite: operations
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  ports:
    - name: coap
      port: 5683
      targetPort: 5683
      protocol: UDP
  selector:
    app.kubernetes.io/name: addon-ops-thingsboard
EOF
```

> O provedor de cloud atribui um IP externo (VIP) a esse LB, registrado no DNS e liberado no firewall. Segurança via DTLS/mTLS + firewall.

#### 2.6 Action Center (HTTP, integra com Redpanda)

Deployment:

```bash
cat > apps/operations/thingsboard/deployment-action-center.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-ops-action-center
  labels:
    app.kubernetes.io/name: addon-ops-action-center
    app.kubernetes.io/part-of: appgear
    appgear.io	tier: addon
    appgear.io	suite: operations
    appgear.io	topology: B
    appgear.io	workspac e-id: global
    appgear.io	tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-ops-action-center
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-ops-action-center
        app.kubernetes.io/part-of: appgear
        appgear.io	tier: addon
        appgear.io	suite: operations
        appgear.io	topology: B
        appgear.io	workspac e-id: global
        appgear.io	tenant-id: global
    spec:
      containers:
        - name: action-center
          image: appgear/ops-action-center:latest
          ports:
            - containerPort: 8080
              name: http
          env:
            - name: REDPANDA_BROKERS
              value: core-redpanda.appgear-core.svc.cluster.local:9092
            - name: TELEMETRY_TOPICS
              value: "iot.telemetry.*,ops.alerts.*"
            - name: WORKSPACE_MAPPING_STRATEGY
              value: "tenantId=appgear.io/tenant-id"
          envFrom:
            - secretRef:
                name: ops-action-center-secrets
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
EOF
```

Service:

```bash
cat > apps/operations/thingsboard/service-action-center.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-ops-action-center
  labels:
    app.kubernetes.io/name: addon-ops-action-center
    appgear.io/suite: operations
    appgear.io/tenant-id: global
spec:
  ports:
    - name: http
      port: 80
      targetPort: 8080
  selector:
    app.kubernetes.io/name: addon-ops-action-center
EOF
```

IngressRoute HTTP:

```bash
cat > apps/operations/thingsboard/ingressroute-action-center-http.yaml << 'EOF'
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: addon-ops-action-center-http
  namespace: ops-iot
  labels:
    app.kubernetes.io/name: addon-ops-action-center-http
    appgear.io	suite: operations
    appgear.io	topology: B
    appgear.io	tenant-id: global
spec:
  entryPoints:
    - websecure
  routes:
    - match: PathPrefix(`/ops-center`)
      kind: Rule
      services:
        - name: addon-ops-action-center
          port: 80
      middlewares:
        - name: core-traefik-forward-auth-sso
          namespace: appgear-core
EOF
```

---

### 3. RPA – Robocorp com Scale-to-Zero

#### 3.1 Namespace e kustomization

`apps/operations/rpa-robocorp/namespace.yaml`:

```bash
cat > apps/operations/rpa-robocorp/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: ops-rpa
  labels:
    app.kubernetes.io/name: ops-rpa
    appgear.io/tier: addon
    appgear.io/suite: operations
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
EOF
```

`apps/operations/rpa-robocorp/kustomization.yaml`:

```bash
cat > apps/operations/rpa-robocorp/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ops-rpa

resources:
  - namespace.yaml
  - deployment-robocorp-runner.yaml
  - service-robocorp-runner.yaml
  - scaledobject-robocorp.yaml
EOF
```

#### 3.2 Deployment Robocorp + Service + KEDA

Deployment:

```bash
cat > apps/operations/rpa-robocorp/deployment-robocorp-runner.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-ops-robocorp
  labels:
    app.kubernetes.io/name: addon-ops-robocorp
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: operations
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  replicas: 0
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-ops-robocorp
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-ops-robocorp
        app.kubernetes.io/part-of: appgear
        appgear.io	tier: addon
        appgear.io	suite: operations
        appgear.io	topology: B
        appgear.io	workspac e-id: global
        appgear.io	tenant-id: global
    spec:
      containers:
        - name: rpa-runner
          image: robocorp/rcc:latest
          command: ["rcc"]
          args: ["run", "--task", "Main"]
          envFrom:
            - secretRef:
                name: ops-robocorp-credentials
          env:
            - name: RPA_JOBS_BROKERS
              value: core-redpanda.appgear-core.svc.cluster.local:9092
            - name: RPA_JOBS_TOPIC
              value: "ops.rpa.jobs"
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "2"
              memory: "2Gi"
EOF
```

Service:

```bash
cat > apps/operations/rpa-robocorp/service-robocorp-runner.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-ops-robocorp
  labels:
    app.kubernetes.io/name: addon-ops-robocorp
    appgear.io/suite: operations
    appgear.io/tenant-id: global
spec:
  ports:
    - name: http
      port: 8080
      targetPort: 8080
  selector:
    app.kubernetes.io/name: addon-ops-robocorp
EOF
```

KEDA:

```bash
cat > apps/operations/rpa-robocorp/scaledobject-robocorp.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: addon-ops-robocorp
  namespace: ops-rpa
  labels:
    app.kubernetes.io/name: addon-ops-robocorp
    appgear.io	tier: addon
    appgear.io	suite: operations
    appgear.io	topology: B
    appgear.io	workspac e-id: global
    appgear.io	tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  scaleTargetRef:
    kind: Deployment
    name: addon-ops-robocorp
  minReplicaCount: 0
  maxReplicaCount: 10
  cooldownPeriod: 300
  pollingInterval: 30
  triggers:
    - type: kafka
      metadata:
        bootstrapServers: core-redpanda.appgear-core.svc.cluster.local:9092
        consumerGroup: ops-rpa-runners
        topic: ops.rpa.jobs
        lagThreshold: "1"
EOF
```

---

### 4. Edge – KubeEdge CloudCore com VIP dedicado

#### 4.1 Namespace e kustomization

`apps/operations/kubeedge/namespace.yaml`:

```bash
cat > apps/operations/kubeedge/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: ops-edge
  labels:
    app.kubernetes.io/name: ops-edge
    appgear.io	tier: addon
    appgear.io	suite: operations
    appgear.io	topology: B
    appgear.io	workspac e-id: global
    appgear.io	tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
EOF
```

`apps/operations/kubeedge/kustomization.yaml`:

```bash
cat > apps/operations/kubeedge/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ops-edge

resources:
  - namespace.yaml
  - configmap-cloudcore.yaml
  - deployment-cloudcore.yaml
  - service-cloudcore-lb.yaml
EOF
```

#### 4.2 ConfigMap + Deployment CloudCore

ConfigMap:

```bash
cat > apps/operations/kubeedge/configmap-cloudcore.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubeedge-cloudcore-config
  labels:
    app.kubernetes.io/name: addon-ops-kubeedge-cloudcore
    appgear.io/suite: operations
    appgear.io/tenant-id: global
data:
  cloudcore.yaml: |
    apiVersion: cloudcore.config.kubeedge.io/v1alpha2
    kind: CloudCoreConfiguration
    kubeAPIConfig:
      master: ""
      kubeConfig: ""
    cloudHub:
      address: 0.0.0.0
      port: 10000
      nodeLimit: 1000
    edgeController:
      nodeUpdateFrequency: 10
EOF
```

Deployment:

```bash
cat > apps/operations/kubeedge/deployment-cloudcore.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-ops-kubeedge-cloudcore
  labels:
    app.kubernetes.io/name: addon-ops-kubeedge-cloudcore
    app.kubernetes.io/part-of: appgear
    appgear.io	tier: addon
    appgear.io	suite: operations
    appgear.io	topology: B
    appgear.io	workspac e-id: global
    appgear.io	tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-ops-kubeedge-cloudcore
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-ops-kubeedge-cloudcore
        app.kubernetes.io/part-of: appgear
        appgear.io	tier: addon
        appgear.io	suite: operations
        appgear.io	topology: B
        appgear.io	workspac e-id: global
        appgear.io	tenant-id: global
    spec:
      containers:
        - name: cloudcore
          image: kubeedge/cloudcore:latest
          ports:
            - containerPort: 10000
              name: cloudhub
            - containerPort: 10001
              name: cloudstream
          volumeMounts:
            - name: kubeedge-config
              mountPath: /etc/kubeedge
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "2Gi"
      volumes:
        - name: kubeedge-config
          configMap:
            name: kubeedge-cloudcore-config
EOF
```

#### 4.3 Service LoadBalancer CloudCore (VIP)

```bash
cat > apps/operations/kubeedge/service-cloudcore-lb.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-ops-kubeedge-cloudcore
  labels:
    app.kubernetes.io/name: addon-ops-kubeedge-cloudcore
    appgear.io	suite: operations
    appgear.io	tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  # loadBalancerIP pode ser definido dependendo do provedor
  # loadBalancerIP: 203.0.113.10
  ports:
    - name: cloudhub
      port: 10000
      targetPort: 10000
      protocol: TCP
    - name: cloudstream
      port: 10001
      targetPort: 10001
      protocol: TCP
  selector:
    app.kubernetes.io/name: addon-ops-kubeedge-cloudcore
EOF
```

> O VIP deste Service será o endpoint que os `edgecore` nos nós Edge enxergam (ex.: `cloudcore.edge.appgear.local`).

#### 4.4 Join de nós Edge

Em cada host Edge (fora do cluster):

```bash
sudo keadm join \
  --cloudcore-ipport=cloudcore.edge.appgear.local:10000 \
  --edgenode-name=edge-site-01 \
  --token=<TOKEN_KUBEEDGE>
```

O `token`:

* Deve ser gerado/obtido durante a instalação do KubeEdge;
* Deve ser armazenado/rotacionado via **Vault** (Módulo 5).

---

### 5. Recursos por workspace (`ws-<workspace_id>-ops`)

Exemplo simplificado de adapter de telemetria por workspace, mapeando `workspace-id ↔ tenant-id`:

```bash
cat > apps/ops/telemetry-adapter/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ws-ops-telemetry-adapter
  namespace: ws-<workspace_id>-ops
  labels:
    app.kubernetes.io/name: ws-ops-telemetry-adapter
    appgear.io	tier: addon
    appgear.io	suite: operations
    appgear.io	topology: B
    appgear.io	workspac e-id: "<workspace_id>"
    appgear.io	tenant-id: "<tenant_id>"
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod11-suite-operations"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ws-ops-telemetry-adapter
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ws-ops-telemetry-adapter
        appgear.io	tier: addon
        appgear.io	suite: operations
        appgear.io	topology: B
        appgear.io	workspac e-id: "<workspace_id>"
        appgear.io	tenant-id: "<tenant_id>"
    spec:
      containers:
        - name: adapter
          image: appgear/ops-telemetry-adapter:latest
          env:
            - name: THINGSBOARD_URL
              value: https://core.dev.appgear.local/iot
            - name: REDPANDA_BROKERS
              value: core-redpanda.appgear-core.svc.cluster.local:9092
            - name: WORKSPACE_ID
              value: "<workspace_id>"
            - name: TENANT_ID
              value: "<tenant_id>"
EOF
```

> O Módulo 13 define criação de `<workspace_id>` e `<tenant_id>`; este módulo apenas consome esses IDs.

---

### 6. Topologia A – Compose (demo IoT/DT com MQTT)

Diretório:

```bash
mkdir -p /opt/appgear/operations
```

`/opt/appgear/operations/docker-compose.operations.yml`:

```bash
cat > /opt/appgear/operations/docker-compose.operations.yml << 'EOF'
version: "3.9"

services:
  traefik:
    image: traefik:v2.11
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.mqtt.address=:1883"
    ports:
      - "80:80"
      - "1883:1883"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  postgres_postgis:
    image: postgis/postgis:latest
    environment:
      POSTGRES_DB: thingsboard
      POSTGRES_USER: thingsboard
      POSTGRES_PASSWORD: ${OPS_THINGSBOARD_DB_PASSWORD}
    volumes:
      - ./data/postgis:/var/lib/postgresql/data

  thingsboard:
    image: thingsboard/tb-postgres:latest
    environment:
      TB_POSTGRES_HOST: postgres_postgis
      TB_POSTGRES_DB: thingsboard
      TB_POSTGRES_USERNAME: thingsboard
      TB_POSTGRES_PASSWORD: ${OPS_THINGSBOARD_DB_PASSWORD}
    depends_on:
      - postgres_postgis
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.iot.rule=PathPrefix(`/iot`)"
      - "traefik.http.services.iot.loadbalancer.server.port=8080"
      - "traefik.tcp.routers.iot-mqtt.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.iot-mqtt.entrypoints=mqtt"
      - "traefik.tcp.services.iot-mqtt.loadbalancer.server.port=1883"
    volumes:
      - ./data/thingsboard:/data
EOF
```

`.env` central (compartilhado):

```bash
cat >> /opt/appgear/.env << 'EOF'
OPS_THINGSBOARD_DB_PASSWORD=trocar-para-senha-segura
EOF
```

Subir:

```bash
cd /opt/appgear/operations
docker compose -f docker-compose.operations.yml up -d
```

> Topologia A é **apenas desenvolvimento/demo**.

---

## Como verificar

1. **GitOps da suíte**

```bash
cd appgear-gitops-suites
tree apps/operations
```

* Deve existir a estrutura com `thingsboard`, `rpa-robocorp`, `kubeedge`.

2. **Argo CD**

```bash
argocd app list | grep suite-operations
argocd app get suite-operations
```

* STATUS: `Healthy`;
* SYNC: `Synced`.

3. **Namespaces**

```bash
kubectl get ns | egrep 'ops-iot|ops-rpa|ops-edge'
```

4. **ThingsBoard e Action Center**

```bash
kubectl get deploy,svc -n ops-iot
```

* Esperado: `addon-ops-thingsboard`, `addon-ops-thingsboard-http`, `addon-ops-thingsboard-mqtt`, `addon-ops-action-center`.

Testes HTTP (cadeia WAF):

```bash
curl -k https://core.dev.appgear.local/iot -I
curl -k https://core.dev.appgear.local/ops-center -I
```

5. **Borda MQTT/CoAP**

IngressRouteTCP MQTT:

```bash
kubectl get ingressroutetcp -A | grep thingsboard-mqtt
```

Teste MQTT:

```bash
mosquitto_pub -h <ip_ou_dns_mqtt> -p 1883 -t test/topic -m "hello"
```

Para CoAP, usar `coap-client` apontando para o VIP do LB UDP:

```bash
coap-client -m get coap://<vip_coap>/sensors
```

6. **KubeEdge CloudCore**

```bash
kubectl get deploy,svc -n ops-edge
```

* `addon-ops-kubeedge-cloudcore` deve estar `Available`;
* Service com `EXTERNAL-IP` (VIP).

Nos nodes:

```bash
kubectl get nodes | grep edge-
```

* Nós Edge devem aparecer como `Ready`.

7. **RPA + KEDA**

```bash
kubectl get scaledobject -n ops-rpa
kubectl get deploy -n ops-rpa
```

* `ScaledObject` presente;
* Deployment com `replicas: 0` em idle;
* Ao publicar jobs em `ops.rpa.jobs`, observar escala automática do deployment.

8. **Labels de FinOps**

```bash
kubectl get deploy -n ops-iot -o jsonpath='{.items[*].metadata.labels.appgear\.io/tenant-id}'
```

* Deve retornar `global` (recursos globais).

Em `ws-<workspace_id>-ops`, verificar `<tenant_id>` específico:

```bash
kubectl get deploy -n ws-<workspace_id>-ops -o jsonpath='{.items[*].metadata.labels.appgear\.io/tenant-id}'
```

9. **Observabilidade / Custos**

* Grafana: dashboards com métricas de ThingsBoard, Action Center, RPA, CloudCore;
* Lago/OpenCost: filtros por `appgear.io/suite=operations` e `appgear.io/tenant-id`.

10. **Topologia A (Compose)**

```bash
cd /opt/appgear/operations
docker ps
```

* Containers `traefik`, `postgres_postgis`, `thingsboard` em `Up`;
* Acessar:

  * `http://localhost/iot`;
  * MQTT em `localhost:1883`.

---

## Erros comuns

1. **Aplicar WAF HTTP em MQTT/CoAP**

* Problema:

  * Tentar expor IoT via Ingress HTTP;
* Correção:

  * HTTP UIs/API continuam na cadeia WAF;
  * MQTT/CoAP usam borda TCP/UDP dedicada, protegida por mTLS e firewall.

2. **CloudCore sem VIP claro**

* Problema:

  * Service sem exposição clara para Edge;
* Correção:

  * `Service type: LoadBalancer` com `externalTrafficPolicy: Local` e, se necessário, `loadBalancerIP` definido;
  * DNS explícito (ex.: `cloudcore.edge.appgear.local`).

3. **Ausência de `appgear.io/tenant-id`**

* Problema:

  * Custos de IoT/Edge invisíveis por tenant;
* Correção:

  * Garantir `appgear.io/tenant-id` em:

    * Namespace;
    * Deployment;
    * Service;
    * IngressRoute/Ingress;
    * ScaledObject.

4. **ThingsBoard sem `resources`**

* Problema:

  * Pode saturar o cluster;
* Correção:

  * Requests/limits de CPU/Mem definidos, conforme YAML deste módulo.

5. **Usar Topologia A como se fosse produção**

* Problema:

  * Sem WAF, sem Zero-Trust, sem controles equivalentes;
* Correção:

  * Topologia A apenas dev/demo;
  * Produção somente Topologia B.

6. **KEDA usando triggers errados**

* Problema:

  * ScaledObject apontando para tópico errado ou sem métricas;
* Correção:

  * Conferir tópico `ops.rpa.jobs` e brokers em Redpanda;
  * Validar funcionamento do trigger Kafka do KEDA.

7. **Edge join sem gestão de token/segurança**

* Problema:

  * `keadm join` com token exposto em script/plain text;
* Correção:

  * Armazenar token no Vault;
  * Gerar/rotacionar conforme M05.

---

## Onde salvar

1. **Contrato / Documentação**

* Repositório: `appgear-contracts` ou `appgear-docs`;
* Arquivo:

  * `Módulo 11 – Suíte Operations (IoT, Digital Twins, RPA, KubeEdge) v0.1.md`;
* Referência em:

  * `1 - Desenvolvimento v0.md`, seção “Módulo 11 – Suíte Operations (IoT, Digital Twins, RPA, KubeEdge) – v0.1”.

2. **Repositório GitOps – Suítes**

* Repositório: `appgear-gitops-suites`;
* Estrutura recomendada:

```text
apps/operations/kustomization.yaml
apps/operations/thingsboard/*.yaml
apps/operations/rpa-robocorp/*.yaml
apps/operations/kubeedge/*.yaml

clusters/ag-<regiao>-core-<env>/apps-suites.yaml
  # contém a Application suite-operations
```

3. **Topologia A (Compose)**

* Host de desenvolvimento:

```text
/opt/appgear/.env
/opt/appgear/operations/docker-compose.operations.yml
/opt/appgear/operations/data/
```

---

## Dependências entre os módulos

A Suíte Operations (Módulo 11) se encaixa na arquitetura da AppGear da seguinte forma:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Define:

    * Convenções de nomes (`core-*`, `addon-*`);
    * Forma canônica de artefatos (`*.md`);
    * Labels `appgear.io/*` (incluindo `appgear.io/tenant-id` e `appgear.io/workspace-id`);
    * Padrão de `.env` central em Topologia A;
    * Diretrizes de FinOps usadas para rotular todos os manifests deste módulo.

* **Módulo 01 – GitOps e Argo CD**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD como orquestrador GitOps;
    * Estrutura `clusters/ag-<regiao>-core-<env>/apps-suites.yaml`, onde é registrada a Application `suite-operations`.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * Cadeia de borda HTTP **Traefik → Coraza → Kong → Istio** para UIs/APIs de ThingsBoard e Action Center;
    * Configuração de entrypoints TCP/UDP dedicados (ex.: `mqtt`) para IoT;
    * Istio como malha de serviço para comunicação interna.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * **Dependência mútua.**
  * M03:

    * Coleta métricas e custos de ThingsBoard, Action Center, RPA e CloudCore;
  * M11:

    * Usa labels `appgear.io/suite=operations` e `appgear.io/tenant-id` para atribuição de custos;
    * Produz métricas de uso (jobs RPA, telemetria processada, etc.).

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, Redpanda, etc.)**

  * **Pré-requisito técnico.**
  * Fornece:

    * Postgres + PostGIS para ThingsBoard e Geo-Ops;
    * Ceph (block) para PVC de dados do ThingsBoard;
    * Redpanda como broker para telemetria (`iot.telemetry.*`) e jobs RPA (`ops.rpa.jobs`).

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * **Pré-requisito direto.**
  * Fornece:

    * Vault para credenciais de banco, tokens de dispositivos, tokens de KubeEdge, secrets de Robocorp;
    * OPA para validação de manifests (labels obrigatórias, uso de `resources`, ausência de segredos inline);
    * Falco monitorando pods de IoT, RPA e Edge.

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * **Pré-requisito funcional.**
  * Fornece:

    * SSO em UIs de ThingsBoard e Action Center (via forward-auth no Traefik);
    * Atributos de identidade (`tenant`, `workspace`) para mapear devices e assets a contextos de negócio.

* **Módulo 07 – Portal Backstage e Integrações Core**

  * **Consumidor deste módulo.**
  * Fornece:

    * Interfaces e plugins de catálogo para:

      * Visualizar tenants/dispositivos IoT;
      * Ver status de RPA e Edge sites;
    * Scaffolder que cria/adiciona integrações de Operations em sistemas existentes.

* **Módulo 08 – Serviços de Aplicação Core (LiteLLM, Flowise, N8n, Directus, Appsmith, Metabase)**

  * **Complementar.**
  * Fornece:

    * N8n/BPMN para orquestrar ações acionadas pelo Action Center;
    * Directus/Appsmith/Metabase para dashboards de operações, telemetria e performance de robôs.

* **Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer)**

  * **Complementar à Operations.**
  * Fornece:

    * CDEs e pipelines que podem simular ou ingerir dados de IoT;
    * Builders que podem empacotar aplicações de campo (agentes RPA/IoT) para Edge.

* **Módulo 10 – Suíte Brain (RAG, Agentes, AutoML)**

  * **Altamente acoplado.**
  * Fornece:

    * RAG e Agentes que podem consumir eventos de IoT/Operations;
    * Modelos de previsão/anomalia usados em Geo-Ops e regras do Action Center.

* **Módulo 11 – Suíte Operations (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06, M07, M08, M09, M10**;
  * Entrega:

    * Conectividade IoT (MQTT/CoAP);
    * Geo-Ops com ThingsBoard + PostGIS;
    * RPA com Robocorp e autoscaling por eventos;
    * Edge computing com KubeEdge CloudCore;
    * Base para que M13 (Workspaces/vClusters) conecte devices e operações a cada workspace/tenant.

* **Módulo 13 – Workspaces e vClusters (futuro)**

  * **Dependente direto deste módulo.**
  * Usará os componentes da Suíte Operations para:

    * Criar/associar devices, assets e fluxos de IoT a cada workspace;
    * Provisionar adapters `ws-<workspace_id>-ops` com mapeamento `workspace-id ↔ tenant-id`.

Fluxo geral:

**M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → M09 → M10 → M11 → (M13, suítes adicionais, PWA, etc.)**

Sem o Módulo 11, a AppGear não dispõe de uma camada padronizada de **IoT, Digital Twins, Geo-Ops, RPA e Edge**, limitando fortemente a capacidade de orquestrar operações físicas em tempo real e conectar o mundo real ao restante das suítes da plataforma.
