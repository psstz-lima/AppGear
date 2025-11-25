# Módulo 15 – Continuidade de Negócios (DR & Backup Global)

Versão: v0.1

### Premissas padrão (v0.1)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Define a estratégia de backup e disaster recovery da plataforma AppGear.
Usa Velero + storage externo + snapshots CSI para proteger componentes core e workspaces selecionados, com procedimentos de restore Day 0.

---

## O que é

Este módulo define a estratégia de **Continuidade de Negócios da plataforma AppGear** (focada na própria plataforma e vClusters, não nos dados de negócio do cliente) em dois cenários:

1. **Topologia B – Kubernetes (Produção / Enterprise)**

   * Instalação e operação do **Velero** no namespace `velero`.
   * Backup em **Object Storage externo** (S3/GCS/Azure/MinIO fora do cluster).
   * Snapshots CSI dos PVCs (Ceph) via `VolumeSnapshotClass` definido no Módulo 04.
   * Agendamentos de backup para:

     * Infraestrutura core (`argocd`, `security`, `appgear-core`, `backstage`, `observability`, `velero`).
     * Workspaces `ws-*` selecionados por label `appgear.io/backup-enabled=true`.

2. **Topologia A – Docker (Dev / Demo / Legacy)**

   * Script `backup-docker.sh` para backup simples de containers/dados locais.
   * Uso exclusivo para **desenvolvimento/demo**, não substitui a estratégia DR Enterprise com Velero.

---

## Por que

Sem este módulo, a AppGear fica exposta a:

* Perda total do cluster (deleção acidental, desastre físico, falha de provedor).
* Perda da identidade/estado core (Argo CD, Vault, Keycloak, Backstage, N8n, etc.).
* Perda de workspaces `ws-*` já modelados em M13, porém sem proteção centralizada.

Este módulo:

1. **Eleva a plataforma a padrão Enterprise/Gov/Bank**

* Backups automáticos para storage externo.
* Procedimento claro de **Day 0 Restore** em novo cluster.

2. **Corrige riscos apontados na auditoria** 

* Remove a prática de criar arquivos de credenciais em disco para Velero:

  * Credenciais S3 passam a ser geridas exclusivamente via **Vault (M05) + ExternalSecrets**.
* Garante rastreabilidade de custos (FinOps):

  * Label `appgear.io/tenant-id: global` em todos os recursos do Velero.
  * Custos de storage/egress/API do S3 atribuídos ao “tenant” global da plataforma.
* Garante governança de recursos:

  * `resources.requests/limits` no Deployment do Velero, evitando que operações de backup/restore sobrecarreguem o cluster.

3. **Integra-se com outros módulos**

* **M04 – Storage & Bancos Core**:

  * Usa `VolumeSnapshotClass` (ex.: `ceph-rbd-snapclass`) para snapshots de PVCs (Vault, Postgres, etc.).
* **M05 – Segurança & Segredos**:

  * Usa Vault como SSoT das credenciais S3 via `ClusterSecretStore` + `ExternalSecret`.
* **M13 – Workspaces & Backups por Cliente**:

  * M15 cuida do DR global da plataforma; M13 cuida do backup por workspace/tenant.
  * M15 inclui nos schedules os namespaces `ws-*` com `appgear.io/backup-enabled=true`.

---

## Pré-requisitos

### Contrato / Governança

* `0 - Contrato v0.md` em vigor. 
* Diretrizes de:

  * `2 - Auditoria v0.md`;
  * `3 - Interoperabilidade v0.md`;
    aplicadas aos componentes DR.

### Módulos já implantados (Topologia B)

* M00 – Convenções, Repositórios, Nomenclatura.
* M01 – GitOps (Argo CD, App-of-Apps, ApplicationSets).
* M02 – Borda & Malha (Traefik, Coraza, Kong, Istio).
* M03 – Observabilidade & FinOps.
* M04 – Storage & Bancos Core:

  * Rook-Ceph + `VolumeSnapshotClass` (ex.: `ceph-rbd-snapclass`).
* M05 – Segurança & Segredos:

  * Vault acessível via `ClusterSecretStore` (external-secrets.io).
* M13 – Workspaces & vClusters:

  * Namespaces `ws-*` com labels `appgear.io/workspace-id`, `appgear.io/tenant-id`;
  * Convenção para `appgear.io/backup-enabled=true` em workspaces com backup habilitado.

### Infraestrutura (Topologia B – Kubernetes)

* Cluster `ag-<regiao>-core-<env>` com:

  * CSI + CRDs de `VolumeSnapshot` instalados.
  * `VolumeSnapshotClass` alinhada ao M04 (ajustar nome no manifesto deste módulo).
* Object Storage externo configurado:

  * AWS S3, GCS, Azure Blob ou MinIO em ambiente separado do cluster.
* No Vault (M05), secret com credenciais DR:

  * Exemplo:

    * path: `kv/appgear/velero/dr-s3`
    * campo `cloud` contendo credenciais estilo `~/.aws/credentials` (`[default]`).

### Topologia A (Docker / Legacy – apenas Dev/Demo)

* Host Ubuntu LTS com:

  * Docker + docker-compose.
  * Estrutura base em `/opt/appgear`:

    * `.env` central;
    * `docker-compose.yml`;
    * `data/`, `logs/`, `backup/` (ou equivalentes).

---

## Como fazer (comandos)

### Módulo 15.1 – Estrutura GitOps DR no `appgear-gitops-core`

#### O que é

Organizar os manifests de DR (Velero + schedules + ExternalSecret) em um módulo GitOps próprio dentro do repositório `appgear-gitops-core`.

#### Como fazer (comandos)

```bash
cd appgear-gitops-core

mkdir -p apps/core/dr/schedules
```

`apps/core/dr/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - velero-deployment.yaml
  - backup-locations.yaml
  - schedules/backup-core-daily.yaml
  - schedules/backup-workspaces-daily.yaml
  - schedules/backup-full-weekly.yaml
```

---

### Módulo 15.2 – Namespace Velero com labels FinOps

#### O que é

Namespace dedicado para o Velero, já rotulado para FinOps e rastreio de custos.

#### Como fazer (comandos)

`apps/core/dr/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: velero
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
```

---

### Módulo 15.3 – Velero Deployment + RBAC + Resources

#### O que é

Deployment do Velero com:

* ServiceAccount, ClusterRole, ClusterRoleBinding;
* resources requests/limits configurados;
* integração com Secret `velero-cloud-credentials` (gerado por ExternalSecrets).

#### Como fazer (comandos)

`apps/core/dr/velero-deployment.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: velero
  namespace: velero
  labels:
    app.kubernetes.io/name: velero
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: velero
  labels:
    app.kubernetes.io/name: velero
    appgear.io/module: "mod15-business-continuity-dr"
    appgear.io/tenant-id: global
rules:
  - apiGroups: [""]
    resources:
      - namespaces
      - pods
      - pods/log
      - persistentvolumeclaims
      - persistentvolumes
      - secrets
      - configmaps
      - services
      - serviceaccounts
    verbs: ["*"]
  - apiGroups: ["apps"]
    resources:
      - deployments
      - statefulsets
      - daemonsets
      - replicasets
    verbs: ["*"]
  - apiGroups: ["batch"]
    resources:
      - jobs
      - cronjobs
    verbs: ["*"]
  - apiGroups: ["velero.io"]
    resources:
      - backups
      - restores
      - schedules
      - backupstoragelocations
      - volumesnapshotlocations
    verbs: ["*"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources:
      - volumesnapshots
      - volumesnapshotcontents
      - volumesnapshotclasses
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: velero
  labels:
    app.kubernetes.io/name: velero
    appgear.io/module: "mod15-business-continuity-dr"
    appgear.io/tenant-id: global
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: velero
subjects:
  - kind: ServiceAccount
    name: velero
    namespace: velero
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: velero
  namespace: velero
  labels:
    app.kubernetes.io/name: velero
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: velero
  template:
    metadata:
      labels:
        app.kubernetes.io/name: velero
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: velero
      containers:
        - name: velero
          image: velero/velero:v1.13.0
          imagePullPolicy: IfNotPresent
          command:
            - /velero
          args:
            - server
            - --features=EnableCSI
          env:
            - name: VELERO_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: AWS_SHARED_CREDENTIALS_FILE
              value: /credentials/cloud
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /credentials/cloud
            - name: AZURE_CREDENTIALS_FILE
              value: /credentials/cloud
          volumeMounts:
            - name: cloud-credentials
              mountPath: /credentials
              readOnly: true
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
        - name: velero-plugin-for-aws
          image: velero/velero-plugin-for-aws:v1.9.0
          imagePullPolicy: IfNotPresent
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "300m"
              memory: "256Mi"
      volumes:
        - name: cloud-credentials
          secret:
            secretName: velero-cloud-credentials
```

> O Secret `velero-cloud-credentials` **não** é criado manualmente: será gerado via `ExternalSecret`.

---

### Módulo 15.4 – BackupStorageLocation, VolumeSnapshotLocation & ExternalSecret (Vault)

#### O que é

Configuração do destino S3 externo e do `VolumeSnapshotLocation`, além do `ExternalSecret` que converte um secret do Vault em `velero-cloud-credentials`.

#### Como fazer (comandos)

`apps/core/dr/backup-locations.yaml`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: velero-cloud-credentials
  namespace: velero
  labels:
    app.kubernetes.io/name: velero-cloud-credentials
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: appgear-vault               # definido no M05 (ClusterSecretStore -> Vault)
    kind: ClusterSecretStore
  target:
    name: velero-cloud-credentials
    creationPolicy: Owner
  data:
    - secretKey: cloud
      remoteRef:
        key: kv/appgear/velero/dr-s3  # path no Vault
        property: cloud               # campo com conteúdo estilo ~/.aws/credentials
---
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: dr-s3-external
  namespace: velero
  labels:
    app.kubernetes.io/name: velero-bsl
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  provider: aws
  objectStorage:
    bucket: ${VELERO_DR_S3_BUCKET}
    prefix: appgear-platform
  config:
    region: ${VELERO_DR_S3_REGION}
    s3Url: ${VELERO_DR_S3_ENDPOINT}
    s3ForcePathStyle: "true"
  accessMode: ReadWrite
---
apiVersion: velero.io/v1
kind: VolumeSnapshotLocation
metadata:
  name: dr-ceph-csi
  namespace: velero
  labels:
    app.kubernetes.io/name: velero-vsl
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  provider: csi
  config:
    snapshot-class: ceph-rbd-snapclass           # alinhar com M04
    driver: rook-ceph.rbd.csi.ceph.com
```

---

### Módulo 15.5 – Schedules Velero (Core, Workspaces, Full Weekly)

#### O que é

Definição de schedules de backup:

* diário da infraestrutura core;
* diário dos workspaces com backup habilitado;
* semanal full (quase cluster inteiro).

#### Como fazer (comandos)

`apps/core/dr/schedules/backup-core-daily.yaml`:

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: core-infra-daily
  namespace: velero
  labels:
    app.kubernetes.io/name: velero-schedule-core-daily
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  schedule: "0 1 * * *"   # 01:00 AM
  template:
    includedNamespaces:
      - argocd
      - security
      - appgear-core
      - backstage
      - observability
      - velero
    excludedResources:
      - events
      - events.events.k8s.io
    storageLocation: dr-s3-external
    volumeSnapshotLocations:
      - dr-ceph-csi
    ttl: 720h   # 30 dias
```

`apps/core/dr/schedules/backup-workspaces-daily.yaml`:

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: workspaces-daily
  namespace: velero
  labels:
    app.kubernetes.io/name: velero-schedule-workspaces-daily
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  schedule: "0 2 * * *"   # 02:00 AM
  template:
    includedNamespaces:
      - '*'   # todos, filtrados por label
    labelSelector:
      matchLabels:
        appgear.io/backup-enabled: "true"
    excludedResources:
      - events
      - events.events.k8s.io
    storageLocation: dr-s3-external
    volumeSnapshotLocations:
      - dr-ceph-csi
    ttl: 336h   # 14 dias
```

`apps/core/dr/schedules/backup-full-weekly.yaml`:

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: cluster-full-weekly
  namespace: velero
  labels:
    app.kubernetes.io/name: velero-schedule-full-weekly
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  schedule: "0 3 * * 0"   # Domingo, 03:00 AM
  template:
    includedNamespaces:
      - '*'
    excludedNamespaces:
      - kube-node-lease
      - kube-public
      - kube-system        # pode ser incluído após testes
      - rook-ceph          # infra Ceph; dados já cobertos via snapshots de PVC
      - ws-tmp             # exemplo de namespace temporário
    excludedResources:
      - events
      - events.events.k8s.io
      - jobs
      - pods
    storageLocation: dr-s3-external
    volumeSnapshotLocations:
      - dr-ceph-csi
    ttl: 2160h   # 90 dias
```

---

### Módulo 15.6 – Application Argo CD `core-dr` (GitOps)

#### O que é

Aplicação Argo CD que representa o módulo DR/Backup Global dentro do App-of-Apps do cluster.

#### Como fazer (comandos)

No arquivo de apps core do cluster, por exemplo `clusters/ag-br-core-dev/apps-core.yaml`, incluir:

```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-dr
  namespace: argocd
  labels:
    app.kubernetes.io/name: core-dr
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod15-business-continuity-dr"
spec:
  project: default
  source:
    repoURL: https://git.example.com/appgear-gitops-core.git
    targetRevision: main
    path: apps/core/dr
  destination:
    server: https://kubernetes.default.svc
    namespace: velero
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Commit:

```bash
git add apps/core/dr clusters/ag-br-core-dev/apps-core.yaml
git commit -m "mod15 v0.1: DR & Backup Global (Velero + Vault + Workspaces)"
git push origin main
```

---

### Módulo 15.7 – Procedimento Day 0 Restore (Kubernetes)

#### O que é

Fluxo canônico para restaurar a plataforma AppGear em um novo cluster após desastre.

#### Como fazer (comandos)

1. **Criar novo cluster** com:

   * CSI + `VolumeSnapshotClass` (nome alinhado ao M04).

2. **Aplicar base GitOps:**

   * M00–M04 (infra core + storage).
   * M01 (Argo CD + App-of-Apps).

3. **Sincronizar Application `core-dr`:**

```bash
argocd app sync core-dr
kubectl get pods -n velero
```

4. **Listar backups disponíveis:**

```bash
velero backup get -n velero
```

5. **Restaurar infra core (exemplo):**

```bash
velero restore create restore-core-infra \
  --from-backup core-infra-daily-<timestamp> \
  --namespace-mappings argocd:argocd,security:security,appgear-core:appgear-core,backstage:backstage,observability:observability \
  -n velero
```

6. **Restaurar workspaces (se necessário):**

```bash
velero restore create restore-workspaces \
  --from-backup workspaces-daily-<timestamp> \
  -n velero
```

7. **Deixar Argo CD convergir:**

* Argo CD reconciliará o estado restaurado com o que está no Git;
* Ajustes fine-tuning podem ser aplicados via Git.

---

### Módulo 15.8 – Topologia A – Script de Backup Docker (Dev/Demo)

#### O que é

Script de backup para hosts Docker AppGear, usado apenas em ambientes de desenvolvimento/demonstração (Topologia A).

#### Como fazer (comandos)

`.env` em `/opt/appgear/.env` (exemplo):

```env
BACKUP_SAFE_PATH=/mnt/backup-safe/appgear
POSTGRES_CONTAINER=appgear-postgres
KEYCLOAK_CONTAINER=appgear-keycloak
N8N_CONTAINER=appgear-n8n
DOCKER_DATA_DIR=/opt/appgear/data
```

Criar diretório de scripts:

```bash
mkdir -p /opt/appgear/scripts
```

`/opt/appgear/scripts/backup-docker.sh`:

```bash
cat > /opt/appgear/scripts/backup-docker.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AVISO:
# Este script é apenas para ambientes Docker/Dev/Demo (Topologia A).
# Ele NÃO substitui a estratégia de DR Enterprise (Velero + S3 externo).
# =============================================================================

# Carrega .env central, se existir
if [ -f "/opt/appgear/.env" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' /opt/appgear/.env | xargs -d '\n')
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_SAFE_PATH:-/opt/appgear/backup}"
ARCHIVE_NAME="appgear-platform-backup-${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo ">> Iniciando backup Docker AppGear em ${TIMESTAMP}"

TMP_DIR="$(mktemp -d /tmp/appgear-backup-XXXXXX)"

cleanup() {
  echo ">> Limpando diretório temporário ${TMP_DIR}"
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

# 1. Backup Postgres (pg_dump)
if [ -n "${POSTGRES_CONTAINER:-}" ]; then
  echo ">> Fazendo pg_dump do container ${POSTGRES_CONTAINER}"
  docker exec "${POSTGRES_CONTAINER}" pg_dump -U postgres -F c -d postgres > "${TMP_DIR}/postgres.dump"
fi

# 2. Backup Keycloak DB (opcional, se separado)
if [ -n "${KEYCLOAK_CONTAINER:-}" ]; then
  echo ">> Exportando bancos do Keycloak (se aplicável)"
  docker exec "${KEYCLOAK_CONTAINER}" /bin/sh -c 'pg_dump -U "$KC_DB_USERNAME" -F c -d "$KC_DB_DATABASE"' > "${TMP_DIR}/keycloak.dump" || true
fi

# 3. Backup N8n (se tiver DB próprio)
if [ -n "${N8N_CONTAINER:-}" ]; then
  echo ">> Exportando metadados do N8n (se aplicável)"
  docker exec "${N8N_CONTAINER}" /bin/sh -c 'pg_dump -U "$DB_POSTGRESDB_USER" -F c -d "$DB_POSTGRESDB_DATABASE"' > "${TMP_DIR}/n8n.dump" || true
fi

# 4. Compactar diretórios de dados
DATA_DIR="${DOCKER_DATA_DIR:-/opt/appgear/data}"
if [ -d "${DATA_DIR}" ]; then
  echo ">> Compactando diretório de dados ${DATA_DIR}"
  tar -czf "${TMP_DIR}/data.tar.gz" -C "${DATA_DIR}" .
fi

# 5. Criar artefato final
echo ">> Criando artefato final ${ARCHIVE_NAME}"
tar -czf "${BACKUP_DIR}/${ARCHIVE_NAME}" -C "${TMP_DIR}" .

echo ">> Backup concluído: ${BACKUP_DIR}/${ARCHIVE_NAME}"
EOF

chmod +x /opt/appgear/scripts/backup-docker.sh
```

Agendamento diário (opcional):

```bash
(crontab -l ; echo "0 2 * * * /opt/appgear/scripts/backup-docker.sh >> /opt/appgear/logs/backup.log 2>&1") | crontab -
```

---

## Como verificar

### Topologia B – Velero

1. **Argo CD – Application `core-dr`**

```bash
argocd app get core-dr
argocd app sync core-dr   # se OutOfSync
```

2. **Pods do Velero**

```bash
kubectl get ns velero
kubectl get pods -n velero
```

* Esperado: pod `velero-xxxxx` em `Running`.

3. **BackupStorageLocation / VolumeSnapshotLocation**

```bash
kubectl get backupstoragelocation -n velero
kubectl get volumesnapshotlocation -n velero
```

4. **ExternalSecret e Secret de credenciais**

```bash
kubectl get externalsecret -n velero
kubectl get secret velero-cloud-credentials -n velero
```

* `velero-cloud-credentials` deve existir e ter a chave `cloud`.

5. **Backup manual de teste**

```bash
velero backup create manual-test \
  --include-namespaces argocd,security,appgear-core,backstage \
  --storage-location dr-s3-external \
  --volume-snapshot-locations dr-ceph-csi \
  -n velero

velero backup describe manual-test -n velero
velero backup logs manual-test -n velero
```

6. **Verificar objeto no S3 externo**

* Usar CLI/console do provedor para checar bucket `${VELERO_DR_S3_BUCKET}` no prefixo `appgear-platform/`.

7. **Teste de restore de namespace (ex.: `backstage`)**

```bash
kubectl delete ns backstage
velero restore create restore-backstage \
  --from-backup manual-test \
  --include-namespaces backstage \
  -n velero

kubectl get pods -n backstage
```

8. **Verificar labels FinOps**

```bash
kubectl get deployment velero -n velero --show-labels
```

* Deve conter `appgear.io/tenant-id=global`.

### Topologia A – Script Docker

1. Executar manualmente:

```bash
/opt/appgear/scripts/backup-docker.sh
```

2. Conferir artefato:

```bash
ls -lh "${BACKUP_SAFE_PATH:-/opt/appgear/backup}"
```

* Deve encontrar arquivos `appgear-platform-backup-YYYYMMDD-HHMMSS.tar.gz`.

---

## Erros comuns

1. **Criar credenciais S3 manualmente em arquivo local**

* Risco:

  * Vazamento de chaves com acesso total aos backups.
* Correção:

  * Sempre usar **Vault + ExternalSecrets** para `velero-cloud-credentials`.
  * Nunca manter arquivo `credentials-velero` no home do operador.

2. **Ausência de `appgear.io/tenant-id: global`**

* Impacto:

  * Custos de backup (storage/egress) não mapeados ao tenant da plataforma.
* Correção:

  * Garantir label em:

    * Namespace `velero`;
    * Deployment Velero;
    * BSL, VSL, Schedules.

3. **Deployment do Velero sem `resources`**

* Sintoma:

  * Backup/restore massivo degrada o cluster.
* Correção:

  * Manter `requests/limits` como definido;
  * Ajustar conforme tamanho do cluster.

4. **`VolumeSnapshotClass` inconsistente com M04**

* Sintoma:

  * Erros de snapshot nos logs do Velero.
* Correção:

  * Alinhar valor de `snapshot-class` (`ceph-rbd-snapclass`) com o realmente instalado.

5. **Namespaces `ws-*` sem label `appgear.io/backup-enabled=true`**

* Sintoma:

  * Workspaces que deveriam ser protegidos não entram no schedule `workspaces-daily`.
* Correção:

  * Ajustar M13 para garantir label em todos os namespaces que requerem DR.

6. **Uso do script Docker como “DR oficial”**

* Risco:

  * Falso senso de segurança em produção.
* Correção:

  * Deixar claro em documentação e comentários do script que é apenas para **Dev/Demo**, nunca para ambientes Enterprise/Kubernetes.

---

## Onde salvar

1. **Contrato / Desenvolvimento**

* Repositório: `appgear-contracts`.
* Arquivo sugerido:

  * `Módulo 15 – Continuidade de Negócios (DR & Backup Global) v0.1.md`;
* Referenciado em:

  * `1 - Desenvolvimento v0.md`, seção “Módulo 15 – Continuidade de Negócios (DR & Backup Global) – v0.1”.

2. **GitOps – Topologia B (Kubernetes)**

* Repositório: `appgear-gitops-core`.
* Estrutura:

```text
apps/core/dr/
  kustomization.yaml
  namespace.yaml
  velero-deployment.yaml
  backup-locations.yaml
  schedules/
    backup-core-daily.yaml
    backup-workspaces-daily.yaml
    backup-full-weekly.yaml

clusters/ag-<regiao>-core-<env>/
  apps-core.yaml   # Application core-dr
```

3. **Topologia A – Host Docker**

* Diretório base: `/opt/appgear`:

```text
/opt/appgear/.env                # inclui BACKUP_SAFE_PATH, etc.
/opt/appgear/scripts/backup-docker.sh
/opt/appgear/backup/             # destino dos .tar.gz
/opt/appgear/logs/backup.log     # log de execução (se usar cron)
```

---

## Dependências entre os módulos

A posição do **Módulo 15 – Continuidade de Negócios (DR & Backup Global)** dentro da arquitetura AppGear é:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * Pré-requisito direto.
  * Define:

    * forma canônica (`*.md`);
    * nomenclaturas (`core-*`, `addon-*`);
    * labels `appgear.io/*` (incluindo `tenant-id`, `workspace-id`);
    * diretrizes de FinOps aplicadas aos recursos do Velero.

* **Módulo 01 – GitOps e Argo CD (App-of-Apps)**

  * Pré-requisito direto.
  * Fornece:

    * Argo CD como orquestrador;
    * estrutura de `Application` (`core-dr`) que implanta o módulo de DR;
    * fluxo declarativo para implantar/atualizar Velero, BSL, VSL e schedules.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * Pré-requisito funcional.
  * Fornece:

    * Istio com mTLS STRICT protegendo tráfego do Velero dentro do cluster;
    * topologia de rede comum a todos os módulos core.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * Dependência mútua.
  * M03:

    * monitora métricas e logs do Velero;
    * calcula custos de backup (storage/egress/API) a partir das labels.
  * M15:

    * garante labels (`appgear.io/tenant-id=global`, etc.) em todos os recursos de DR;
    * torna custos de DR auditáveis e imputáveis.

* **Módulo 04 – Storage & Bancos Core (Ceph, Postgres, etc.)**

  * Pré-requisito técnico.
  * Fornece:

    * `VolumeSnapshotClass` (ex.: `ceph-rbd-snapclass`) usado pelo `VolumeSnapshotLocation`;
    * PVCs de bancos e componentes core cuja persistência é protegida por snapshots + backups.

* **Módulo 05 – Segurança & Segredos (Vault, OPA, Falco, OpenFGA)**

  * Pré-requisito direto.
  * Fornece:

    * Vault como SSoT de credenciais S3 (via `ClusterSecretStore` + `ExternalSecret`);
    * OPA para validar políticas, se desejado, sobre manifests de DR;
    * Falco para monitorar atividades suspeitas em pods do Velero;
    * OpenFGA para políticas sobre quem pode operar DR/restore.

* **Módulo 06 – Identidade & SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * Pré-requisito funcional.
  * Fornece:

    * identidade/RBAC para times de plataforma que executam restores;
    * papéis específicos (por exemplo “AppGear DR Operator”) integrados a workflows de aprovação.

* **Módulo 07 – Portal Backstage e Integrações Core**

  * Consumidor potencial.
  * Pode expor:

    * painéis de status de backups (via integração com Velero/Prometheus);
    * workflows de solicitação de restore (aprovados por segurança/gestão).

* **Módulo 08 – Serviços Core (LiteLLM, Flowise, N8n, etc.)**

  * Consumidor indireto.
  * Serviços Core:

    * são incluídos nos schedules de backup core (`appgear-core`, N8n, etc.);
    * dependem de M15 para ter DR padronizado e reprodutível.

* **Módulos 09, 10, 11, 12 – Suítes Factory, Brain, Operations, Guardian**

  * Consumidores indiretos.
  * Rodam sobre storage/bancos protegidos por M04 e incluídos nos backups/snapshots:

    * DR de pipelines (Factory),
    * modelos/artefatos (Brain),
    * automações IoT/Edge (Ops),
    * componentes de segurança (Guardian).

* **Módulo 13 – Workspaces, vCluster e modelo por cliente**

  * Dependência funcional direta.
  * Fornece:

    * namespaces e vClusters `ws-*` com labels (`appgear.io/workspace-id`, `tenant-id`);
    * convenção `appgear.io/backup-enabled=true` que M15 usa para selecionar workspaces a serem protegidos no schedule `workspaces-daily`.

* **Módulo 14 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD)**

  * Consumidor indireto.
  * Pipelines AI-First:

    * dependem de ambientes core/workspaces que são protegidos por M15;
    * podem acionar testes de restore em ambientes de staging como parte de cenários de DR automatizados.

* **Módulo 15 – Continuidade de Negócios (DR & Backup Global) – este módulo**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06, M13**;
  * Entrega:

    * a camada de **Disaster Recovery global** da plataforma AppGear, com:

      * backup/snapshot automatizado;
      * restauração reprodutível;
      * credenciais seguras (Vault);
      * rastreio de custos (FinOps);
      * integração com o modelo de Workspaces/vClusters.

Fluxo de dependência simplificado:

**M00 → M01 → M02 → M03 → M04 → M05 → M06 → (M07–M12) → M13 → M14 → M15 → (runbooks avançados de DR, testes automatizados, compliance regulatório)**

Sem o **Módulo 15**, a AppGear teria infraestrutura, workspaces e pipelines, mas **sem uma política unificada e auditável de DR**, deixando a plataforma vulnerável a perda de estado em incidentes graves.
