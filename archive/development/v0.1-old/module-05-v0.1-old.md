# Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)

Versão: v0.1

### Premissas padrão (v0.1)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Define o modelo de segurança infra: segredos, políticas, auditoria e detecção.
Inclui Vault como SSoT de segredos, OPA para políticas, Falco para detecção de intrusão e OpenFGA/ReBAC para autorização fina. 

---

## O que é

Este módulo define, em formato GitOps e em documento canônico `.md`, a camada de **Segurança e Segredos** da plataforma **AppGear**, composta por:

1. **Vault – Source of Truth de Segredos (SSoT)**

   * Serviço `core-vault` no namespace `security`.
   * Storage `raft` sobre PVC com `storageClassName: ceph-block`.
   * Engines habilitadas:

     * `kv` (KV v2) em `kv/appgear/...`;
     * `database` em `database/creds/postgres-role-*`;
     * `auth/kubernetes` para autenticação de pods.
   * Suporte a injeção de segredos via **Vault Agent Sidecar** (Vault Injector) em serviços core e CDEs.

2. **OPA (Open Policy Agent) – Policy-as-Code**

   * Serviço `core-opa` no namespace `security`.
   * Políticas Rego para:

     * bloquear segredos estáticos em manifests;
     * exigir labels `appgear.io/*` (incluindo `appgear.io/tenant-id`);
     * proibir imagens `:latest` em pipelines.
     * rejeitar referências diretas a `api.openai.com` em workloads que não sejam `core-litellm`.
   * Integração v0 via **serviço de validação** em pipelines Argo Workflows (sem Admission Controller ainda).

3. **Falco – Segurança de Runtime**

   * DaemonSet `core-falco` rodando em todos os nós do cluster.
   * Configurado para logar em stdout (coleta via promtail → Loki).
   * Regras para detecção de shell interativo em container e eventos suspeitos.
   * `resources.requests/limits` definidos para que Falco não degrade o nó em situações de ataque.

4. **OpenFGA – Autorização fina (RBAC/ReBAC)**

   * Serviço `core-openfga` no namespace `security`.
   * Datastore Postgres (`core-postgres`, Módulo 04).
   * Credenciais dinâmicas servidas via Vault (engine `database`).
   * Ponto central de autorização fina para Backstage, APIs internas e Suítes.

5. **Governança & FinOps**

   * Todos os recursos core (Deployments, StatefulSets, DaemonSets, Services) deste módulo carregam:

     * `appgear.io/tenant-id: global`;
     * `appgear.io/tier`, `appgear.io/suite`, `appgear.io/topology`, `appgear.io/workspace-id`.
   * Permite que o Módulo 03 (OpenCost/Lago) atribua custo à camada de segurança por tenant e por componente.

---

## Por que

1. **Conformidade com o Contrato v0 e com o plano de Desenvolvimento v0.1** 

   * Implementa **Gestão de Segredos via Vault** (Seções 4 e 7.A do Contrato).
   * Implementa **Policy-as-Code via OPA** para pipelines GitOps (Argo Workflows).
   * Implementa **Segurança de Runtime via Falco**.
   * Implementa **Autorização ReBAC via OpenFGA**.

2. **Segurança + FinOps orientados a tenant**

   * Sem `appgear.io/tenant-id`, os custos de segurança aparecem como “não alocados” em OpenCost/Lago.
   * Sem `resources` em Vault/Falco, há risco de saturar nós exatamente durante incidentes (piorando MTTR).
   * Com labels e resources explícitos:

     * é possível medir custo da camada de segurança;
     * é possível ajustar capacidade com base em métricas.

3. **Integração com demais módulos**

   * M03 (Observabilidade): logs e métricas de Vault, OPA, Falco e OpenFGA ficam filtráveis por `tenant-id` e contexto de negócio.
   * M04 (Armazenamento e Bancos): roles dinâmicas como `postgres-role-openfga` fecham o ciclo segredos DB → Vault → OpenFGA.
   * Módulo de SSO (M06+): Vault armazena `oidc-client-secret` e demais segredos do provedor de identidade em `kv/appgear/sso/...`.

4. **Correções sobre a versão anterior (v0)** 

   * Conversão de `.py` para `.md` seguindo padrão canônico.
   * Inclusão de `appgear.io/tenant-id: global` em todos os componentes core de segurança.
   * Definição explícita de `resources.requests/limits` para Vault e Falco (e recomendação para todos os componentes).

---

## Pré-requisitos

### Contratuais e Governança

* **0 – Contrato v0** aprovado.
* **Módulo 00 v0.1 – Convenções, Repositórios e Nomenclatura**:

  * Convenções de diretórios GitOps (`apps/core/*`, `clusters/ag-<regiao>-core-<env>` etc.).
  * Labels obrigatórias:

    * `appgear.io/tier`
    * `appgear.io/suite`
    * `appgear.io/topology`
    * `appgear.io/workspace-id`
    * `appgear.io/tenant-id`
  * Convenções de paths no Vault: `kv/appgear/...`, `database/creds/...`.

### Técnicos (módulos anteriores)

* **Módulo 01 – GitOps & Argo CD**

  * App-of-Apps funcionando.
  * `apps/core/security/` referenciado em `apps-core.yaml` (Application `core-security`).

* **Módulo 02 – Malha de Serviço e Borda**

  * Istio com `mTLS STRICT` ativo.
  * Cadeia Traefik + Coraza (+ Kong) em produção.

* **Módulo 03 – Observabilidade & FinOps**

  * Loki, Promtail, Grafana, OpenCost/Lago operando.

* **Módulo 04 – Storage & Bancos Core**

  * Ceph com StorageClass `ceph-block` disponível.
  * `core-postgres` disponível para uso pelo OpenFGA.

### Cluster e Ferramentas

* Cluster Kubernetes `ag-<regiao>-core-<env>` (ex.: `ag-br-core-dev`).
* Namespaces existentes ou a criar: `security`, `observability`, `appgear-core`, `argocd`.
* Ferramentas:

  * `kubectl`
  * `kustomize` (ou `kubectl kustomize`)
  * `argocd`
  * `git`.

---

## Como fazer (comandos)

> Todos os manifests abaixo devem ser versionados em Git e aplicados via Argo CD (GitOps). Não é recomendado aplicar diretamente com `kubectl apply` em produção. 

---

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

> A pasta `coraza/` é trazida do Módulo 02 (WAF), mas é mantida aqui como parte do agregador de segurança.

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

#### 3.3 StatefulSet `core-vault` com resources e backup

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

#### 3.4 Service `core-vault`

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

> Jobs de bootstrap (habilitar `kv`, `database`, `auth/kubernetes`, roles para Postgres etc.) devem existir em repositório de automação/infra, não são repetidos aqui para evitar duplicidade.

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

#### 4.2 ConfigMap de políticas Rego

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

    # Permitir openai.com apenas via core-litellm
    litellm_allowed {
      input.metadata.labels["app.kubernetes.io/name"] == "core-litellm"
    }

    litellm_allowed {
      input.spec.template.metadata.labels["app.kubernetes.io/name"] == "core-litellm"
    }

    references_openai(container) {
      some env
      env := container.env[_]
      value := env.value
      contains(lower(value), "api.openai.com")
    }

    references_openai(container) {
      some arg
      arg := container.args[_]
      contains(lower(arg), "api.openai.com")
    }

    references_openai(container) {
      some cmd
      cmd := container.command[_]
      contains(lower(cmd), "api.openai.com")
    }

    containers[container] {
      container := input.spec.template.spec.containers[_]
    }

    containers[container] {
      container := input.spec.template.spec.initContainers[_]
    }

    deny[msg] {
      containers[container]
      references_openai(container)
      not litellm_allowed
      msg := sprintf("Chamada direta a api.openai.com detectada no container %v; usar gateway core-litellm", [container.name])
    }
```

> A política Rego acima trabalha em conjunto com as NetworkPolicies do M02: primeiro impede que o manifest faça referência direta à OpenAI, depois a rede bloqueia qualquer egress que não passe pelo `core-litellm`.

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

### 6. OpenFGA – `core-openfga` (Autorização ReBAC)

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

No arquivo `clusters/ag-<regiao>-core-<env>/apps-core.yaml`, garantir o `Application`:

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

   Deve listar, no mínimo:

   * `statefulset/core-vault`
   * `deployment/core-opa`
   * `daemonset/core-falco`
   * `deployment/core-openfga`
   * Services correspondentes.

3. **Labels de FinOps (`tenant-id`)**

   ```bash
   kubectl get deploy core-opa -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
   kubectl get sts core-vault -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
   kubectl get ds core-falco -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
   kubectl get deploy core-openfga -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
   ```

   * Esperado: `global` em todos.

4. **Resources de Vault e Falco**

   ```bash
   kubectl get sts core-vault -n security -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
   kubectl get ds core-falco -n security -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
   ```

   * Esperado: blocos `requests` e `limits` preenchidos.

5. **Vault funcional**

   ```bash
   kubectl port-forward -n security svc/core-vault 8200:8200
   export VAULT_ADDR=http://127.0.0.1:8200
   vault status
   ```

   * Esperado: status `sealed` ou `initialized` (conforme estágio de bootstrap).

6. **OPA funcional (validação de políticas)**

   ```bash
   kubectl port-forward -n security svc/core-opa 8181:8181

   curl -s \
     -X POST \
     -H "Content-Type: application/json" \
     --data '{"input":{"apiVersion":"v1","kind":"Secret","metadata":{"name":"segredo-teste","labels":{}},"data":{"senha":"xxx"}}}' \
     http://localhost:8181/v1/data/appgear/security/deny
   ```

   * Esperado: array JSON com mensagens de negação (segredo estático + labels obrigatórias ausentes).

7. **Falco logando para observabilidade**

   ```bash
   kubectl logs -n security daemonset/core-falco | head
   ```

   * Esperado: logs em JSON prontos para coleta por Promtail/Loki.

8. **OpenFGA saudável**

   ```bash
   kubectl port-forward -n security svc/core-openfga 8080:8080
   curl -s http://localhost:8080/healthz
   ```

   * Esperado: HTTP 200, indicando serviço saudável.

---

## Erros comuns

1. **Omitir `appgear.io/tenant-id` em manifests de segurança**

   * Impacto: custo da camada de segurança fica “não alocado” em OpenCost/Lago.
   * Correção: garantir a label em todos os `Deployment`, `StatefulSet`, `DaemonSet` e `Service` core deste módulo.

2. **Não definir `resources` em Vault/Falco**

   * Impacto: sob carga ou ataque, podem saturar CPU/memória do nó e afetar workloads de negócio.
   * Correção: manter ou ajustar os `requests/limits` recomendados, nunca remover.

3. **Segredos em Git ou em ConfigMaps**

   * Impacto: violação direta do Contrato v0 e alto risco de vazamento.
   * Correção: mover segredos para Vault (`kv/appgear/...` ou `database/creds/...`) e usar OPA para bloquear manifests que contenham segredos estáticos.

4. **OPA não integrado aos pipelines**

   * Impacto: políticas não são avaliadas antes do deploy; risco de drift de segurança.
   * Correção: integrar chamadas a `core-opa` nos templates de Argo Workflows/CI, validando YAML antes de comitar/aplicar.

5. **Falco sem privilégios ou mounts corretos**

   * Impacto: Falco não consegue inspecionar syscalls; detecção de ameaças é comprometida.
   * Correção: garantir `privileged: true` e mounts de `/dev`, `/proc`, `/lib/modules`, `/boot` conforme definido.

6. **OpenFGA sem segredos via Vault**

   * Impacto: credenciais Postgres de OpenFGA tornam-se estáticas e difíceis de rotacionar.
   * Correção: criar role dinâmica no Vault e Secret `core-openfga-db` provisionado via engine `database`.

---

## Onde salvar

* **Documento deste módulo (governança)**

  * Nome do arquivo:
    `Módulo 05 – Segurança e Segredos v0.1.md`
  * Repositório de contratos/documentação (exemplo):
    `appgear-contracts` ou `appgear-docs`.
  * Caminho sugerido:
    `contrato/1 - Desenvolvimento/Módulo 05 – Segurança e Segredos v0.1.md`

* **Manifests GitOps (Topologia B)**

  * Repositório: `appgear-gitops-core/`.
  * Estrutura:

    ```text
    apps/core/security/
      namespace.yaml
      kustomization.yaml
      vault/
        configmap-server.yaml
        statefulset.yaml
        service.yaml
        kustomization.yaml
      opa/
        configmap-policies.yaml
        deployment.yaml
        service.yaml
        kustomization.yaml
      falco/
        configmap-falco.yaml
        daemonset.yaml
        kustomization.yaml
      openfga/
        configmap-openfga.yaml
        deployment.yaml
        service.yaml
        kustomization.yaml

    clusters/ag-<regiao>-core-<env>/apps-core.yaml
      # inclui Application core-security
    ```

---

## Dependências entre os módulos

A relação deste Módulo 05 com os demais módulos da AppGear deve ser respeitada para garantir implantação ordenada e coerente:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Fornece:

    * padrão de organização de repositórios GitOps (`appgear-gitops-core`),
    * convenções de labels `appgear.io/*` usadas em todos os manifests deste módulo,
    * convenções de paths no Vault (`kv/appgear/...`, `database/creds/...`),
    * forma canônica de documentação `.md`.

* **Módulo 01 – Bootstrap GitOps e Argo CD**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD instalado e operacional (App-of-Apps),
    * `AppProject appgear-core`,
    * `clusters/ag-<regiao>-core-<env>/apps-core.yaml`, onde é definido o `Application core-security`.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * Istio com `mTLS STRICT`, garantindo tráfego seguro para Vault, OPA e OpenFGA,
    * cadeia de borda que protege o acesso externo aos componentes de segurança (quando expostos),
    * contexto de rede seguro para chamadas de pipelines e serviços internos a OPA/OpenFGA.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Grafana, Loki, OpenCost, Lago)**

  * **Dependente deste módulo** para:

    * coletar métricas/logs de Vault, OPA, Falco e OpenFGA,
    * atribuir custo de segurança por tenant, usando `appgear.io/tenant-id: global` e demais labels,
    * expor dashboards de postura de segurança e custo da camada de segurança core.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, RabbitMQ, Redpanda)**

  * **Pré-requisito técnico para este módulo** no ponto de vista de dados:

    * OpenFGA depende de `core-postgres` como datastore, com credenciais servidas via Vault (engine `database`),
    * Vault utiliza `ceph-block` como backend de storage (via PVC), conforme definido em M04,
    * roles dinâmicas de DB definidas no Vault utilizam instâncias de Postgres padrões do M04.

* **Módulo 05 – Segurança e Segredos (este módulo)**

  * Depende de:

    * **M00** (governança, labels, convenções),
    * **M01** (GitOps/Argo CD),
    * **M02** (malha e borda),
    * **M03** (observabilidade e FinOps),
    * **M04** (storage e bancos core).
  * Entrega:

    * Vault como SSoT de segredos,
    * OPA como Policy-as-Code para pipelines,
    * Falco como sensor de runtime,
    * OpenFGA como serviço de autorização ReBAC.

* **Módulo 06+ – SSO, Identidade, Autorização avançada, Suites, Workspaces**

  * **Dependem deste módulo** para:

    * armazenar segredos de SSO/IDP em Vault (`kv/appgear/sso/...`),
    * validar manifests e pipelines contra políticas OPA,
    * consumir OpenFGA como backend de autorização fina,
    * monitorar eventos de runtime suspeitos via Falco.

Em resumo:

* **M00 → M01 → M02 → M03 → M04 → M05 → (M06, Suites, Workspaces, etc.)**
* Sem Módulo 05, a plataforma AppGear carece de uma camada padronizada de **Segurança, Segredos e Autorização**, e módulos posteriores (SSO, Suites, Workspaces) não podem ser considerados conformes do ponto de vista de segurança.
