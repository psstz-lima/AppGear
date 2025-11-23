Vou reescrever o **Módulo 05** inteiro como **v0.1 em formato Markdown**, já corrigindo:

* Forma canônica (.md, não mais `.py`);
* Inclusão da label **`appgear.io/tenant-id: global`** em todos os recursos críticos;
* Inclusão de **`resources.requests/limits` explícitos** (especialmente para Vault e Falco).

Abaixo está o texto pronto para ser salvo como `Módulo 05 v0.1.md`.

---

# Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA) – v0.1

> Módulo 05 do **1 - Desenvolvimento v0.1**, alinhado ao **0 - Contrato v0**.
> Este módulo define a arquitetura de **Segurança & Segredos** da AppGear, composta por:
>
> * **Vault** como Source of Truth de segredos (SSoT);
> * **OPA (Open Policy Agent)** como Policy-as-Code para pipelines GitOps (Argo Workflows);
> * **Falco** como sensor de Segurança de Runtime em Kubernetes;
> * **OpenFGA** como serviço de Autorização fina (RBAC/ReBAC).
>
> Versão v0.1 corrige as não conformidades do artefato anterior (v0):
>
> * Converte o módulo de **Python (.py)** para **Markdown (.md)**;
> * Adiciona a label **`appgear.io/tenant-id: global`** em todos os Deployments/StatefulSets/DaemonSets/Services core;
> * Define **resources.requests/limits explícitos** para Vault e Falco (e recomenda para todos os componentes de segurança).

---

## O que é

Este módulo define, em formato GitOps, a camada de **Segurança e Segredos** da AppGear:

1. **Vault – Gestão de Segredos e Credenciais Dinâmicas**

   * Serviço `core-vault` no namespace `security`;
   * Storage `raft` em PVC com `storageClassName: ceph-block`;
   * Engines habilitadas:

     * `kv` (KV v2) em `kv/appgear/...`;
     * `database` em `database/creds/postgres-role-*`;
     * `auth/kubernetes` para autenticação de pods;
   * Suporte a injeção via **Vault Agent Sidecar** (Vault Injector) em serviços core e CDEs.

2. **OPA – Policy-as-Code**

   * Serviço `core-opa` no namespace `security`;
   * Políticas Rego para:

     * bloquear segredos estáticos em manifestos;
     * exigir labels `appgear.io/*` (incluindo `appgear.io/tenant-id`);
     * proibir imagens `:latest` em pipelines;
   * Integração v0 via **“Serviço de Validação”** em pipelines Argo Workflows (não Admission Controller ainda).

3. **Falco – Segurança de Runtime**

   * DaemonSet `core-falco` em todos os nós do cluster;
   * Configurado para logar em stdout (coleta via promtail → Loki);
   * Regras para detectar shells interativos, acessos suspeitos etc.;
   * **Resources.requests/limits definidos** para evitar que Falco afete a estabilidade do nó sob carga/ataque.

4. **OpenFGA – Autorização ReBAC**

   * Serviço `core-openfga` no namespace `security`;
   * Datastore Postgres (`core-postgres`, Módulo 04);
   * Credenciais dinâmicas via Vault/Database engine;
   * Ponto central de autorização para Backstage, APIs internas, Suítes.

5. **Governança & FinOps**

   * Todos os recursos core deste módulo (Deployments, StatefulSets, DaemonSets, Services) carregam:

     * `appgear.io/tenant-id: global`;
     * labels padrão de tier/suite/topology/workspace;
   * Isso habilita atribuição de custo no OpenCost/Lago por tenant-id e por componente de segurança.

---

## Por que

1. **Conformidade Contratual**

   * Implementa a **Gestão de Segredos (Vault)** conforme a Seção 4 e 7.A do Contrato;
   * Implementa **Policy-as-Code (OPA)** para pipelines GitOps;
   * Implementa **Runtime Security (Falco)** como camada de detecção;
   * Implementa **Autorização Fina (OpenFGA)** para RBAC/ReBAC.

2. **Observabilidade e FinOps**

   * Sem `appgear.io/tenant-id`, o custo da segurança fica “invisível” no OpenCost;
   * Sem `resources` em Vault/Falco, há risco de saturar nós sob ataque (piorando SLOs);
   * Com labels e resources, conseguimos:

     * Monitorar custo por camada (segurança vs dados vs app);
     * Planejar capacidade e tunar limites com base em métricas.

3. **Interoperabilidade com Módulos 03, 04, 06**

   * M03 (Observabilidade): logs de Vault, OPA, Falco e OpenFGA ficam filtráveis por `tenant-id` e contexto de negócio;
   * M04 (Dados): roles dinâmicas `postgres-role-openfga` completam o ciclo de segredos DB → Vault → OpenFGA;
   * M06 (SSO): Vault armazena `oidc-client-secret` e demais segredos de Keycloak/SSO em `kv/appgear/sso/...`.

---

## Pré-requisitos

### Contratuais e Governança

* **0 - Contrato v0** aprovado;
* **Módulo 00 v0.1** aplicado:

  * Convenções de diretórios GitOps (`apps/core/*`, `clusters/ag-<regiao>-core-<env>` etc.);
  * Labels obrigatórias:

    * `appgear.io/tier`
    * `appgear.io/suite`
    * `appgear.io/topology`
    * `appgear.io/workspace-id`
    * `appgear.io/tenant-id`
  * Convenções de paths de Vault (`kv/appgear/...`, `database/creds/...`).

### Técnicos

* Módulo 01 – GitOps & Argo CD:

  * App-of-Apps funcionando;
  * `apps/core/security/` referenciado em `apps-core.yaml`.
* Módulo 02 – Malha de Serviço:

  * Istio com mTLS STRICT;
  * Traefik + Coraza em produção.
* Módulo 03 – Observabilidade:

  * Loki, Promtail, Grafana funcionais.
* Módulo 04 – Storage & Bancos:

  * Ceph com `ceph-block`;
  * `core-postgres` operante.

### Cluster / Tooling

* Acesso `kubectl`, `kustomize`, `argocd`;
* Cluster `ag-<regiao>-core-<env>` (ex.: `ag-br-core-dev`);
* Namespaces `security`, `observability`, `appgear-core`, `argocd`.

---

## Como fazer (comandos)

### 1. Estrutura de diretórios GitOps

No repositório `appgear-gitops-core`:

```bash
cd appgear-gitops-core

mkdir -p apps/core/security/{vault,opa,falco,openfga}
```

---

### 2. Agregador de Segurança (`apps/core/security`)

#### 2.1 Namespace `security`

`apps/core/security/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: security
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
```

#### 2.2 Kustomization agregadora

`apps/core/security/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: security

resources:
  - namespace.yaml
  - coraza/
  - vault/
  - opa/
  - falco/
  - openfga/
```

---

### 3. Vault – `core-vault` (SSoT de Segredos)

#### 3.1 Kustomization

`apps/core/security/vault/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap-server.yaml
  - statefulset.yaml
  - service.yaml
```

#### 3.2 ConfigMap do servidor Vault

`apps/core/security/vault/configmap-server.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-vault-config
  labels:
    app.kubernetes.io/name: core-vault
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
data:
  server.hcl: |
    ui = true
    disable_mlock = true

    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = 1
    }

    storage "raft" {
      path = "/vault/data"
    }
```

#### 3.3 StatefulSet `core-vault` com resources

`apps/core/security/vault/statefulset.yaml`:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: core-vault
  labels:
    app.kubernetes.io/name: core-vault
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/backup-enabled: "true"
    appgear.io/backup-profile: "core-vault"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  serviceName: core-vault
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: core-vault
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-vault
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
        - name: vault
          image: hashicorp/vault:1.17
          args:
            - "server"
            - "-config=/vault/config/server.hcl"
          ports:
            - containerPort: 8200
              name: http
          resources:
            requests:
              cpu: "500m"
              memory: "2Gi"
            limits:
              cpu: "2"
              memory: "8Gi"
          volumeMounts:
            - name: config
              mountPath: /vault/config
            - name: data
              mountPath: /vault/data
      volumes:
        - name: config
          configMap:
            name: core-vault-config
            items:
              - key: server.hcl
                path: server.hcl
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          appgear.io/backup-enabled: "true"
          appgear.io/backup-profile: "core-vault"
          appgear.io/tenant-id: global
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ceph-block
        resources:
          requests:
            storage: 100Gi
```

#### 3.4 Service `core-vault` com tenant-id

`apps/core/security/vault/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: core-vault
  labels:
    app.kubernetes.io/name: core-vault
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  selector:
    app.kubernetes.io/name: core-vault
  ports:
    - name: http
      port: 8200
      targetPort: http
```

> O job de bootstrap (habilitar `kv`, `database`, `auth/kubernetes`, roles para Postgres etc.) permanece conceitualmente igual ao da versão v0, apenas deve ser migrado para o repositório de infra (não é repetido aqui para evitar duplicidade).

---

### 4. OPA – `core-opa` (Policy-as-Code)

#### 4.1 Kustomization

`apps/core/security/opa/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap-policies.yaml
  - deployment.yaml
  - service.yaml
```

#### 4.2 ConfigMap de políticas (exemplo simplificado)

`apps/core/security/opa/configmap-policies.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-opa-policies
  labels:
    app.kubernetes.io/name: core-opa
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
data:
  policies.rego: |
    package appgear.security

    # Proibir Secret com data inline
    deny[msg] {
      input.kind == "Secret"
      input.apiVersion == "v1"
      some k, v
      v := input.data[k]
      v != ""
      msg := sprintf("Segredo estático não permitido: %v", [input.metadata.name])
    }

    # Exigir labels obrigatórias, incluindo tenant-id
    required_labels := {
      "appgear.io/tier",
      "appgear.io/suite",
      "appgear.io/topology",
      "appgear.io/workspace-id",
      "appgear.io/tenant-id",
    }

    deny[msg] {
      required_labels[l]
      not input.metadata.labels[l]
      msg := sprintf("Label obrigatória ausente: %v", [l])
    }
```

#### 4.3 Deployment `core-opa`

`apps/core/security/opa/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-opa
  labels:
    app.kubernetes.io/name: core-opa
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: core-opa
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-opa
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
        - name: opa
          image: openpolicyagent/opa:0.64.1
          args:
            - "run"
            - "--server"
            - "--addr=0.0.0.0:8181"
            - "/policies/policies.rego"
          ports:
            - containerPort: 8181
              name: http
          volumeMounts:
            - name: policies
              mountPath: /policies
          # resources recomendados (não críticos no diagnóstico)
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"
      volumes:
        - name: policies
          configMap:
            name: core-opa-policies
```

#### 4.4 Service `core-opa`

`apps/core/security/opa/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: core-opa
  labels:
    app.kubernetes.io/name: core-opa
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  selector:
    app.kubernetes.io/name: core-opa
  ports:
    - name: http
      port: 8181
      targetPort: http
```

---

### 5. Falco – `core-falco` (Runtime Security)

#### 5.1 Kustomization

`apps/core/security/falco/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap-falco.yaml
  - daemonset.yaml
```

#### 5.2 ConfigMap `core-falco-config`

`apps/core/security/falco/configmap-falco.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-falco-config
  labels:
    app.kubernetes.io/name: core-falco
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
data:
  falco.yaml: |
    json_output: true
    stdout_output:
      enabled: true
    file_output:
      enabled: false

  rules.yaml: |
    - rule: Unexpected Shell in Container
      desc: Detecta shell interativa em container
      condition: spawned_process and container and shell_procs and not user_known_shell_container
      output: >
        Falco alerta: shell inesperado (user=%user.name container_id=%container.id
        container_name=%container.name cmdline=%proc.cmdline)
      priority: WARNING
      tags: [runtime, shell]
```

#### 5.3 DaemonSet `core-falco` com resources

`apps/core/security/falco/daemonset.yaml`:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: core-falco
  labels:
    app.kubernetes.io/name: core-falco
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "false"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: core-falco
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-falco
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      serviceAccountName: core-falco
      tolerations:
        - operator: "Exists"
      containers:
        - name: falco
          image: falcosecurity/falco:latest
          securityContext:
            privileged: true
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "2Gi"
          volumeMounts:
            - name: dev-fs
              mountPath: /host/dev
            - name: proc-fs
              mountPath: /host/proc
              readOnly: true
            - name: boot-fs
              mountPath: /host/boot
              readOnly: true
            - name: lib-modules
              mountPath: /host/lib/modules
              readOnly: true
            - name: falco-config
              mountPath: /etc/falco
      volumes:
        - name: dev-fs
          hostPath:
            path: /dev
        - name: proc-fs
          hostPath:
            path: /proc
        - name: boot-fs
          hostPath:
            path: /boot
        - name: lib-modules
          hostPath:
            path: /lib/modules
        - name: falco-config
          configMap:
            name: core-falco-config
            items:
              - key: falco.yaml
                path: falco.yaml
              - key: rules.yaml
                path: rules.d/custom-rules.yaml
```

---

### 6. OpenFGA – `core-openfga` (Autorização)

#### 6.1 Kustomization

`apps/core/security/openfga/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap-openfga.yaml
  - deployment.yaml
  - service.yaml
```

#### 6.2 ConfigMap `core-openfga-config`

`apps/core/security/openfga/configmap-openfga.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-openfga-config
  labels:
    app.kubernetes.io/name: core-openfga
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
data:
  OPENFGA_DATASTORE_ENGINE: "postgres"
  OPENFGA_LOG_FORMAT: "json"
  OPENFGA_LOG_LEVEL: "info"
```

#### 6.3 Deployment `core-openfga`

`apps/core/security/openfga/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-openfga
  labels:
    app.kubernetes.io/name: core-openfga
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: core-openfga
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-openfga
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
        - name: openfga
          image: openfga/openfga:v1.7.0
          envFrom:
            - configMapRef:
                name: core-openfga-config
            - secretRef:
                name: core-openfga-db   # criado via Vault/database engine
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"
```

#### 6.4 Service `core-openfga`

`apps/core/security/openfga/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: core-openfga
  labels:
    app.kubernetes.io/name: core-openfga
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  selector:
    app.kubernetes.io/name: core-openfga
  ports:
    - name: http
      port: 8080
      targetPort: http
```

---

### 7. GitOps – Application `core-security` (Argo CD)

No arquivo `clusters/ag-<regiao>-core-<env>/apps-core.yaml`, garantir o Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-security
  namespace: argocd
  labels:
    app.kubernetes.io/name: core-security
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod05-security-secrets"
spec:
  project: appgear-core
  source:
    repoURL: git@github.com:appgear/appgear-gitops-core.git
    targetRevision: main
    path: apps/core/security
  destination:
    server: https://kubernetes.default.svc
    namespace: security
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Como verificar

1. **Sincronismo do Argo CD**

   ```bash
   argocd app sync core-security
   argocd app get core-security
   ```

   * Esperado: `Sync Status: Synced`, `Health: Healthy`.

2. **Recursos no namespace `security`**

   ```bash
   kubectl get deploy,sts,ds,svc -n security
   ```

   * Deve listar:

     * `statefulset/core-vault`
     * `deployment/core-opa`
     * `daemonset/core-falco`
     * `deployment/core-openfga`
     * Services correspondentes.

3. **Labels de FinOps (tenant-id)**

   Verificar se `appgear.io/tenant-id: global` foi aplicada:

   ```bash
   kubectl get deploy core-opa -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}'
   kubectl get sts core-vault -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}'
   kubectl get ds core-falco -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}'
   ```

   * Esperado: `global` em todos.

4. **Resources Vault e Falco**

   ```bash
   kubectl get sts core-vault -n security -o jsonpath='{.spec.template.spec.containers[0].resources}'
   kubectl get ds core-falco -n security -o jsonpath='{.spec.template.spec.containers[0].resources}'
   ```

   * Esperado: `requests` e `limits` definidos.

5. **Vault funcional**

   ```bash
   kubectl port-forward -n security svc/core-vault 8200:8200
   export VAULT_ADDR=http://127.0.0.1:8200
   vault status
   ```

6. **OPA funcional**

   ```bash
   kubectl port-forward -n security svc/core-opa 8181:8181

   curl -s \
     -X POST \
     -H "Content-Type: application/json" \
     --data '{"input":{"apiVersion":"v1","kind":"Secret","metadata":{"name":"segredo-teste","labels":{}},"data":{"senha":"xxx"}}}' \
     http://localhost:8181/v1/data/appgear/security/deny
   ```

   * Esperado: array com mensagens de negação (segredo estático + falta de labels).

7. **Falco logando para Observabilidade**

   ```bash
   kubectl logs -n security daemonset/core-falco | head
   ```

   * Esperado: logs JSON que serão coletados pelo Promtail/Loki.

8. **OpenFGA saudável**

   ```bash
   kubectl port-forward -n security svc/core-openfga 8080:8080
   curl -s http://localhost:8080/healthz
   ```

   * Esperado: status 200/“healthy”.

---

## Erros comuns

1. **Esquecer `appgear.io/tenant-id` em novos manifests**

   * Impacto: custos de segurança não aparecem por tenant no OpenCost;
   * Correção: garantir label no metadata de todos os Deployments/StatefulSets/DaemonSets/Services core.

2. **Não definir resources em Vault/Falco**

   * Impacto: sob ataque, podem exaurir CPU/memória do nó;
   * Correção: manter ou ajustar os `requests/limits` conforme sugerido neste módulo.

3. **Segredos em Git ou ConfigMaps**

   * Impacto: violação direta do contrato e risco de vazamento;
   * Correção: mover tudo para Vault (`kv/appgear` ou `database/creds`) e deixar OPA bloquear manifestos inseguros.

4. **Não integrar OPA aos pipelines**

   * Impacto: políticas não são verificadas antes do deploy;
   * Correção: integrar chamadas a `core-opa` em templates Argo Workflows (validação pré-deploy).

5. **Falco sem permissões de host**

   * Impacto: Falco não consegue inspecionar syscalls;
   * Correção: garantir `privileged: true` e mount de `/dev`, `/proc`, `/lib/modules`, etc.

---

## Onde salvar

* **Nome do arquivo:**
  `Módulo 05 v0.1.md`

* **Local recomendado no repositório de contratos/documentação:**
  `contrato/1 - Desenvolvimento/Módulo 05 v0.1.md`
  (ajustar caminho conforme padrão real do seu monorepo de documentação).

* **Local dos manifests (GitOps):**
  Repositório `appgear-gitops-core/`:

  * `apps/core/security/namespace.yaml`
  * `apps/core/security/kustomization.yaml`
  * `apps/core/security/vault/*`
  * `apps/core/security/opa/*`
  * `apps/core/security/falco/*`
  * `apps/core/security/openfga/*`
  * `clusters/ag-<regiao>-core-<env>/apps-core.yaml` (Application `core-security`).

Com estas alterações, o **Módulo 05 v0.1** fica em **formato canônico (.md)**, com **metadados de FinOps (`tenant-id`) e resources de segurança** definidos, sanando integralmente os pontos levantados no diagnóstico.
