# Módulo 01 – GitOps e Argo CD (App-of-Apps)

Versão: v0.2

### Atualizações v0.2

- Reforça Argo CD/App-of-Apps com ApplicationSets por workspace/vCluster e annotations Traefik nos Ingresses.


### Premissas padrão (v0.2)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Estabelece o Argo CD como fonte única de verdade operacional.
Define App-of-Apps, AppProjects, Applications e ApplicationSets para instalar/atualizar todos os módulos da AppGear a partir de repositórios Git.. 

---

## O que é

Este módulo define o **bootstrap GitOps da plataforma AppGear na Topologia B (Kubernetes)**, com foco em:

1. **Instalação do Argo CD via manifesto vendorizado**

   * Manifesto oficial pinado por versão (ex.: `v2.11.0`).
   * Patches para:

     * `resources` (CPU/RAM),
     * `liveness/readiness probes`,
     * labels de governança (`appgear.io/*`).

2. **Configuração do acesso Git autenticado do Argo CD**

   * Secret `argocd-repo-cred` com chave SSH dedicada.
   * Criação **imperativa porém declarativa** (pipe `--dry-run=client -o yaml | kubectl apply -f -`).
   * Labels obrigatórias de governança no Secret:

     * `appgear.io/part-of=appgear`
     * `appgear.io/tier=core` (recomendado)
     * `appgear.io/tenant-id=global`.

3. **Tratamento da conta `admin` do Argo CD**

   * Senha representada no Git apenas como **hash bcrypt** dentro do Secret `argocd-secret`.
   * Hash fornecido por processo de segurança (fora deste módulo).
   * `admin.passwordMtime` registrado para rastreio.
   * Política Day 2: rotação ou desativação da conta `admin` após implantação de SSO (Módulo de SSO/SSO+RBAC).

4. **Estrutura GitOps App-of-Apps**

   * `AppProjects`:

     * `appgear-core`       → Stack Core (infra, conectividade, observabilidade, segurança).
     * `appgear-suites`     → Suítes (Factory, Brain, Operations, Guardian).
     * `appgear-workspaces` → Workspaces (Tenant → Workspace → vCluster), com restrição de destino para `ws-*`.
   * `Applications` “root”:

     * `root-core-ag-br-core-dev`   → aponta para `appgear-gitops-core`.
     * `root-suites-ag-br-core-dev` → aponta para `appgear-gitops-suites`.
   * `ApplicationSet`:

     * `workspaces-appset` → gera 1 `Application` por workspace a partir de `appgear-gitops-workspaces` (lista declarativa de workspaces).

5. **Padronização de layout em `/opt/appgear` e `.env` central**

   * Estrutura de diretórios para Git, configs, logs, keys.
   * `.env` como ponto único para caminhos locais e URLs remotas dos repositórios GitOps e versão do Argo CD.

---

## Por que

1. **Atender ao Contrato v0 e ao Módulo 00 (Governança & Topologia)** 

   * Git como **fonte única de verdade** (manifests, policies, bootstrap).
   * Reconciliação contínua orientada por Git (GitOps).
   * Labels padronizadas para FinOps e governança (`appgear.io/tenant-id`, `appgear.io/part-of`, `appgear.io/tier`).

2. **Formalizar o padrão de bootstrap da Topologia B**

   * Evitar instalações “ad hoc” de Argo CD por `kubectl apply` direto em URLs.
   * Garantir que o YAML do Argo CD é uma combinação de:

     * manifesto vendorizado,
     * patches versionados,
     * segredos/configs sob M00 e Módulos de segurança.

3. **Escalabilidade natural via App-of-Apps + ApplicationSet**

   * `AppProjects` separam responsabilidades (Core / Suites / Workspaces).
   * Root Apps (`root-*`) evitam espalhar lógica de bootstrap em múltiplos lugares.
   * `ApplicationSet` de Workspaces permite escalar para dezenas/centenas de tenants sem criar `Applications` manualmente.

4. **Aderência à auditoria de Governança e Segurança**

   * Correção do problema “**Segredo imperativo sem labels**” (Secret `argocd-repo-cred`).
   * Formalização da exceção de segurança para hash do `admin` (bootstrap apenas).
   * Ponto único para demonstrar conformidade com:

     * M00 – Governança (labels e segredos),
     * G04 – Escalabilidade (ApplicationSets),
     * M05 – Segurança (admin/password).

5. **Base para módulos posteriores (SSO, RBAC, Observabilidade, Suites, Workspaces)**

   * Sem Argo CD padronizado, todo o resto da Topologia B fica inconsistente.
   * Este módulo é o “primeiro tijolo” da malha GitOps da plataforma.

---

## Pré-requisitos

### 1. Cluster Kubernetes e permissões

* Cluster Kubernetes ativo em Topologia B, nomeado no padrão:
  `ag-<regiao>-core-<env>` (ex.: `ag-br-core-dev`).
* Usuário com permissão de **`cluster-admin`** ou equivalente.
* Ferramentas instaladas no host ou ambiente de CI:

  * `kubectl`
  * `kustomize` (ou `kubectl kustomize`)
  * `git`
  * `curl`
  * (opcional) `yq` e `jq` para inspeção.

### 2. Estrutura inicial em `/opt/appgear`

```bash
sudo mkdir -p /opt/appgear/{git,config,logs,docs,keys}
sudo chown -R $USER:$USER /opt/appgear
```

Inicializar diretórios de repositórios:

```bash
mkdir -p /opt/appgear/git/\
appgear-infra-bootstrap \
appgear-gitops-core \
appgear-gitops-suites \
appgear-gitops-workspaces
```

### 3. `.env` central (AppGear / GitOps)

Arquivo `/opt/appgear/.env` (não versionado):

```dotenv
APPGEAR_GIT_ROOT=/opt/appgear/git

APPGEAR_INFRA_BOOTSTRAP_LOCAL=${APPGEAR_GIT_ROOT}/appgear-infra-bootstrap
APPGEAR_GITOPS_CORE_LOCAL=${APPGEAR_GIT_ROOT}/appgear-gitops-core
APPGEAR_GITOPS_SUITES_LOCAL=${APPGEAR_GIT_ROOT}/appgear-gitops-suites
APPGEAR_GITOPS_WORKSPACES_LOCAL=${APPGEAR_GIT_ROOT}/appgear-gitops-workspaces

APPGEAR_INFRA_BOOTSTRAP_REMOTE=git@git.example.com:appgear/appgear-infra-bootstrap.git
APPGEAR_GITOPS_CORE_REMOTE=git@git.example.com:appgear/appgear-gitops-core.git
APPGEAR_GITOPS_SUITES_REMOTE=git@git.example.com:appgear/appgear-gitops-suites.git
APPGEAR_GITOPS_WORKSPACES_REMOTE=git@git.example.com:appgear/appgear-gitops-workspaces.git

# Versão pinada do Argo CD
ARGOCD_VERSION=v2.11.0
```

Carregar as variáveis no shell:

```bash
set -a
source /opt/appgear/.env
set +a
```

### 4. Repositórios Git

Exemplo para `infra-bootstrap`:

```bash
cd "${APPGEAR_INFRA_BOOTSTRAP_LOCAL}"
git init

# Opcional: conectar remoto
# git remote add origin "${APPGEAR_INFRA_BOOTSTRAP_REMOTE}"
# git branch -M main
# git push -u origin main
```

Repetir processo para:

* `${APPGEAR_GITOPS_CORE_LOCAL}`
* `${APPGEAR_GITOPS_SUITES_LOCAL}`
* `${APPGEAR_GITOPS_WORKSPACES_LOCAL}`

### 5. Chave SSH dedicada ao Argo CD

Gerar par de chaves:

```bash
ssh-keygen -t ed25519 -C "argocd@appgear" -f /opt/appgear/keys/argocd -N ""
```

Registrar `/opt/appgear/keys/argocd.pub` como **Deploy Key (read-only)** nos repositórios:

* `appgear-infra-bootstrap`
* `appgear-gitops-core`
* `appgear-gitops-suites`
* `appgear-gitops-workspaces`

### 6. Hash bcrypt da senha `admin`

* Gerado por processo interno do time de segurança (fora deste módulo, mas obrigatório).
* O resultado (string bcrypt) será injetado em `argocd-admin-secret.yaml` como `admin.password`.

---

## Como fazer (comandos)

### 1. Vendorizar o manifesto oficial do Argo CD

```bash
cd "${APPGEAR_INFRA_BOOTSTRAP_LOCAL}"
mkdir -p manifests/argocd
```

Baixar o manifesto pinado:

```bash
curl -L \
  "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" \
  -o manifests/argocd/argocd-install-${ARGOCD_VERSION}.yaml
```

Versionar:

```bash
git add manifests/argocd/argocd-install-${ARGOCD_VERSION}.yaml
git commit -m "vendor: Argo CD ${ARGOCD_VERSION}"
```

---

### 2. Adicionar patches de resources, probes e labels

Criar diretório de patches:

```bash
cd "${APPGEAR_INFRA_BOOTSTRAP_LOCAL}"
mkdir -p manifests/argocd/patches
```

#### 2.1 Patch do `argocd-server`

`manifests/argocd/patches/patch-argocd-server-resources.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  template:
    metadata:
      labels:
        appgear.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: argocd-server
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 20
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
```

#### 2.2 Patch do `argocd-repo-server`

`manifests/argocd/patches/patch-argocd-repo-resources.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-repo-server
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  template:
    metadata:
      labels:
        appgear.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: argocd-repo-server
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
```

#### 2.3 Patch do `argocd-application-controller`

`manifests/argocd/patches/patch-argocd-app-controller-resources.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-application-controller
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  template:
    metadata:
      labels:
        appgear.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: argocd-application-controller
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
```

---

### 3. ConfigMap `argocd-cm` com repositórios Git

`manifests/argocd/patches/patch-argocd-cm-repositories.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
data:
  repositories: |
    - url: git@git.example.com:appgear/appgear-infra-bootstrap.git
      name: infra-bootstrap
      type: git
      sshPrivateKeySecret:
        name: argocd-repo-cred
        key: sshPrivateKey

    - url: git@git.example.com:appgear/appgear-gitops-core.git
      name: gitops-core
      type: git
      sshPrivateKeySecret:
        name: argocd-repo-cred
        key: sshPrivateKey

    - url: git@git.example.com:appgear/appgear-gitops-suites.git
      name: gitops-suites
      type: git
      sshPrivateKeySecret:
        name: argocd-repo-cred
        key: sshPrivateKey

    - url: git@git.example.com:appgear/appgear-gitops-workspaces.git
      name: gitops-workspaces
      type: git
      sshPrivateKeySecret:
        name: argocd-repo-cred
        key: sshPrivateKey
```

---

### 4. Secret `argocd-secret` com hash bcrypt do `admin`

`manifests/argocd/argocd-admin-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-secret
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
type: Opaque
stringData:
  admin.password: "<HASH_BCRYPT_ADMIN>"
  admin.passwordMtime: "2025-11-20T00:00:00Z"
```

> `<HASH_BCRYPT_ADMIN>` deve ser substituído pelo valor fornecido pelo time de segurança.

---

### 5. `kustomization.yaml` do Argo CD

`manifests/argocd/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: argocd

resources:
  - argocd-install-v2.11.0.yaml
  - argocd-admin-secret.yaml

patches:
  - path: patches/patch-argocd-server-resources.yaml
  - path: patches/patch-argocd-repo-resources.yaml
  - path: patches/patch-argocd-app-controller-resources.yaml
  - path: patches/patch-argocd-cm-repositories.yaml
```

Aplicar no cluster:

```bash
kubectl create namespace argocd || true

kubectl apply -k manifests/argocd
```

---

### 6. Secret `argocd-repo-cred` (imperativo com labels de Governança)

> Ponto crítico de Governança que corrige o problema “Segredo imperativo sem labels”.

Criar o Secret com labels:

```bash
kubectl -n argocd create secret generic argocd-repo-cred \
  --from-file=sshPrivateKey=/opt/appgear/keys/argocd \
  --type=Opaque \
  --labels="appgear.io/part-of=appgear,appgear.io/tier=core,appgear.io/tenant-id=global" \
  --dry-run=client -o yaml | kubectl apply -f -
```

* Usa `--dry-run=client` + `kubectl apply` para idempotência.
* Garante que o Secret respeita M00 (governança, tenant-id, part-of, tier).

---

### 7. AppProjects (Core, Suites, Workspaces)

Criar diretório:

```bash
mkdir -p "${APPGEAR_INFRA_BOOTSTRAP_LOCAL}/clusters/ag-br-core-dev/projects"
```

`clusters/ag-br-core-dev/projects/appgear-core.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: appgear-core
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  description: "Stack Core (infraestrutura base da plataforma AppGear)"
  sourceRepos:
    - '*'
  destinations:
    - namespace: '*'
      server: 'https://kubernetes.default.svc'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
```

`clusters/ag-br-core-dev/projects/appgear-suites.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: appgear-suites
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  description: "Suítes (Factory, Brain, Operations, Guardian)"
  sourceRepos:
    - '*'
  destinations:
    - namespace: '*'
      server: 'https://kubernetes.default.svc'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
```

`clusters/ag-br-core-dev/projects/appgear-workspaces.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: appgear-workspaces
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  description: "Workspaces (Tenant > Workspace > vCluster)"
  sourceRepos:
    - '*'
  destinations:
    - namespace: 'ws-*'
      server: 'https://kubernetes.default.svc'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
```

Aplicar:

```bash
cd "${APPGEAR_INFRA_BOOTSTRAP_LOCAL}"
kubectl apply -f clusters/ag-br-core-dev/projects/
```

---

### 8. Root Applications (Core e Suites)

Criar diretório:

```bash
mkdir -p "${APPGEAR_INFRA_BOOTSTRAP_LOCAL}/clusters/ag-br-core-dev/apps"
```

`clusters/ag-br-core-dev/apps/root-core-ag-br-core-dev.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-core-ag-br-core-dev
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  project: appgear-core
  source:
    repoURL: git@git.example.com:appgear/appgear-gitops-core.git
    targetRevision: main
    path: clusters/ag-br-core-dev
  destination:
    server: https://kubernetes.default.svc
    namespace: appgear-core
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

`clusters/ag-br-core-dev/apps/root-suites-ag-br-core-dev.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-suites-ag-br-core-dev
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  project: appgear-suites
  source:
    repoURL: git@git.example.com:appgear/appgear-gitops-suites.git
    targetRevision: main
    path: clusters/ag-br-core-dev
  destination:
    server: https://kubernetes.default.svc
    namespace: appgear-core
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Aplicar:

```bash
kubectl apply -f clusters/ag-br-core-dev/apps/
```

---

### 9. ApplicationSet de Workspaces

```bash
mkdir -p "${APPGEAR_INFRA_BOOTSTRAP_LOCAL}/clusters/ag-br-core-dev/applicationsets"
```

`clusters/ag-br-core-dev/applicationsets/workspaces-appset.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: workspaces-appset
  namespace: argocd
  labels:
    appgear.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  generators:
    - list:
        elements:
          - workspaceId: "acme-erp"
          - workspaceId: "acme-crm"
          # novos workspaces são adicionados aqui
  template:
    metadata:
      name: "ws-{{workspaceId}}"
      labels:
        appgear.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/tenant-id: global
        appgear.io/workspace-id: "{{workspaceId}}"
    spec:
      project: appgear-workspaces
      source:
        repoURL: git@git.example.com:appgear/appgear-gitops-workspaces.git
        targetRevision: main
        path: workspaces/{{workspaceId}}
      destination:
        server: https://kubernetes.default.svc
        namespace: "ws-{{workspaceId}}-core"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

Aplicar:

```bash
kubectl apply -f clusters/ag-br-core-dev/applicationsets/workspaces-appset.yaml
```

---

## Como verificar

1. **Namespace `argocd` e pods do Argo CD**

   ```bash
   kubectl get ns argocd
   kubectl -n argocd get pods
   ```

   Esperado: pods `argocd-server`, `argocd-repo-server`, `argocd-application-controller` em `Running`.

2. **Secret `argocd-repo-cred` com labels de governança**

   ```bash
   kubectl -n argocd get secret argocd-repo-cred -o jsonpath='{.metadata.labels}'
   echo
   ```

   Esperado conter:

   * `appgear.io/part-of=appgear`
   * `appgear.io/tier=core`
   * `appgear.io/tenant-id=global`

3. **ConfigMap `argocd-cm` com repositórios cadastrados**

   ```bash
   kubectl -n argocd get configmap argocd-cm -o yaml | yq '.data.repositories'
   ```

   Verificar URLs para:

   * `appgear-infra-bootstrap`
   * `appgear-gitops-core`
   * `appgear-gitops-suites`
   * `appgear-gitops-workspaces`.

4. **Secret `argocd-secret` com hash bcrypt**

   ```bash
   kubectl -n argocd get secret argocd-secret -o yaml | yq '.stringData.admin.password'
   ```

   Esperado: valor não legível em texto plano (hash bcrypt).

5. **AppProjects aplicados**

   ```bash
   kubectl -n argocd get appprojects
   ```

   Esperado: `appgear-core`, `appgear-suites`, `appgear-workspaces`.

6. **Root Apps e ApplicationSet**

   ```bash
   kubectl -n argocd get applications
   kubectl -n argocd get applicationsets
   ```

   Esperado:

   * Applications: `root-core-ag-br-core-dev`, `root-suites-ag-br-core-dev`.
   * ApplicationSet: `workspaces-appset`.

   Após sincronização: `Applications` gerados para cada workspace (`ws-acme-erp`, etc.).

7. **Argo CD Web UI acessível**

   * Verificar o endereço exposto (via Ingress/Traefik, conforme módulo de exposição).
   * Fazer login com usuário `admin` + senha correspondente ao hash configurado (conforme processo interno).

---

## Erros comuns

* **Criar o Secret `argocd-repo-cred` sem labels**
  Resultado: objeto “órfão” do ponto de vista de auditoria de Governança.
  Correção:

  ```bash
  kubectl -n argocd delete secret argocd-repo-cred

  kubectl -n argocd create secret generic argocd-repo-cred \
    --from-file=sshPrivateKey=/opt/appgear/keys/argocd \
    --type=Opaque \
    --labels="appgear.io/part-of=appgear,appgear.io/tier=core,appgear.io/tenant-id=global" \
    --dry-run=client -o yaml | kubectl apply -f -
  ```

* **Esquecer de atualizar o `ARGOCD_VERSION` no `.env` e no nome do manifesto vendorizado**
  Resultado: divergência entre valor declarado e arquivo real (`argocd-install-v2.xx.yy.yaml`).

* **Não aplicar o `kustomization.yaml` (aplicar o `install.yaml` cru)**
  Resultado: Argo CD sobe sem patches de resources, probes e labels.

* **Registrar chave SSH do Argo CD com permissão de escrita nos repositórios**
  Resultado: risco de alteração acidental de manifests via pipeline.
  Correção: sempre registrar como Deploy Key read-only.

* **Deixar o hash bcrypt de `admin` apontando para senha padrão fraca ou conhecida**
  Resultado: risco de comprometimento do painel Argo CD.
  Correção: garantir processo de geração e rotação regulamentado no Módulo de Segurança (M05/SSO).

* **Não sincronizar Root Apps após bootstrap**
  Resultado: Argo CD sobe, mas nada mais é sincronizado (Core, Suites, Workspaces não são aplicados).

---

## Onde salvar

* **Documento deste módulo (governança):**
  Repositório: `appgear-docs` ou `appgear-contracts` (conforme organização de contrato)
  Arquivo sugerido:
  `docs/architecture/Modulo 01 - Bootstrap GitOps e Argo CD v0.md`
  ou
  `1 - Desenvolvimento v0/Módulo 01 - Bootstrap GitOps e Argo CD v0.md`

* **Manifests de bootstrap Argo CD:**
  Repositório: `appgear-infra-bootstrap`
  Caminhos:

  * `manifests/argocd/argocd-install-v2.11.0.yaml`
  * `manifests/argocd/kustomization.yaml`
  * `manifests/argocd/patches/*.yaml`
  * `manifests/argocd/argocd-admin-secret.yaml`
  * `clusters/ag-br-core-dev/projects/*.yaml`
  * `clusters/ag-br-core-dev/apps/*.yaml`
  * `clusters/ag-br-core-dev/applicationsets/workspaces-appset.yaml`

Este módulo passa a ser a referência única para qualquer bootstrap GitOps da Topologia B com Argo CD na plataforma AppGear.

---

## Dependências entre os módulos

A relação deste módulo com os demais deve ser respeitada para garantir implantação ordenada:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * É pré-requisito direto deste módulo.
  * Define:

    * nomenclatura de clusters (`ag-<regiao>-core-<env>`),
    * convenções de labels `appgear.io/*`,
    * padrões de documentação (`.md`) e organização de repositórios,
    * regras mínimas de `resources`, probes e tratamento de `.env`.

* **Módulo 01 – Bootstrap GitOps e Argo CD (este módulo)**

  * Depende de:

    * **Módulo 00** para nomes, labels, repositórios e regras de governança.
  * Entrega:

    * Argo CD instalado e padronizado na Topologia B,
    * AppProjects (`appgear-core`, `appgear-suites`, `appgear-workspaces`),
    * Applications root (`root-core-*`, `root-suites-*`),
    * ApplicationSet de Workspaces.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Depende do Módulo 01** para:

    * ser sincronizado via Argo CD (App-of-Apps Core),
    * utilizar os AppProjects `appgear-core` e `appgear-suites`.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Grafana, Loki, OpenCost, Lago)**

  * **Depende do Módulo 01** para:

    * implantação GitOps (Application `core-observability` ou similar) dentro de `appgear-core`,
    * reaproveitar labels e estrutura de projetos configurados aqui.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, RabbitMQ, Redpanda)**

  * **Depende do Módulo 01** para:

    * implantação via Argo CD (Application `core-data-brokers` ou equivalente),
    * uso dos AppProjects e labels de governança estabelecidos neste módulo.

* **Demais módulos (SSO, Segurança/Segredos, Suites, Workspaces, PWA, etc.)**

  * Devem assumir:

    * Argo CD como orquestrador GitOps já presente (por este módulo),
    * AppProjects, Applications root e ApplicationSet de Workspaces já implantados,
    * convenções de repositórios Git, caminhos locais e acesso SSH estabelecidos aqui.

Em resumo: **Módulo 00 → Módulo 01 → demais módulos**.
Sem Módulo 01 implementado, nenhum módulo GitOps da Topologia B AppGear deve ser considerado “em produção” ou “conforme”.
