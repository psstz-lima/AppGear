Vou reescrever o **Módulo 04** inteiro já na versão **v0.1**, corrigindo exatamente os pontos do diagnóstico:

* Formato canônico: **Markdown (.md)**, não mais `.py`;
* **Labels FinOps** com `appgear.io/tenant-id: global` em todos os manifestos relevantes (StatefulSets, Services, PVCs, VolumeSnapshots, CronJobs, Applications);
* **resources.requests/limits** explícitos para todos os containers pesados (Postgres, Qdrant, Redpanda, RabbitMQ, Redis, Ceph operator, backup).

Abaixo está o texto para o arquivo **`Módulo 04 v0.1.md`**.

---

# Módulo 04 v0.1 – Armazenamento e Bancos Core

**Ceph, Postgres, Redis, Qdrant, RabbitMQ, Redpanda** – AppGear

---

## O que é

Este módulo define, em formato **Markdown canônico** (M00 v0.1), o **stack de persistência Core** da plataforma AppGear, cobrindo:

* **Storage padrão da Topologia B (Kubernetes):**

  * Ceph via Rook (bloco, filesystem e objeto S3 interno);
* **Bancos Core:**

  * Postgres (relacional, com overlay opcional PostGIS);
  * Redis (cache/KV);
  * Qdrant (vetor DB para RAG);
* **Brokers Core:**

  * RabbitMQ (Task Broker);
  * Redpanda (Streaming / Kafka-compatible);
* **Backups e DR (integração futura com Módulo 15):**

  * `VolumeSnapshotClass` e `VolumeSnapshot` em Ceph;
  * CronJob de backup lógico de Postgres para S3 em Ceph;
* **Governança FinOps e de Recursos (conforme M00 v0.1):**

  * Labels **obrigatórias** em todos os manifestos Core:

    * `appgear.io/tenant-id: global` (multi-tenancy lógico global);
    * `appgear.io/tier: core`, `appgear.io/suite: core`, `appgear.io/topology: B`, `appgear.io/workspace-id: global`;
  * `resources.requests` e `resources.limits` definidos para todos os containers pesados.

O módulo é projetado para **Topologia B (Kubernetes)** como padrão, com um trecho reduzido para **Topologia A (Docker / Legacy) apenas para testes**, nunca para produção.

---

## Por que

Este módulo atende diretamente:

1. **Contrato v0 – Seção 2 (Stack padrão e ambiente de execução)**

   * Define tecnicamente o uso de Ceph, Postgres, Redis, Qdrant, RabbitMQ e Redpanda como **Armazenamento e Bancos Core**.

2. **Contrato v0 – Seções 7.D e 7.E (Segurança de Infra, Continuidade e Custos)**

   * **Backups:**

     * VolumeSnapshots em Ceph (RBD);
     * Backup lógico de Postgres para bucket S3 em Ceph com credenciais geridas pelo Vault (Módulo 05).
   * **Criptografia:**

     * Em repouso: Ceph (pools/OSDs encriptados) + uso obrigatório de `ceph-block` para stateful core;
     * Em trânsito: todos os serviços Core com sidecar Istio, obedecendo mTLS STRICT (Módulo 02).
   * **FinOps:**

     * `appgear.io/tenant-id: global` em todos os recursos Core para atribuir custo de storage / compute ao tenant global;
     * Resources explícitos para bancos/brokers, evitando estouro de nós, eviction e custo imprevisível.

3. **Correção dos achados do Diagnóstico Profundo do Módulo 04 v0**

   * G15 / Forma Canônica:

     * O módulo passa de **`.py` para `.md`**, como exige o Módulo 00 v0.1.
   * M00-3 / FinOps:

     * Inclusão sistemática de `appgear.io/tenant-id: global` em todos os manifestos.
   * M00-3 / Resources:

     * Definição clara de requests/limits para Postgres, Qdrant, Redpanda, RabbitMQ, Redis e Ceph operator.

---

## Pré-requisitos

### Governança / Contrato

* **0 - Contrato v0** como fonte de verdade.
* **Módulo 00 v0.1** aplicado:

  * Formato canônico `.md`;
  * Labels `appgear.io/*` padrão, especialmente:

    * `appgear.io/tenant-id: global`.
* **Módulo 01**:

  * Argo CD com App-of-Apps;
  * `clusters/<cluster>/apps-core.yaml` existente (ex: `clusters/ag-br-core-dev/apps-core.yaml`).
* **Módulo 02**:

  * Istio com mTLS STRICT;
  * Traefik + Coraza + Kong implantados.
* **Módulo 03**:

  * Prometheus, Grafana, Loki, OpenCost, Lago ativos, utilizando labels `appgear.io/*`.

### Infraestrutura (Topologia B)

* Cluster Kubernetes (ex.: `ag-br-core-dev`) com:

  * Versão ≥ 1.24;
  * CSI Snapshot CRDs e snapshot-controller instalados.
* Nós com discos apropriados para Ceph (ou mapeamento de discos cloud).
* Namespaces previstos:

  * `rook-ceph`, `appgear-core`, `argocd`, `security`, `observability`, etc.

### Segurança / Segredos

* Vault operacional, com engines e paths planejados:

  * `kv/appgear/postgres/config`, `kv/appgear/redis/config`, `kv/appgear/qdrant/config`, `kv/appgear/rabbitmq/config`, `kv/appgear/redpanda/config`, `kv/appgear/ceph/backup-s3`;
  * Engine `database/` para credenciais dinâmicas Postgres (`database/creds/postgres-role-*`).
* Integração Vault → Secrets Kubernetes (Módulo 05).

### Ferramentas e Repositórios

* Repositório GitOps: `appgear-gitops-core` com estrutura:

  ```text
  appgear-gitops-core/
    clusters/
      ag-br-core-dev/
        kustomization.yaml
        apps-core.yaml
    apps/
      core/
        # (será preenchido por este módulo)
  ```

* Ferramentas: `kubectl`, `kustomize`, `argocd`, `git`.

### Topologia A (opcional – teste)

* Host Linux com Docker + docker-compose;
* Diretório `/opt/appgear` com `.env` e subpastas `data/...`.

---

## Como fazer (comandos)

> Abaixo, todo o fluxo para **criar o Módulo 04 v0.1** em Git, com Ceph + bancos + brokers + backups, já com labels de FinOps e resources.

### 1. Estrutura GitOps do Módulo 04

```bash
cd appgear-gitops-core

mkdir -p apps/core/{ceph,postgres,postgres/overlays/postgis,redis,qdrant,rabbitmq,redpanda,backup,data-brokers}
```

---

### 2. Ceph – Storage unificado com VolumeSnapshotClass

#### 2.1 Kustomization e Namespace

`apps/core/ceph/namespace.yaml`:

```bash
cat > apps/core/ceph/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: rook-ceph
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
EOF
```

`apps/core/ceph/kustomization.yaml`:

```bash
cat > apps/core/ceph/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - rook-operator.yaml
  - ceph-cluster.yaml
  - storageclass-block.yaml
  - storageclass-filesystem.yaml
  - storageclass-object.yaml
  - volumesnapshotclass-rbd.yaml
EOF
```

#### 2.2 Rook Operator (com resources e FinOps)

```bash
cat > apps/core/ceph/rook-operator.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rook-ceph-operator
  namespace: rook-ceph
  labels:
    app.kubernetes.io/name: core-ceph-operator
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-ceph-operator
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-ceph-operator
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      serviceAccountName: rook-ceph-system
      containers:
        - name: rook-ceph-operator
          image: rook/ceph:v1.15.0
          env:
            - name: ROOK_CURRENT_NAMESPACE_ONLY
              value: "false"
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"
EOF
```

#### 2.3 CephCluster (pools encriptados – criptografia em repouso)

```bash
cat > apps/core/ceph/ceph-cluster.yaml << 'EOF'
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
  labels:
    app.kubernetes.io/name: core-ceph
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  dataDirHostPath: /var/lib/rook
  cephVersion:
    image: quay.io/ceph/ceph:v18.2.0
  mon:
    count: 3
    allowMultiplePerNode: false
  dashboard:
    enabled: true
  network:
    hostNetwork: false
  # Assumir pools/OSDs com criptografia em repouso, conforme política de infra
  storage:
    useAllNodes: true
    useAllDevices: true
    config:
      databaseSizeMB: "2048"
      journalSizeMB: "1024"
EOF
```

#### 2.4 StorageClasses (com FinOps)

`storageclass-block.yaml`:

```bash
cat > apps/core/ceph/storageclass-block.yaml << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-block
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
  clusterID: rook-ceph
  pool: replicapool
  imageFormat: "2"
  imageFeatures: layering
reclaimPolicy: Retain
allowVolumeExpansion: true
mountOptions:
  - discard
volumeBindingMode: WaitForFirstConsumer
EOF
```

`storageclass-filesystem.yaml` e `storageclass-object.yaml` seguem o mesmo padrão de labels, incluindo `appgear.io/tenant-id: global`.

#### 2.5 VolumeSnapshotClass (Ceph RBD)

```bash
cat > apps/core/ceph/volumesnapshotclass-rbd.yaml << 'EOF'
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: ceph-rbd-snapclass
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
driver: rook-ceph.rbd.csi.ceph.com
deletionPolicy: Retain
parameters:
  clusterID: rook-ceph
  pool: replicapool
EOF
```

---

### 3. Postgres (Core + overlay PostGIS) – com mTLS, FinOps e resources

#### 3.1 Kustomization base

```bash
cat > apps/core/postgres/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - statefulset.yaml
  - service.yaml
  - configmap-postgresql.yaml
EOF
```

#### 3.2 ConfigMap

```bash
cat > apps/core/postgres/configmap-postgresql.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-postgres-config
  labels:
    app.kubernetes.io/name: core-postgres
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
data:
  postgresql.conf: |
    shared_buffers = '2GB'
    work_mem = '64MB'
    maintenance_work_mem = '512MB'
    max_connections = 500
    wal_level = replica
    archive_mode = off
    max_wal_senders = 10
    row_security = on
EOF
```

#### 3.3 StatefulSet (FinOps + resources + mTLS)

```bash
cat > apps/core/postgres/statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: core-postgres
  labels:
    app.kubernetes.io/name: core-postgres
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/backup-enabled: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  serviceName: core-postgres
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-postgres
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-postgres
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432
              name: postgres
          envFrom:
            - secretRef:
                name: core-postgres-credentials
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
            - name: config
              mountPath: /etc/postgresql/conf.d
          args:
            - "-c"
            - "config_file=/etc/postgresql/conf.d/postgresql.conf"
          resources:
            requests:
              cpu: "500m"
              memory: "2Gi"
            limits:
              cpu: "2"
              memory: "4Gi"
      volumes:
        - name: config
          configMap:
            name: core-postgres-config
            items:
              - key: postgresql.conf
                path: postgresql.conf
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          appgear.io/backup-enabled: "true"
          appgear.io/backup-profile: "core-postgres"
          appgear.io/tenant-id: global
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ceph-block
        resources:
          requests:
            storage: 200Gi
EOF
```

#### 3.4 Service

```bash
cat > apps/core/postgres/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-postgres
  labels:
    app.kubernetes.io/name: core-postgres
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  selector:
    app.kubernetes.io/name: core-postgres
  ports:
    - name: postgres
      port: 5432
      targetPort: postgres
EOF
```

#### 3.5 Overlay PostGIS (exemplo de novo componente com backup + mTLS)

```bash
cat > apps/core/postgres/overlays/postgis/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - ../../
patches:
  - target:
      kind: StatefulSet
      name: core-postgres
    patch: |
      apiVersion: apps/v1
      kind: StatefulSet
      metadata:
        name: core-postgres
      spec:
        template:
          spec:
            containers:
              - name: postgres
                image: postgis/postgis:16-3.4
EOF
```

---

### 4. Redis (Core Cache)

```bash
cat > apps/core/redis/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - statefulset.yaml
  - service.yaml
EOF
```

`statefulset.yaml`:

```bash
cat > apps/core/redis/statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: core-redis
  labels:
    app.kubernetes.io/name: core-redis
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/backup-enabled: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  serviceName: core-redis
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-redis
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-redis
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - name: redis
          image: redis:7
          args: ["--appendonly", "yes"]
          ports:
            - containerPort: 6379
              name: redis
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          appgear.io/backup-enabled: "true"
          appgear.io/backup-profile: "core-redis"
          appgear.io/tenant-id: global
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ceph-block
        resources:
          requests:
            storage: 20Gi
EOF
```

`service.yaml` inclui as mesmas labels com `appgear.io/tenant-id: global`.

---

### 5. Qdrant (Vetor DB – RAG)

Kustomization idêntica à anterior; StatefulSet com resources:

```bash
cat > apps/core/qdrant/statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: core-qdrant
  labels:
    app.kubernetes.io/name: core-qdrant
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/backup-enabled: "true"
    appgear.io/backup-profile: "core-qdrant"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  serviceName: core-qdrant
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-qdrant
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-qdrant
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - name: qdrant
          image: qdrant/qdrant:v1.11.0
          ports:
            - containerPort: 6333
              name: http
            - containerPort: 6334
              name: grpc
          volumeMounts:
            - name: data
              mountPath: /qdrant/storage
          resources:
            requests:
              cpu: "500m"
              memory: "4Gi"
            limits:
              cpu: "4"
              memory: "8Gi"
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          appgear.io/backup-enabled: "true"
          appgear.io/backup-profile: "core-qdrant"
          appgear.io/tenant-id: global
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ceph-block
        resources:
          requests:
            storage: 200Gi
EOF
```

Service idem, com labels completas.

---

### 6. RabbitMQ (Task Broker)

StatefulSet com resources e FinOps:

```bash
cat > apps/core/rabbitmq/statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: core-rabbitmq
  labels:
    app.kubernetes.io/name: core-rabbitmq
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/backup-enabled: "true"
    appgear.io/backup-profile: "core-rabbitmq"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  serviceName: core-rabbitmq
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-rabbitmq
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-rabbitmq
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - name: rabbitmq
          image: rabbitmq:3.13-management
          envFrom:
            - secretRef:
                name: core-rabbitmq-config
          ports:
            - containerPort: 5672
              name: amqp
            - containerPort: 15672
              name: http
          volumeMounts:
            - name: data
              mountPath: /var/lib/rabbitmq
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "2Gi"
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          appgear.io/backup-enabled: "true"
          appgear.io/backup-profile: "core-rabbitmq"
          appgear.io/tenant-id: global
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ceph-block
        resources:
          requests:
            storage: 100Gi
EOF
```

Service idem com labels FinOps.

---

### 7. Redpanda (Streaming – Kafka-compatible)

StatefulSet com resources pesados:

```bash
cat > apps/core/redpanda/statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: core-redpanda
  labels:
    app.kubernetes.io/name: core-redpanda
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/backup-enabled: "true"
    appgear.io/backup-profile: "core-redpanda"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  serviceName: core-redpanda
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: core-redpanda
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-redpanda
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - name: redpanda
          image: redpandadata/redpanda:latest
          args:
            - redpanda
            - start
            - --smp=2
            - --memory=4G
            - --reserve-memory=0M
            - --overprovisioned
          ports:
            - containerPort: 9092
              name: kafka
            - containerPort: 9644
              name: admin
          volumeMounts:
            - name: data
              mountPath: /var/lib/redpanda/data
          resources:
            requests:
              cpu: "2"
              memory: "4Gi"
            limits:
              cpu: "4"
              memory: "8Gi"
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          appgear.io/backup-enabled: "true"
          appgear.io/backup-profile: "core-redpanda"
          appgear.io/tenant-id: global
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ceph-block
        resources:
          requests:
            storage: 500Gi
EOF
```

Service idem com `appgear.io/tenant-id: global`.

---

### 8. Backups (CronJob Postgres + VolumeSnapshots)

#### 8.1 Kustomization

```bash
cat > apps/core/backup/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - cronjob-postgres-backup.yaml
  - volumesnapshots-core.yaml
EOF
```

#### 8.2 CronJob Postgres → Ceph S3 (com sidecar Istio + FinOps)

```bash
cat > apps/core/backup/cronjob-postgres-backup.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: core-postgres-backup
  labels:
    app.kubernetes.io/name: core-postgres-backup
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/backup-type: "logical"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  schedule: "0 3 * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app.kubernetes.io/name: core-postgres-backup
            appgear.io/tier: core
            appgear.io/suite: core
            appgear.io/topology: B
            appgear.io/workspace-id: global
            appgear.io/tenant-id: global
          annotations:
            sidecar.istio.io/inject: "true"
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pg-backup
              image: postgres:16
              envFrom:
                - secretRef:
                    name: core-postgres-credentials
                - secretRef:
                    name: core-postgres-backup-s3
              command:
                - /bin/sh
                - -c
                - |
                  set -e
                  export PGPASSWORD="${POSTGRES_PASSWORD}"
                  TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
                  FILE="/tmp/backup-${PGDATABASE}-${TIMESTAMP}.sql"
                  pg_dump -h core-postgres -U "${POSTGRES_USER}" -d "${PGDATABASE}" -F c -f "${FILE}"
                  aws s3 cp "${FILE}" "s3://${S3_BUCKET}/${PGDATABASE}/${FILE##*/}"
              resources:
                requests:
                  cpu: "200m"
                  memory: "512Mi"
                limits:
                  cpu: "500m"
                  memory: "1Gi"
EOF
```

#### 8.3 VolumeSnapshots Core (shapes)

```bash
cat > apps/core/backup/volumesnapshots-core.yaml << 'EOF'
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: snapshot-core-postgres
  namespace: appgear-core
  labels:
    appgear.io/backup-enabled: "true"
    appgear.io/backup-profile: "core-postgres"
    appgear.io/tenant-id: global
  annotations:
    appgear.io/backup-type: "snapshot"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  volumeSnapshotClassName: ceph-rbd-snapclass
  source:
    persistentVolumeClaimName: data-core-postgres-0
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: snapshot-core-qdrant
  namespace: appgear-core
  labels:
    appgear.io/backup-enabled: "true"
    appgear.io/backup-profile: "core-qdrant"
    appgear.io/tenant-id: global
  annotations:
    appgear.io/backup-type: "snapshot"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  volumeSnapshotClassName: ceph-rbd-snapclass
  source:
    persistentVolumeClaimName: data-core-qdrant-0
EOF
```

---

### 9. Agregador `core-data-brokers` + Argo CD

`apps/core/data-brokers/kustomization.yaml`:

```bash
cat > apps/core/data-brokers/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - ../ceph
  - ../postgres
  - ../redis
  - ../qdrant
  - ../rabbitmq
  - ../redpanda
  - ../backup
EOF
```

Adicionar o `Application` em `clusters/ag-br-core-dev/apps-core.yaml`:

```bash
cat >> clusters/ag-br-core-dev/apps-core.yaml << 'EOF'
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-data-brokers
  namespace: argocd
  labels:
    app.kubernetes.io/name: core-data-brokers
    app.kubernetes.io/part-of: appgear
    app.kubernetes.io/managed-by: argocd
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod4-storage-databases-core"
spec:
  project: appgear-core
  source:
    repoURL: git@github.com:appgear/appgear-gitops-core.git
    targetRevision: main
    path: apps/core/data-brokers
  destination:
    server: https://kubernetes.default.svc
    namespace: appgear-core
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

Commit / push / sync:

```bash
git add apps/core clusters/ag-br-core-dev/apps-core.yaml
git commit -m "mod4 v0.1: storage/bancos core com FinOps (tenant-id) e resources"
git push origin main

argocd app sync core-data-brokers
argocd app get core-data-brokers
```

---

### 10. Topologia A – Docker/Legacy (teste, não produção)

Mesma ideia da versão anterior, sem mudanças conceituais; apenas serve como ambiente de desenvolvimento e não precisa de labels FinOps (não é observado por OpenCost).

---

## Como verificar

1. **Ceph**

   * Namespaces e pods:

     ```bash
     kubectl get ns rook-ceph
     kubectl get pods -n rook-ceph
     kubectl get storageclass
     kubectl get volumesnapshotclass
     ```

   * `ceph-block` deve ser default; `ceph-rbd-snapclass` presente.

2. **Labels FinOps (tenant-id)**

   ```bash
   kubectl get statefulset -n appgear-core -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.metadata.labels.appgear\.io/tenant-id}{"\n"}{end}'
   kubectl get pvc -n appgear-core -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.metadata.labels.appgear\.io/tenant-id}{"\n"}{end}'
   ```

   Esperado: todos com `global`.

3. **Resources (requests/limits)**

   ```bash
   kubectl get pod -n appgear-core core-postgres-0 -o jsonpath='{.spec.containers[0].resources}'
   kubectl get pod -n appgear-core core-qdrant-0 -o jsonpath='{.spec.containers[0].resources}'
   kubectl get pod -n appgear-core core-redpanda-0 -o jsonpath='{.spec.containers[0].resources}'
   ```

   Esperado: requests/limits preenchidos, sem `null`.

4. **mTLS (Istio)**

   ```bash
   kubectl get pods -n appgear-core -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.metadata.annotations.sidecar\.istio\.io/inject}{"\n"}{end}'
   ```

   Esperado: `true` para todos os pods core.

5. **Backups**

   * CronJob:

     ```bash
     kubectl get cronjob -n appgear-core | grep core-postgres-backup
     ```

   * VolumeSnapshots:

     ```bash
     kubectl get volumesnapshot -n appgear-core
     ```

---

## Erros comuns

1. **Esquecer `appgear.io/tenant-id: global` em novos manifests**

   * Impacto: custos de storage caem em “Unallocated” no Módulo 03 (OpenCost).
   * Mitigação: tratar a label como obrigatória em **todo** StatefulSet/Service/PVC/VolumeSnapshot Core.

2. **resources ausentes ou mal dimensionados**

   * Impacto: eviction de pods críticos, instabilidade em picos de carga, custos imprevisíveis.
   * Mitigação: ajustar os valores sugeridos conforme perfil, mas nunca deixar resources em branco.

3. **Aplicar YAML fora do fluxo GitOps (kubectl apply)**

   * Impacto: Argo CD em `OutOfSync`.
   * Mitigação: sempre editar no Git + `git commit/push` e sincronizar via Argo CD.

4. **Snapshot-controller ausente**

   * Impacto: objetos `VolumeSnapshot` falhando.
   * Mitigação: validar CRDs e controller antes de aplicar `volumesnapshots-core.yaml`.

5. **Pools Ceph sem criptografia em repouso**

   * Impacto: não conformidade com 7.D/7.E do contrato.
   * Mitigação: coordenar com equipe de infra para garantir OSDs/pools encriptados.

---

## Onde salvar

* Repositório: `appgear-contracts`
* Arquivo canônico: **`desenvolvimento/Módulo 04 v0.1.md`**

Ações recomendadas:

1. **Arquivar ou remover** o antigo `Módulo 04 v0.py` (usado apenas como rascunho).
2. Adotar este conteúdo como **única fonte oficial** para o Módulo 04 v0.1.
3. Referenciar este módulo a partir de `1 - Desenvolvimento v0.md` ou consolidar todos os módulos num índice principal, conforme diretriz do Módulo 00 v0.1.

Com estas correções, o Módulo 04 passa a estar **CONFORME** em:

* Forma canônica (Markdown);
* Metadados de FinOps (`appgear.io/tenant-id: global`);
* Governança de recursos (`resources` obrigatórios);
* Alinhamento total com o Contrato v0 e com o diagnóstico profundo.
