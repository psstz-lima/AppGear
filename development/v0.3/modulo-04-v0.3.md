# M04 – Armazenamento e Bancos Core (v0.3)

> [!IMPORTANT]
> Este documento define o **Módulo 04 (M04)** da arquitetura AppGear na linha v0.3.  
> Deve ser lido em conjunto com:
> - `docs/architecture/contract/contract-v0.md`
> - `docs/architecture/audit/audit-v0.md`
> - `docs/architecture/interoperability/interoperability-v0.md`
> - `docs/architecture/interoperability/resources/fluxos-ai-first.md`
> - `docs/architecture/interoperability/resources/mapa-global.md`

Versão do módulo: v0.3  
Compatibilidade: linha v0 / v0.3  

---

## Contexto v0.3

### Padronização v0.3

- Uso de `.env.core` unificado para variáveis sensíveis.
- Proxy Chain: Traefik (TLS) → Coraza (WAF) → Kong (TLS passthrough) → Istio (mTLS STRICT).
- Stack integrada sob controle GitOps via ArgoCD com ApplicationSets.
- Padrão de versionamento e segurança revisado.

---

# Módulo 04 – Armazenamento e Bancos Core

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

- Mantém Ceph, bancos e brokers com snapshots e labels alinhadas para serviços de IA e automação.


### Premissas padrão (v0.3)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Descreve Ceph (ou storage equivalente) e bancos core: Postgres, Redis, Qdrant, Redpanda, MinIO, etc.
Padroniza classes de storage, PVCs, usuários e políticas de acesso para serviços da plataforma.

---

## 1. O que é

Este módulo define, em formato **Markdown canônico** (conforme Módulo 00), o **stack de Armazenamento e Bancos Core** da plataforma **AppGear**, cobrindo:

* **Storage padrão da Topologia B (Kubernetes)**

  * Ceph via Rook (bloco, filesystem e objeto S3 interno).

* **Bancos Core**

  * Postgres (relacional, com overlay opcional PostGIS).
  * Redis (cache / KV).
  * Qdrant (vetor DB para cenários de RAG).

* **Brokers Core**

  * RabbitMQ (task broker, filas).
  * Redpanda (streaming / Kafka-compatible).

* **Backups e DR (integração futura com módulo de Backup/DR)**

  * `VolumeSnapshotClass` e `VolumeSnapshot` usando Ceph (RBD).
  * `CronJob` de backup lógico de Postgres para S3 em Ceph, com credenciais geridas pelo Vault (Módulo de Segurança/Segredos).

* **Governança FinOps e de Recursos**

  * Labels **obrigatórias** em todos os manifests Core:

    * `appgear.io/tenant-id: global` (multi-tenancy lógico global),
    * `appgear.io/tier: core`,
    * `appgear.io/suite: core`,
    * `appgear.io/topology: B`,
    * `appgear.io/workspace-id: global`. 
  * `resources.requests` e `resources.limits` definidos para todos os containers pesados (bancos, brokers, Ceph operator).

O foco é **Topologia B (Kubernetes)**; há apenas um trecho reduzido para **Topologia A (Docker/Legacy)** para testes e desenvolvimento local, nunca para produção.

---

## 2. Por que

1. **Atender ao Contrato v0 (Stack padrão e ambiente de execução)** 

   * Formaliza tecnicamente Ceph, Postgres, Redis, Qdrant, RabbitMQ e Redpanda como **Armazenamento e Bancos Core** da AppGear.
   * Garante que qualquer módulo que precise de persistência crítica use StorageClasses e bancos padronizados.

2. **Segurança, Continuidade e Custos (Contrato v0 – seções de Infra/DR/FinOps)**

   * **Backups**:

     * `VolumeSnapshot` em Ceph (RBD) para workloads stateful críticos.
     * Backup lógico de Postgres para bucket S3 em Ceph, com segredos via Vault.
   * **Criptografia**:

     * Em repouso: pools/OSDs encriptados em Ceph + uso obrigatório de `ceph-block` para stateful core.
     * Em trânsito: sidecar Istio em todos os pods Core, com mTLS STRICT STRICT conforme Módulo 02.
   * **FinOps**:

     * Labels obrigatórias (principalmente `appgear.io/tenant-id: global`), permitindo o Módulo 03 (OpenCost/Lago) atribuir custo aos componentes Core.
     * `resources` explícitos evitam explosão de custo e saturação de nó por bancos/brokers.

3. **Correções do diagnóstico profundo do antigo Módulo 04**

   * Forma canônica: migração de `.py` para `.md`. 
   * Labels de FinOps: inclusão sistemática de `appgear.io/tenant-id: global` em todos os manifests core.
   * Governança de recursos: definição clara de `resources` mínimos para Ceph operator, Postgres, Redis, Qdrant, RabbitMQ e Redpanda.

4. **Base para RAG, pipelines e workloads intensivos**

   * Qdrant como vetor DB padrão para RAG, com recursos adequados (CPU/RAM/Storage) e backup.
   * Redpanda para streaming de eventos (monitoramento, billing, integrações), evitando soluções ad-hoc.

---

## 3. Pré-requisitos

### Governança / Contrato

* **0 – Contrato v0** aprovado.
* **Módulo 00 – Convenções, Repositórios e Nomenclatura**:

  * Padrão canônico de documentação em `.md`.
  * Labels `appgear.io/*` como obrigatórias (especialmente `appgear.io/tenant-id: global`).
* **Módulo 01 – Bootstrap GitOps e Argo CD**:

  * Argo CD instalado e operacional com App-of-Apps.
  * `clusters/<cluster>/apps-core.yaml` existente (ex.: `clusters/ag-br-core-dev/apps-core.yaml`).
* **Módulo 02 – Malha de Serviço e Borda**:

  * Istio com mTLS STRICT STRICT ativo.
  * Cadeia de borda `Traefik → Coraza → Kong → Istio` funcionando.
* **Módulo 03 – Observabilidade e FinOps**:

  * Prometheus, Grafana, Loki, OpenCost e Lago já implantados e utilizando labels `appgear.io/*` para recortes de custo.

### Infraestrutura (Topologia B)

* Cluster Kubernetes (ex.: `ag-br-core-dev`), versão ≥ 1.24. 
* CSI Snapshot CRDs e snapshot-controller instalados.
* Nós com discos apropriados para Ceph (bare-metal ou cloud disks).
* Namespaces existentes ou planejados:

  * `rook-ceph`, `appgear-core`, `argocd`, `security`, `observability`, etc.

### Segurança / Segredos

* Vault operacional, com engines e paths definidos, por exemplo: 

  * `kv/appgear/postgres/config`
  * `kv/appgear/redis/config`
  * `kv/appgear/qdrant/config`
  * `kv/appgear/rabbitmq/config`
  * `kv/appgear/redpanda/config`
  * `kv/appgear/ceph/backup-s3`
* Engine `database/` para credenciais dinâmicas Postgres (`database/creds/postgres-role-*`).
* Integração Vault → Secrets Kubernetes tratada no módulo de Segurança/Segredos.

### Ferramentas e Repositórios

* Repositório GitOps Core: `appgear-gitops-core`, ou equivalente, com estrutura base: 

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

* Ferramentas disponíveis:

  * `kubectl`
  * `kustomize` (ou `kubectl kustomize`)
  * `argocd`
  * `git`

### Topologia A (opcional – testes)

* Host Linux (Ubuntu LTS) com Docker + docker-compose.
* Diretório `/opt/appgear` com `.env` e subpastas `data/...` para testes locais (não produção).

---

## KEDA e scale-to-zero para Ceph/Brokers

* **Gateways Ceph (RGW/ingress)** devem ter `ScaledObject` com trigger HTTP (RPS) e `minReplicaCount: 0`, evitando pods ociosos em ambientes pequenos.
* **Brokers** (RabbitMQ/Redpanda) já possuem triggers de fila; alinhar `pollingInterval: 15s` e `cooldownPeriod: 120s` para padronizar tempo de reidratação.
* **Defaults em charts/kustomize:**

  ```yaml
  keda:
    enabled: true
    minReplicaCount: 0
    cooldownPeriod: 120
    pollingInterval: 15
  ```

  * Coloque esse bloco em `values.yaml`/`kustomization.yaml` dos gateways e sidecars de bancos, **sem flags opcionais** que desliguem o KEDA.
  * `ScaledJob` pode ser usado para jobs de manutenção (rebalanceamento/backup) disparados por fila ou métrica de backlog.

---

## 4. Como fazer (comandos)

> Todos os passos abaixo assumem que você está dentro do repositório `appgear-gitops-core` e que a aplicação será reconciliada via Argo CD (GitOps). 

---

### 1. Estrutura GitOps do Módulo 04

```bash
cd appgear-gitops-core

mkdir -p apps/core/{ceph,postgres,postgres/overlays/postgis,redis,qdrant,rabbitmq,redpanda,backup,data-brokers}
```

---

### 2. Ceph – Storage unificado com VolumeSnapshotClass

#### 2.1 Namespace e Kustomization

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
    appgear.io/module: "mod04-storage-databases-core"
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
    appgear.io/module: "mod04-storage-databases-core"
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
    appgear.io/module: "mod04-storage-databases-core"
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
  storage:
    useAllNodes: true
    useAllDevices: true
    config:
      databaseSizeMB: "2048"
      journalSizeMB: "1024"
EOF
```

#### 2.4 StorageClasses (bloco, filesystem, objeto) com labels FinOps

Exemplo `storageclass-block.yaml`:

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
    appgear.io/module: "mod04-storage-databases-core"
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

`storageclass-filesystem.yaml` e `storageclass-object.yaml` seguem a mesma lógica de labels/annotations.

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
    appgear.io/module: "mod04-storage-databases-core"
driver: rook-ceph.rbd.csi.ceph.com
deletionPolicy: Retain
parameters:
  clusterID: rook-ceph
  pool: replicapool
EOF
```

---

### 3. Postgres (Core) + Overlay PostGIS

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

#### 3.2 ConfigMap do Postgres

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
    appgear.io/module: "mod04-storage-databases-core"
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

#### 3.3 StatefulSet Postgres (resources + mTLS STRICT + backup)

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
    appgear.io/module: "mod04-storage-databases-core"
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

#### 3.4 Service Postgres

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
    appgear.io/module: "mod04-storage-databases-core"
spec:
  selector:
    app.kubernetes.io/name: core-postgres
  ports:
    - name: postgres
      port: 5432
      targetPort: postgres
EOF
```

#### 3.5 Overlay PostGIS

```bash
mkdir -p apps/core/postgres/overlays/postgis

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

`apps/core/redis/kustomization.yaml`:

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

StatefulSet:

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
    appgear.io/module: "mod04-storage-databases-core"
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

Service segue o padrão de labels e porta 6379.

---

### 5. Qdrant (Vetor DB – RAG)

`apps/core/qdrant/statefulset.yaml`:

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
    appgear.io/module: "mod04-storage-databases-core"
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

Service: porta 6333/6334, mesmas labels.

---

### 6. RabbitMQ (Task Broker)

`apps/core/rabbitmq/statefulset.yaml`:

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
    appgear.io/module: "mod04-storage-databases-core"
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

Service: porta 5672/15672, mesmas labels.

---

### 7. Redpanda (Streaming – Kafka-compatible)

`apps/core/redpanda/statefulset.yaml`:

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
    appgear.io/module: "mod04-storage-databases-core"
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

Service: porta 9092/9644, mesmas labels.

---

### 8. Backups (CronJob Postgres + VolumeSnapshots)

#### 8.1 Kustomization de backup

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

#### 8.2 CronJob – backup lógico Postgres → S3 Ceph

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
    appgear.io/module: "mod04-storage-databases-core"
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

#### 8.3 VolumeSnapshots Core

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
    appgear.io/module: "mod04-storage-databases-core"
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
    appgear.io/module: "mod04-storage-databases-core"
spec:
  volumeSnapshotClassName: ceph-rbd-snapclass
  source:
    persistentVolumeClaimName: data-core-qdrant-0
EOF
```

---

### 9. Agregador `core-data-brokers` + Application Argo CD

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
    appgear.io/module: "mod04-storage-databases-core"
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

Commit, push e sync:

```bash
git add apps/core clusters/ag-br-core-dev/apps-core.yaml
git commit -m "mod04 v0.1: storage/bancos core com FinOps (tenant-id) e resources"
git push origin main

argocd app sync core-data-brokers
argocd app get core-data-brokers
```

---

### 10. Topologia A – Docker/Legacy (apenas testes)

Para desenvolvimento local (não produção):

* Utilizar `/opt/appgear` como raiz:

  ```bash
  sudo mkdir -p /opt/appgear/data/{postgres,redis,qdrant,rabbitmq,redpanda}
  sudo chown -R $USER:$USER /opt/appgear
  touch /opt/appgear/.env
  ```

* `docker-compose.yml` com serviços equivalentes (Postgres, Redis, Qdrant, RabbitMQ, Redpanda), usando volumes locais e limites de memória básicos.

> Topologia A é apenas para PoC / DEV local; qualquer ambiente com SLA formal usa Topologia B.

---

## 5. Como verificar

1. **Ceph**

   ```bash
   kubectl get ns rook-ceph
   kubectl get pods -n rook-ceph
   kubectl get storageclass
   kubectl get volumesnapshotclass
   ```

   Verificar:

   * `ceph-block` como StorageClass default.
   * `ceph-rbd-snapclass` presente.

2. **Labels FinOps (`appgear.io/tenant-id`)**

   ```bash
   kubectl get statefulset -n appgear-core -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.metadata.labels.appgear\.io/tenant-id}{"\n"}{end}'

   kubectl get pvc -n appgear-core -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.metadata.labels.appgear\.io/tenant-id}{"\n"}{end}'
   ```

   Esperado: todos com `global`.

3. **Resources (requests/limits) preenchidos**

   ```bash
   kubectl get pod -n appgear-core core-postgres-0 -o jsonpath='{.spec.containers[0].resources}'
   kubectl get pod -n appgear-core core-qdrant-0 -o jsonpath='{.spec.containers[0].resources}'
   kubectl get pod -n appgear-core core-redpanda-0 -o jsonpath='{.spec.containers[0].resources}'
   kubectl get pod -n appgear-core core-redis-0 -o jsonpath='{.spec.containers[0].resources}'
   kubectl get pod -n appgear-core core-rabbitmq-0 -o jsonpath='{.spec.containers[0].resources}'
   ```

   Esperado: blocos `requests` e `limits` presentes.

4. **mTLS STRICT (Istio) ativo nos pods core**

   ```bash
   kubectl get pods -n appgear-core -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.metadata.annotations.sidecar\.istio\.io/inject}{"\n"}{end}'
   ```

   Esperado: `true` para pods de bancos/brokers.

5. **Backups**

   * CronJob:

     ```bash
     kubectl get cronjob -n appgear-core | grep core-postgres-backup
     ```

   * VolumeSnapshots:

     ```bash
     kubectl get volumesnapshot -n appgear-core
     ```

   * Logs de execução de backup (job):

     ```bash
     kubectl get jobs -n appgear-core | grep core-postgres-backup
     ```

---

## 6. Erros comuns

1. **Esquecer `appgear.io/tenant-id: global` em manifests Core**

   * Efeito: custos de storage/compute aparecem como “Unallocated” em OpenCost/Lago.
   * Mitigação: tratar a label como obrigatória em **StatefulSets, PVCs, VolumeSnapshots e Services** Core.

2. **Faltam `resources` em bancos/brokers**

   * Efeito: pods críticos competem por recursos com workloads de negócio; risco de OOMKill/eviction.
   * Mitigação: sempre definir `requests` e `limits` e ajustá-los conforme perfil, sem remover o bloco.

3. **Aplicar YAML direto com `kubectl apply`**

   * Efeito: divergência com GitOps (Argo CD marca `core-data-brokers` como `OutOfSync`).
   * Mitigação: alterar apenas via Git → commit → push → sync Argo CD.

4. **Snapshot-controller ausente**

   * Efeito: recursos `VolumeSnapshot` não funcionam.
   * Mitigação: instalar CRDs de snapshot e controller antes de aplicar manifests de snapshots.

5. **Ceph sem criptografia em repouso**

   * Efeito: não conformidade com requisitos de segurança/DR do Contrato v0.
   * Mitigação: alinhar com a equipe de infraestrutura para garantir OSDs/pools encriptados.

6. **Uso indevido da Topologia A em ambientes de produção**

   * Efeito: ausência de HA, ausência de mecanismos nativos de backup/snapshot, maior risco operacional.
   * Mitigação: restringir formalmente Topologia A a DEV/PoC.

---

## 7. Onde salvar

* **Documento de governança deste módulo**

  * Repositório recomendado: `appgear-docs` ou `appgear-contracts`.
  * Arquivo sugerido:

    * `docs/architecture/Modulo 04 - Armazenamento e Bancos Core v0.1.md`
      ou
    * `desenvolvimento/Módulo 04 - Armazenamento e Bancos Core v0.1.md`.

* **Manifests GitOps (Topologia B)**

  * Repositório: `appgear-gitops-core`.
  * Estrutura:

    ```text
    apps/core/ceph/
      namespace.yaml
      rook-operator.yaml
      ceph-cluster.yaml
      storageclass-block.yaml
      storageclass-filesystem.yaml
      storageclass-object.yaml
      volumesnapshotclass-rbd.yaml
      kustomization.yaml

    apps/core/postgres/
      configmap-postgresql.yaml
      statefulset.yaml
      service.yaml
      kustomization.yaml
      overlays/postgis/kustomization.yaml

    apps/core/redis/
      statefulset.yaml
      service.yaml
      kustomization.yaml

    apps/core/qdrant/
      statefulset.yaml
      service.yaml
      kustomization.yaml

    apps/core/rabbitmq/
      statefulset.yaml
      service.yaml
      kustomization.yaml

    apps/core/redpanda/
      statefulset.yaml
      service.yaml
      kustomization.yaml

    apps/core/backup/
      cronjob-postgres-backup.yaml
      volumesnapshots-core.yaml
      kustomization.yaml

    apps/core/data-brokers/
      kustomization.yaml

    clusters/ag-br-core-dev/apps-core.yaml
      # inclui Application core-data-brokers
    ```

* **Topologia A (DEV/PoC)**

  * Repositório local de infra de desenvolvimento (quando houver).
  * Diretório padrão: `/opt/appgear` com `docker-compose.yml` e `data/...` para testes.

---

## 8. Dependências entre os módulos

A relação deste Módulo 04 com os demais módulos da AppGear deve ser respeitada para garantir uma implantação ordenada e coerente:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Fornece:

    * nomenclatura de clusters (`ag-<regiao>-core-<env>`),
    * labels `appgear.io/*` usadas em todos os manifests (especialmente `tenant-id` e `suite`),
    * regras mínimas de `resources` e tratamento de `.env`,
    * organização de repositórios Git e forma canônica `.md`.

* **Módulo 01 – Bootstrap GitOps e Argo CD**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD instalado, com AppProjects e Applications root,
    * `clusters/<cluster>/apps-core.yaml`, onde este módulo registra o `Application` `core-data-brokers`,
    * acesso Git autenticado e GitOps como mecanismo único de aplicação.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * Istio com mTLS STRICT STRICT para o tráfego entre serviços Core e demais workloads,
    * cadeia de borda que protege acessos externos a APIs que utilizam estes bancos/brokers,
    * contexto de rede para a exposição segura de serviços dependentes de persistência.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Grafana, Loki, OpenCost, Lago)**

  * **Depende diretamente deste módulo** para:

    * coletar métricas e logs de bancos/brokers Core (Postgres, Redis, Qdrant, RabbitMQ, Redpanda),
    * calcular custos de storage/compute destes componentes, usando as labels `appgear.io/tenant-id: global` e demais labels definidas aqui,
    * exibir dashboards de saúde e custo da camada de persistência Core.

* **Módulo 04 – Armazenamento e Bancos Core (este módulo)**

  * Depende de:

    * **M00** (governança, labels, forma canônica),
    * **M01** (GitOps/Argo CD),
    * **M02** (malha/borda),
    * **M03** (para observação/custo, ainda que possa subir antes).
  * Entrega:

    * Ceph (storage default + VolumeSnapshotClass),
    * Postgres (com overlay PostGIS), Redis, Qdrant, RabbitMQ, Redpanda,
    * CronJob de backup lógico e `VolumeSnapshot` Core.

* **Módulo de Segurança / Segredos (Vault, CSI, SSO, etc.) – M05+**

  * **Depende deste módulo** para:

    * definir quais bancos/brokers precisam de segredos (credenciais, S3 backup, etc.),
    * integrar Vault para provisionar Secrets dinâmicos para Postgres e demais componentes.

* **Demais módulos (Suites, Workspaces, PWA, pipelines, RAG, etc.)**

  * Devem:

    * consumir bancos/brokers Core conforme definidos aqui (ex.: Qdrant para RAG, RabbitMQ/Redpanda para filas/streams),
    * respeitar StorageClasses e labels de FinOps deste módulo para manter rastreabilidade de custo e SLA.

Em resumo:

* **M00 → M01 → M02 → M03 → M04 → (Segurança, Suites, Workspaces, RAG, PWA, etc.)**
* Sem Módulo 04, não existe camada de persistência Core padronizada; sem M00–M03, este módulo não é considerado conforme na AppGear.

---

## 9. Metadados
- Gerado automaticamente por CodeGPT
- Versão do módulo: v0.3
- Compatibilidade: full
- Data de geração: 2025-11-24
