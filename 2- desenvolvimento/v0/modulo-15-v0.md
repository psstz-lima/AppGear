Perfeito, vamos tratar isso como um \*\*retrofit completo\*\* do Módulo 15, já corrigindo todos os pontos do diagnóstico:



\* Formato em \*\*Markdown\*\* (v0.1).

\* \*\*Sem\*\* criação manual de `credentials-velero` em disco.

\* Uso de \*\*Vault / ExternalSecrets\*\* para o Secret `velero-cloud-credentials`.

\* Inclusão de `appgear.io/tenant-id: global` em todos os recursos do Velero.

\* Definição de `resources` no Deployment do Velero.

\* Agendamento específico para \*\*workspaces (`ws-\*`) via label `appgear.io/backup-enabled=true`\*\*.

\* Script de Docker com aviso explícito de uso apenas para Dev/Demo.



Abaixo está o \*\*Módulo 15 v0.1 – Continuidade de Negócios (DR \& Backup Global)\*\* pronto para ser salvo como `Módulo 15 v0.1.md`.



---



\# Módulo 15 v0.1 – Continuidade de Negócios (Disaster Recovery \& Backup Global)



(Disaster Recovery \& Backup Global da Plataforma – Velero, S3 Externo, Workspaces, backup-docker.sh)



---



\## O que é



Este módulo define a \*\*estratégia de Continuidade de Negócios da Plataforma AppGear\*\* (stack da plataforma, não dos dados do cliente) em dois contextos:



1\. \*\*Topologia B (Kubernetes – Produção/Enterprise)\*\*



&nbsp;  \* Instalação e operação do \*\*Velero\*\* no namespace `velero`.

&nbsp;  \* Backup para \*\*Object Storage externo\*\* (S3/GCS/Azure/MinIO fora do cluster).

&nbsp;  \* Snapshots CSI dos volumes PVC (Ceph) via `VolumeSnapshotClass` do \*\*Módulo 04\*\*.

&nbsp;  \* Schedules de backup:



&nbsp;    \* Infraestrutura core (`argocd`, `security`, `appgear-core`, `backstage`, `observability`, `velero`).

&nbsp;    \* Workspaces de clientes (`ws-\*`) selecionados por label `appgear.io/backup-enabled=true`.



2\. \*\*Topologia A (Docker/Legacy – Dev/Demo)\*\*



&nbsp;  \* Script `backup-docker.sh` para \*\*backup simples\*\* de containers e diretórios `data/`.

&nbsp;  \* \*\*Aviso explícito:\*\* este script é apenas para \*\*Dev/Demo\*\* e \*\*não substitui\*\* a estratégia de DR Enterprise com Velero.



---



\## Por que



Sem este módulo, a plataforma está exposta a:



\* \*\*Perda total de cluster\*\* (deleção acidental, desastre físico, falha do provedor).

\* \*\*Perda de identidade e estado core\*\* (Argo CD, Vault, Keycloak, Backstage, N8n etc.).

\* \*\*Perda de workspaces ws-\*\*\* já tratados no Módulo 13, mas sem proteção global.



Este módulo:



1\. \*\*Eleva a AppGear a nível Enterprise/Gov/Bank\*\*



&nbsp;  \* Backups automatizados para storage externo.

&nbsp;  \* Procedimento claro de \*\*Day 0 Restore\*\* em um novo cluster.



2\. \*\*Corrige riscos apontados na auditoria\*\*



&nbsp;  \* Elimina o uso de arquivos manuais de credenciais:



&nbsp;    \* As chaves de S3 são segredos de alto privilégio e agora são geridos \*\*apenas pelo Vault (M05) + ExternalSecrets\*\*.

&nbsp;  \* Garante rastreabilidade de custo (\*\*FinOps\*\*):



&nbsp;    \* Inclusão obrigatória de `appgear.io/tenant-id: global` em todos os recursos Velero.

&nbsp;    \* Permite alocar custos de \*\*storage, egress e API calls do S3\*\* ao “tenant” global da plataforma.

&nbsp;  \* Garante \*\*governança de recursos\*\*:



&nbsp;    \* Requests/limits no pod do Velero para evitar que, durante um backup/restore massivo, ele derrube o cluster.



3\. \*\*Integração com outros módulos\*\*



&nbsp;  \* \*\*M04 – Storage \& Bancos Core\*\*



&nbsp;    \* Usa `VolumeSnapshotClass` (`ceph-rbd-snapclass`) para snapshots dos PVC de Ceph (Vault, Postgres etc.).

&nbsp;  \* \*\*M05 – Segurança \& Segredos\*\*



&nbsp;    \* Usa Vault como SSoT de credenciais S3, via `ClusterSecretStore` + `ExternalSecret`.

&nbsp;  \* \*\*M13 – Workspaces / Backups por Cliente\*\*



&nbsp;    \* M15 foca no \*\*DR da plataforma\*\*; M13 foca no backup \*\*por cliente\*\*.

&nbsp;    \* M15 deve incluir nos backups os namespaces `ws-\*` que tiverem label `appgear.io/backup-enabled=true`.



---



\## Pré-requisitos



\### Contrato / Governança



\* \*\*0 - Contrato v0\*\* em vigor.

\* Diretrizes de auditoria e interoperabilidade (arquivos `2 - Auditoria v0.md` e `3 - Interoperabilidade v0.md`) aplicadas.



\### Módulos já implantados (Topologia B)



\* M00 – Convenções, Repositórios, Nomenclatura.

\* M01 – GitOps (Argo CD, App-of-Apps, ApplicationSets).

\* M02 – Borda \& Malha (Traefik, Coraza, Kong, Istio).

\* M03 – Observabilidade \& FinOps.

\* M04 – Storage \& Bancos Core:



&nbsp; \* Rook-Ceph com `VolumeSnapshotClass` \*\*`ceph-rbd-snapclass`\*\*.

\* M05 – Segurança \& Segredos:



&nbsp; \* Vault acessível via `ClusterSecretStore` (external-secrets.io).

\* M13 – Workspaces e Backups por cliente (para integração de labels em namespaces `ws-\*`).



\### Infraestrutura (Topologia B)



\* Cluster Kubernetes (`ag-<regiao>-core-<env>`) com:



&nbsp; \* CSI + CRDs de `VolumeSnapshot` instalados.

&nbsp; \* `VolumeSnapshotClass` `ceph-rbd-snapclass` (o nome deve coincidir com o usado neste módulo).



\* \*\*Object Storage Externo\*\* configurado, por exemplo:



&nbsp; \* AWS S3, GCS, Azure Blob, ou MinIO \*\*fora do cluster\*\* (VM separada, outro DC ou outro cluster).



\* No Vault (M05), um secret com as credenciais de DR, por exemplo:



&nbsp; \* Path: `kv/appgear/velero/dr-s3`

&nbsp; \* Campos: `cloud` (conteúdo no formato `\[default]` do AWS credentials).



\### Topologia A (Docker / Legacy)



\* Host Linux (Ubuntu LTS) com:



&nbsp; \* Docker + docker-compose.

&nbsp; \* Estrutura `/opt/appgear` com:



&nbsp;   \* `.env` central.

&nbsp;   \* `docker-compose.yml`.

&nbsp;   \* `data/`, `logs/`, `backup/` (ou equivalente).



---



\## Como fazer (comandos)



\### 1. Estrutura GitOps do DR (repositório `appgear-gitops-core`)



```bash

cd appgear-gitops-core



mkdir -p apps/core/dr/schedules

```



`apps/core/dr/kustomization.yaml`:



```yaml

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - namespace.yaml

&nbsp; - velero-deployment.yaml

&nbsp; - backup-locations.yaml

&nbsp; - schedules/backup-core-daily.yaml

&nbsp; - schedules/backup-workspaces-daily.yaml

&nbsp; - schedules/backup-full-weekly.yaml

```



---



\### 2. Namespace Velero com labels FinOps



`apps/core/dr/namespace.yaml`:



```yaml

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

```



---



\### 3. Velero Deployment + RBAC + Resources



`apps/core/dr/velero-deployment.yaml`:



```yaml

apiVersion: v1

kind: ServiceAccount

metadata:

&nbsp; name: velero

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

---

apiVersion: rbac.authorization.k8s.io/v1

kind: ClusterRole

metadata:

&nbsp; name: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

&nbsp;   appgear.io/tenant-id: global

rules:

&nbsp; - apiGroups: \[""]

&nbsp;   resources:

&nbsp;     - namespaces

&nbsp;     - pods

&nbsp;     - pods/log

&nbsp;     - persistentvolumeclaims

&nbsp;     - persistentvolumes

&nbsp;     - secrets

&nbsp;     - configmaps

&nbsp;     - services

&nbsp;     - serviceaccounts

&nbsp;   verbs: \["\*"]

&nbsp; - apiGroups: \["apps"]

&nbsp;   resources:

&nbsp;     - deployments

&nbsp;     - statefulsets

&nbsp;     - daemonsets

&nbsp;     - replicasets

&nbsp;   verbs: \["\*"]

&nbsp; - apiGroups: \["batch"]

&nbsp;   resources:

&nbsp;     - jobs

&nbsp;     - cronjobs

&nbsp;   verbs: \["\*"]

&nbsp; - apiGroups: \["velero.io"]

&nbsp;   resources:

&nbsp;     - backups

&nbsp;     - restores

&nbsp;     - schedules

&nbsp;     - backupstoragelocations

&nbsp;     - volumesnapshotlocations

&nbsp;   verbs: \["\*"]

&nbsp; - apiGroups: \["snapshot.storage.k8s.io"]

&nbsp;   resources:

&nbsp;     - volumesnapshots

&nbsp;     - volumesnapshotcontents

&nbsp;     - volumesnapshotclasses

&nbsp;   verbs: \["\*"]

---

apiVersion: rbac.authorization.k8s.io/v1

kind: ClusterRoleBinding

metadata:

&nbsp; name: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

&nbsp;   appgear.io/tenant-id: global

roleRef:

&nbsp; apiGroup: rbac.authorization.k8s.io

&nbsp; kind: ClusterRole

&nbsp; name: velero

subjects:

&nbsp; - kind: ServiceAccount

&nbsp;   name: velero

&nbsp;   namespace: velero

---

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: velero

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   sidecar.istio.io/inject: "true"

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: velero

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: velero

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: core

&nbsp;       appgear.io/suite: core

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;   spec:

&nbsp;     serviceAccountName: velero

&nbsp;     containers:

&nbsp;       - name: velero

&nbsp;         image: velero/velero:v1.13.0

&nbsp;         imagePullPolicy: IfNotPresent

&nbsp;         command:

&nbsp;           - /velero

&nbsp;         args:

&nbsp;           - server

&nbsp;           - --features=EnableCSI

&nbsp;         env:

&nbsp;           - name: VELERO\_NAMESPACE

&nbsp;             valueFrom:

&nbsp;               fieldRef:

&nbsp;                 fieldPath: metadata.namespace

&nbsp;           - name: AWS\_SHARED\_CREDENTIALS\_FILE

&nbsp;             value: /credentials/cloud

&nbsp;           - name: GOOGLE\_APPLICATION\_CREDENTIALS

&nbsp;             value: /credentials/cloud

&nbsp;           - name: AZURE\_CREDENTIALS\_FILE

&nbsp;             value: /credentials/cloud

&nbsp;         volumeMounts:

&nbsp;           - name: cloud-credentials

&nbsp;             mountPath: /credentials

&nbsp;             readOnly: true

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "500m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

&nbsp;       - name: velero-plugin-for-aws

&nbsp;         image: velero/velero-plugin-for-aws:v1.9.0

&nbsp;         imagePullPolicy: IfNotPresent

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "100m"

&nbsp;             memory: "128Mi"

&nbsp;           limits:

&nbsp;             cpu: "300m"

&nbsp;             memory: "256Mi"

&nbsp;     volumes:

&nbsp;       - name: cloud-credentials

&nbsp;         secret:

&nbsp;           secretName: velero-cloud-credentials

```



> Observação: o segredo `velero-cloud-credentials` \*\*não é criado manualmente\*\*, ele será gerado via `ExternalSecret` (próximo passo).



---



\### 4. BackupStorageLocation + VolumeSnapshotLocation com ExternalSecret (Vault)



`apps/core/dr/backup-locations.yaml`:



```yaml

apiVersion: external-secrets.io/v1beta1

kind: ExternalSecret

metadata:

&nbsp; name: velero-cloud-credentials

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero-cloud-credentials

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; refreshInterval: 1h

&nbsp; secretStoreRef:

&nbsp;   name: appgear-vault              # Definido no Módulo 05 (ClusterSecretStore -> Vault)

&nbsp;   kind: ClusterSecretStore

&nbsp; target:

&nbsp;   name: velero-cloud-credentials

&nbsp;   creationPolicy: Owner

&nbsp; data:

&nbsp;   - secretKey: cloud

&nbsp;     remoteRef:

&nbsp;       key: kv/appgear/velero/dr-s3

&nbsp;       property: cloud

---

apiVersion: velero.io/v1

kind: BackupStorageLocation

metadata:

&nbsp; name: dr-s3-external

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero-bsl

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; provider: aws

&nbsp; objectStorage:

&nbsp;   bucket: ${VELERO\_DR\_S3\_BUCKET}

&nbsp;   prefix: appgear-platform

&nbsp; config:

&nbsp;   region: ${VELERO\_DR\_S3\_REGION}

&nbsp;   s3Url: ${VELERO\_DR\_S3\_ENDPOINT}      # Endpoint S3-compatible (MinIO externo ou S3 público)

&nbsp;   s3ForcePathStyle: "true"

&nbsp; accessMode: ReadWrite

---

apiVersion: velero.io/v1

kind: VolumeSnapshotLocation

metadata:

&nbsp; name: dr-ceph-csi

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero-vsl

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; provider: csi

&nbsp; config:

&nbsp;   snapshot-class: ceph-rbd-snapclass

&nbsp;   driver: rook-ceph.rbd.csi.ceph.com

```



> As variáveis `${VELERO\_DR\_S3\_\*}` podem ser resolvidas via Kustomize/Argo CD ou ConfigMap específico de ambiente.

> As credenciais em si \*\*nunca\*\* aparecem em Git: o Vault entrega o conteúdo de `cloud` no formato `\[default]` direto para o Secret.



---



\### 5. Schedules – Core, Workspaces e Full Weekly



\#### 5.1 Backup diário da infraestrutura core



`apps/core/dr/schedules/backup-core-daily.yaml`:



```yaml

apiVersion: velero.io/v1

kind: Schedule

metadata:

&nbsp; name: core-infra-daily

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero-schedule-core-daily

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; schedule: "0 1 \* \* \*"  # 01:00 AM

&nbsp; template:

&nbsp;   includedNamespaces:

&nbsp;     - argocd

&nbsp;     - security

&nbsp;     - appgear-core

&nbsp;     - backstage

&nbsp;     - observability

&nbsp;     - velero

&nbsp;   excludedResources:

&nbsp;     - events

&nbsp;     - events.events.k8s.io

&nbsp;   storageLocation: dr-s3-external

&nbsp;   volumeSnapshotLocations:

&nbsp;     - dr-ceph-csi

&nbsp;   ttl: 720h   # 30 dias

```



\#### 5.2 Backup diário dos Workspaces (ws-\*)



> Seleção baseada em \*\*label do namespace\*\*: `appgear.io/backup-enabled=true`.

> M13 deve garantir que todo namespace de workspace que precisa de backup receba essa label.



`apps/core/dr/schedules/backup-workspaces-daily.yaml`:



```yaml

apiVersion: velero.io/v1

kind: Schedule

metadata:

&nbsp; name: workspaces-daily

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero-schedule-workspaces-daily

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; schedule: "0 2 \* \* \*"  # 02:00 AM

&nbsp; template:

&nbsp;   includedNamespaces:

&nbsp;     - '\*'     # Seleciona todos, mas aplica labelSelector

&nbsp;   labelSelector:

&nbsp;     matchLabels:

&nbsp;       appgear.io/backup-enabled: "true"

&nbsp;   excludedResources:

&nbsp;     - events

&nbsp;     - events.events.k8s.io

&nbsp;   storageLocation: dr-s3-external

&nbsp;   volumeSnapshotLocations:

&nbsp;     - dr-ceph-csi

&nbsp;   ttl: 336h   # 14 dias

```



\#### 5.3 Backup semanal quase full-cluster



`apps/core/dr/schedules/backup-full-weekly.yaml`:



```yaml

apiVersion: velero.io/v1

kind: Schedule

metadata:

&nbsp; name: cluster-full-weekly

&nbsp; namespace: velero

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: velero-schedule-full-weekly

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; schedule: "0 3 \* \* 0"  # Domingo, 03:00 AM

&nbsp; template:

&nbsp;   includedNamespaces:

&nbsp;     - '\*'

&nbsp;   excludedNamespaces:

&nbsp;     - kube-node-lease

&nbsp;     - kube-public

&nbsp;     - kube-system     # incluir se necessário após testes

&nbsp;     - rook-ceph       # Ceph é infra gerenciada; snapshots dos PVC já cobrem os dados

&nbsp;     - ws-tmp          # exemplo de namespace temporário

&nbsp;   excludedResources:

&nbsp;     - events

&nbsp;     - events.events.k8s.io

&nbsp;     - jobs

&nbsp;     - pods

&nbsp;   storageLocation: dr-s3-external

&nbsp;   volumeSnapshotLocations:

&nbsp;     - dr-ceph-csi

&nbsp;   ttl: 2160h   # 90 dias

```



---



\### 6. Application Argo CD `core-dr` (GitOps)



No arquivo de apps core do cluster (por exemplo `clusters/ag-br-core-dev/apps-core.yaml`), incluir:



```yaml

---

apiVersion: argoproj.io/v1alpha1

kind: Application

metadata:

&nbsp; name: core-dr

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: core-dr

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod15-business-continuity-dr"

spec:

&nbsp; project: default

&nbsp; source:

&nbsp;   repoURL: https://git.example.com/appgear-gitops-core.git

&nbsp;   targetRevision: main

&nbsp;   path: apps/core/dr

&nbsp; destination:

&nbsp;   server: https://kubernetes.default.svc

&nbsp;   namespace: velero

&nbsp; syncPolicy:

&nbsp;   automated:

&nbsp;     prune: true

&nbsp;     selfHeal: true

```



Depois:



```bash

git add apps/core/dr clusters/ag-br-core-dev/apps-core.yaml

git commit -m "mod15 v0.1: DR \& Backup Global (Velero + Vault + Workspaces)"

git push origin main

```



---



\### 7. Procedimento Day 0 Restore (Kubernetes)



Fluxo padrão para restaurar a plataforma em um novo cluster:



1\. \*\*Criar novo cluster\*\* com:



&nbsp;  \* CSI + `VolumeSnapshotClass` `ceph-rbd-snapclass` alinhado ao M04.



2\. \*\*Aplicar base GitOps:\*\*



&nbsp;  \* M00–M04 (infra core + storage).

&nbsp;  \* M01 (Argo CD + App-of-Apps).



3\. \*\*Sincronizar Application `core-dr`:\*\*



```bash

argocd app sync core-dr

kubectl get pods -n velero

```



4\. \*\*Listar backups disponíveis:\*\*



```bash

velero backup get -n velero

```



5\. \*\*Restaurar infra core (exemplo):\*\*



```bash

velero restore create restore-core-infra \\

&nbsp; --from-backup core-infra-daily-<timestamp> \\

&nbsp; --namespace-mappings argocd:argocd,security:security,appgear-core:appgear-core,backstage:backstage,observability:observability \\

&nbsp; -n velero

```



6\. \*\*Restaurar workspaces, se necessário:\*\*



```bash

velero restore create restore-workspaces \\

&nbsp; --from-backup workspaces-daily-<timestamp> \\

&nbsp; -n velero

```



7\. \*\*Deixar Argo CD convergir:\*\*



&nbsp;  \* Argo CD vai reconciliar estados dos manifests restaurados com o que está no Git.



---



\### 8. Topologia A – Script de Backup (Dev/Demo)



> \*\*AVISO IMPORTANTE:\*\*

> Este script é apenas para \*\*ambientes Docker/Dev/Demo\*\* (Topologia A).

> Ele \*\*não substitui\*\* a estratégia de DR Enterprise baseada em Velero (Topologia B).



Assumindo `.env` em `/opt/appgear/.env`:



```env

BACKUP\_SAFE\_PATH=/mnt/backup-safe/appgear

POSTGRES\_CONTAINER=appgear-postgres

KEYCLOAK\_CONTAINER=appgear-keycloak

N8N\_CONTAINER=appgear-n8n

DOCKER\_DATA\_DIR=/opt/appgear/data

```



Criar diretório de scripts:



```bash

mkdir -p /opt/appgear/scripts

```



`/opt/appgear/scripts/backup-docker.sh`:



```bash

cat > /opt/appgear/scripts/backup-docker.sh << 'EOF'

\#!/usr/bin/env bash

set -euo pipefail



\# =============================================================================

\# AVISO:

\# Este script é apenas para ambientes Docker/Dev/Demo (Topologia A).

\# Ele NÃO substitui a estratégia de DR Enterprise (Velero + S3 externo).

\# =============================================================================



\# Carrega .env central, se existir

if \[ -f "/opt/appgear/.env" ]; then

&nbsp; # shellcheck disable=SC2046

&nbsp; export $(grep -v '^#' /opt/appgear/.env | xargs -d '\\n')

fi



TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

BACKUP\_DIR="${BACKUP\_SAFE\_PATH:-/opt/appgear/backup}"

ARCHIVE\_NAME="appgear-platform-backup-${TIMESTAMP}.tar.gz"



mkdir -p "${BACKUP\_DIR}"



echo ">> Iniciando backup Docker AppGear em ${TIMESTAMP}"



TMP\_DIR="$(mktemp -d /tmp/appgear-backup-XXXXXX)"



cleanup() {

&nbsp; echo ">> Limpando diretório temporário ${TMP\_DIR}"

&nbsp; rm -rf "${TMP\_DIR}"

}

trap cleanup EXIT



\# 1. Backup Postgres (pg\_dump)

if \[ -n "${POSTGRES\_CONTAINER:-}" ]; then

&nbsp; echo ">> Fazendo pg\_dump do container ${POSTGRES\_CONTAINER}"

&nbsp; docker exec "${POSTGRES\_CONTAINER}" pg\_dump -U postgres -F c -d postgres > "${TMP\_DIR}/postgres.dump"

fi



\# 2. Backup Keycloak DB (opcional, se separado)

if \[ -n "${KEYCLOAK\_CONTAINER:-}" ]; then

&nbsp; echo ">> Exportando bancos do Keycloak (se aplicável)"

&nbsp; docker exec "${KEYCLOAK\_CONTAINER}" /bin/sh -c 'pg\_dump -U "$KC\_DB\_USERNAME" -F c -d "$KC\_DB\_DATABASE"' > "${TMP\_DIR}/keycloak.dump" || true

fi



\# 3. Backup N8n (se tiver DB próprio)

if \[ -n "${N8N\_CONTAINER:-}" ]; then

&nbsp; echo ">> Exportando metadados do N8n (se aplicável)"

&nbsp; docker exec "${N8N\_CONTAINER}" /bin/sh -c 'pg\_dump -U "$DB\_POSTGRESDB\_USER" -F c -d "$DB\_POSTGRESDB\_DATABASE"' > "${TMP\_DIR}/n8n.dump" || true

fi



\# 4. Compactar diretórios de dados

DATA\_DIR="${DOCKER\_DATA\_DIR:-/opt/appgear/data}"

if \[ -d "${DATA\_DIR}" ]; then

&nbsp; echo ">> Compactando diretório de dados ${DATA\_DIR}"

&nbsp; tar -czf "${TMP\_DIR}/data.tar.gz" -C "${DATA\_DIR}" .

fi



\# 5. Criar artefato final

echo ">> Criando artefato final ${ARCHIVE\_NAME}"

tar -czf "${BACKUP\_DIR}/${ARCHIVE\_NAME}" -C "${TMP\_DIR}" .



echo ">> Backup concluído: ${BACKUP\_DIR}/${ARCHIVE\_NAME}"

EOF



chmod +x /opt/appgear/scripts/backup-docker.sh

```



Agendamento diário (opcional):



```bash

(crontab -l ; echo "0 2 \* \* \* /opt/appgear/scripts/backup-docker.sh >> /opt/appgear/logs/backup.log 2>\&1") | crontab -

```



---



\## Como verificar



\### Topologia B – Velero



1\. \*\*Argo CD – Application `core-dr`\*\*



```bash

argocd app get core-dr

argocd app sync core-dr   # se estiver OutOfSync

```



2\. \*\*Pods do Velero\*\*



```bash

kubectl get ns velero

kubectl get pods -n velero

```



Esperado: 1 pod `velero-xxxxx` em `Running`.



3\. \*\*BSL/VSL\*\*



```bash

kubectl get backupstoragelocation -n velero

kubectl get volumesnapshotlocation -n velero

```



4\. \*\*ExternalSecret e Secret de credenciais\*\*



```bash

kubectl get externalsecret -n velero

kubectl get secret velero-cloud-credentials -n velero

```



5\. \*\*Backup manual de teste\*\*



```bash

velero backup create manual-test \\

&nbsp; --include-namespaces argocd,security,appgear-core,backstage \\

&nbsp; --storage-location dr-s3-external \\

&nbsp; --volume-snapshot-locations dr-ceph-csi \\

&nbsp; -n velero



velero backup describe manual-test -n velero

velero backup logs manual-test -n velero

```



6\. \*\*Verificar objeto no S3 externo\*\*



\* Via CLI ou console do provider:



&nbsp; \* Procurar pelo prefixo `appgear-platform/` e backup `manual-test`.



7\. \*\*Teste de restore de namespace (ex.: `backstage`)\*\*



```bash

kubectl delete ns backstage

velero restore create restore-backstage \\

&nbsp; --from-backup manual-test \\

&nbsp; --include-namespaces backstage \\

&nbsp; -n velero



kubectl get pods -n backstage

```



8\. \*\*Verificar label FinOps\*\*



```bash

kubectl get deployment velero -n velero --show-labels

```



Deve incluir `appgear.io/tenant-id=global`.



\### Topologia A – Script



1\. Executar manualmente:



```bash

/opt/appgear/scripts/backup-docker.sh

```



2\. Conferir artefato:



```bash

ls -lh "${BACKUP\_SAFE\_PATH:-/opt/appgear/backup}"

```



Arquivos `appgear-platform-backup-YYYYMMDD-HHMMSS.tar.gz` devem estar presentes.



---



\## Erros comuns



1\. \*\*Credenciais S3 criadas manualmente em arquivo local\*\*



&nbsp;  \* Risco: vazamento de chave com acesso total aos backups.

&nbsp;  \* Como evitar: sempre usar \*\*Vault + ExternalSecrets\*\* para o `velero-cloud-credentials`.

&nbsp;  \* Sinal de erro: existe arquivo `credentials-velero` em `/home/...` ou Secret criado via `kubectl create secret generic ... --from-file`.



2\. \*\*Ausência de `appgear.io/tenant-id: global`\*\*



&nbsp;  \* Impacto: custos de storage/egress de backup não alocados ao tenant da plataforma.

&nbsp;  \* Como evitar: garantir label em Namespace, Deployment, Schedules, BSL, VSL.



3\. \*\*Falta de resources no Deployment do Velero\*\*



&nbsp;  \* Impacto: em restore/backup massivo, o pod pode consumir CPU/Mem excessivos, causando instabilidade.

&nbsp;  \* Correção: requests/limits conforme especificado (500m/512Mi – 1/1Gi).



4\. \*\*`VolumeSnapshotClass` com nome diferente de `ceph-rbd-snapclass`\*\*



&nbsp;  \* Sintoma: snapshots não são criados; logs do Velero apontam erro de snapshot.

&nbsp;  \* Correção: alinhar nome aqui e no Módulo 04 (`kubectl get volumesnapshotclass`).



5\. \*\*Namespaces `ws-\*` sem label `appgear.io/backup-enabled=true`\*\*



&nbsp;  \* Sintoma: Workspaces não entram no cron de `workspaces-daily`.

&nbsp;  \* Correção: ajustar M13 para aplicar a label em todos os namespaces de workspace que devem ser protegidos.



6\. \*\*Usar script de Docker como “DR oficial”\*\*



&nbsp;  \* Risco: falso senso de segurança em produção.

&nbsp;  \* Correção: deixar claro (documento e comentários) que é \*\*apenas para Dev/Demo\*\*.



---



\## Onde salvar



1\. \*\*Documento do Contrato / Desenvolvimento\*\*



&nbsp;  \* Repositório: `appgear-contracts` (ou equivalente).

&nbsp;  \* Arquivo: `1 - Desenvolvimento v0.md`

&nbsp;  \* Seção: substituir/criar a seção

&nbsp;    \*\*“Módulo 15 v0.1 – Continuidade de Negócios (DR \& Backup Global)”\*\*

&nbsp;    com o conteúdo desta versão.



2\. \*\*GitOps – Topologia B\*\*



&nbsp;  \* Repositório: `appgear-gitops-core`

&nbsp;  \* Pastas/arquivos:



&nbsp;    \* `apps/core/dr/kustomization.yaml`

&nbsp;    \* `apps/core/dr/namespace.yaml`

&nbsp;    \* `apps/core/dr/velero-deployment.yaml`

&nbsp;    \* `apps/core/dr/backup-locations.yaml`

&nbsp;    \* `apps/core/dr/schedules/backup-core-daily.yaml`

&nbsp;    \* `apps/core/dr/schedules/backup-workspaces-daily.yaml`

&nbsp;    \* `apps/core/dr/schedules/backup-full-weekly.yaml`

&nbsp;    \* `clusters/ag-br-core-<env>/apps-core.yaml` (Application `core-dr`).



3\. \*\*Topologia A – Host Docker\*\*



&nbsp;  \* Diretório base: `/opt/appgear`



&nbsp;    \* `.env` com variáveis de backup.

&nbsp;    \* `/opt/appgear/scripts/backup-docker.sh`.

&nbsp;    \* `/opt/appgear/backup/` como destino dos `.tar.gz`.

&nbsp;    \* Crontab opcional para agendamento.



Com estas correções, o \*\*Módulo 15 v0.1\*\* passa a estar \*\*CONFORME\*\* em:



\* Forma canônica (Markdown),

\* Segurança (Vault/ExternalSecrets para credenciais),

\* FinOps (`appgear.io/tenant-id: global`),

\* Governança de recursos (requests/limits),

\* Interoperabilidade com M04, M05 e M13.



