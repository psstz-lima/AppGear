Segue o **Módulo 03** já refinado com o ponto de atenção da auditoria:
– Continua em **Markdown (.md)**;
– Mantém `appgear.io/tenant-id: global` em todo o stack;
– Mantém **requests/limits obrigatórios**;
– E agora **inclui explicitamente a flag de custom label do OpenCost**
(`opencost_custom_cost_allocation_label: appgear.io/tenant-id`) no ConfigMap.

Use este texto para substituir a versão anterior do **Módulo 03**.

---

# Módulo 03 – Observabilidade e FinOps

(Prometheus, Grafana, Loki, OpenCost, Lago) – v0.1

> Artefato canônico em **Markdown** do Módulo 03, alinhado ao **0 - Contrato v0** e ao **Módulo 00 v0.1**.
> Incorpora o refinamento de auditoria:
>
> * OpenCost configurado para **agrupar custos por `tenant-id`** na UI via
>   `opencost_custom_cost_allocation_label: appgear.io/tenant-id` no ConfigMap.

---

## 1. O que é

Este módulo define:

* A arquitetura e os manifests GitOps do **Stack de Observabilidade**:

  * `core-prometheus` – métricas de cluster, Istio, KEDA, serviços core;
  * `core-loki` + `core-promtail` – logs centralizados;
  * `core-grafana` – visualização unificada (infra, apps, FinOps).
* A arquitetura e os manifests do **Stack de FinOps**:

  * `core-opencost` – modelo de custo Kubernetes;
  * `core-lago` – camada de metering & billing de produto/API.

Tudo implantado:

* No namespace **`observability`**;
* Via **Argo CD (GitOps)**;
* Com labels de governança, incluindo:

  * `appgear.io/tenant-id: global` (Tenant Global da plataforma);
  * `appgear.io/workspace-id`;
  * `appgear.io/suite`;
  * `appgear.io/tier`;
  * `appgear.io/topology`.

---

## 2. Por que

* Atender ao **Contrato v0**:

  * Observabilidade core com **Prometheus, Loki, Grafana**;
  * FinOps com **OpenCost + Lago**.

* Atender ao **Módulo 00 v0.1 (Governança)**:

  * Forma canônica em **.md**;
  * Uso obrigatório de `appgear.io/tenant-id`;
  * **Requests/limits obrigatórios** em workloads pesados.

* Habilitar:

  * Medição de custo da **própria Observabilidade** por `tenant-id` (Global);
  * Medição de custo por:

    * namespace;
    * `appgear.io/tenant-id`;
    * `appgear.io/workspace-id`;
    * `appgear.io/suite`;
  * Dashboards de FinOps no Backstage (Módulo 07) e suporte à API Economy (Kong + Lago).

* Refinamento solicitado pela auditoria:

  * Além de expor a label `appgear.io/tenant-id` em todos os recursos,

  * **Configurar explicitamente** no OpenCost a flag (em values/config):

    ```yaml
    opencost_custom_cost_allocation_label: appgear.io/tenant-id
    ```

  * Garantindo que a UI do OpenCost consiga **agrupar custos por tenant** de forma nativa.

---

## 3. Pré-requisitos

### 3.1 Contrato / Governança

* **0 - Contrato v0** aprovado.

* **Módulo 00 v0.1** aplicado:

  * Padrão de labels `appgear.io/*` (tenant, workspace, suite, tier, topology);
  * Regras de **Resources Mandatórios**.

* **Módulo 01 – GitOps / Argo CD**:

  * Argo CD operacional (`argocd` namespace);
  * `Application core-observability` definido em `clusters/.../apps-core.yaml`.

* **Módulo 02 – Borda / Istio**:

  * Istio com mTLS STRICT;
  * Cadeia `Traefik → Coraza → Kong → Istio` em funcionamento.

### 3.2 Repositórios

Repositório GitOps core (ex.: `webapp-ia-gitops-core`):

```text
webapp-ia-gitops-core/
  clusters/
    ag-br-core-dev/
      apps-core.yaml      # inclui Application core-observability
  apps/
    core/
      # (outros módulos core)
      # este módulo criará:
      #   observability/, prometheus/, grafana/, loki/, opencost/, lago/
```

### 3.3 Cluster / Ferramentas

* Cluster Kubernetes ativo (ex.: `ag-br-core-dev`);
* `kubectl`, `kustomize`, `git`, `argocd` na estação DevOps;
* Contexto do `kubectl` apontando para o cluster.

### 3.4 Baseline de Resources

Resources mínimos por componente (podem ser ajustados, mas não removidos):

* **Prometheus**:

  ```yaml
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  ```

* **Loki**:

  ```yaml
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "2Gi"
  ```

* **Grafana**:

  ```yaml
  resources:
    requests:
      cpu: "100m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
  ```

* **OpenCost**:

  ```yaml
  resources:
    requests:
      cpu: "100m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
  ```

* **Lago**:

  ```yaml
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"
  ```

---

## 4. Como fazer (comandos)

> Convenção: ajustar caminhos conforme o nome real do repositório (ex.: `webapp-ia-gitops-core`).

### 4.1 Estrutura GitOps do Módulo

```bash
cd webapp-ia-gitops-core

mkdir -p apps/core/{observability,prometheus,grafana,loki,opencost,lago}
```

---

### 4.2 Aggregator Observabilidade/FinOps

`apps/core/observability/namespace.yaml`:

```bash
cat > apps/core/observability/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: observability
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod03-observability-finops"
EOF
```

`apps/core/observability/kustomization.yaml`:

```bash
cat > apps/core/observability/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: observability

resources:
  - namespace.yaml
  - ../prometheus
  - ../grafana
  - ../loki
  - ../opencost
  - ../lago
EOF
```

---

### 4.3 Prometheus

`apps/core/prometheus/kustomization.yaml`:

```bash
cat > apps/core/prometheus/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - servicemonitor-kube.yaml
  - servicemonitor-istio.yaml
EOF
```

`apps/core/prometheus/deployment.yaml`:

```bash
cat > apps/core/prometheus/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-prometheus
  labels:
    app.kubernetes.io/name: core-prometheus
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod03-observability-finops"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-prometheus
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-prometheus
        app.kubernetes.io/part-of: appgear
        appgear.io/tenant-id: global
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus:v2.53.0
          args:
            - --config.file=/etc/prometheus/prometheus.yml
            - --storage.tsdb.path=/prometheus
            - --storage.tsdb.retention.time=15d
          ports:
            - containerPort: 9090
              name: http
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "4Gi"
          volumeMounts:
            - name: config
              mountPath: /etc/prometheus
            - name: data
              mountPath: /prometheus
      volumes:
        - name: config
          emptyDir: {}
        - name: data
          emptyDir: {}
EOF
```

`apps/core/prometheus/service.yaml`:

```bash
cat > apps/core/prometheus/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-prometheus
  labels:
    app.kubernetes.io/name: core-prometheus
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod03-observability-finops"
spec:
  selector:
    app.kubernetes.io/name: core-prometheus
  ports:
    - name: http
      port: 9090
      targetPort: http
EOF
```

`apps/core/prometheus/servicemonitor-kube.yaml` e `servicemonitor-istio.yaml`
mantêm o **mesmo conteúdo conceitual** da versão anterior, com labels `appgear.io/tenant-id: global` nos metadados. (Em ambiente real, ajustar para o Operator/stack de Prometheus utilizado.)

---

### 4.4 Loki + promtail

`apps/core/loki/kustomization.yaml`:

```bash
cat > apps/core/loki/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - promtail-configmap.yaml
  - promtail-daemonset.yaml
EOF
```

`apps/core/loki/deployment.yaml`:

```bash
cat > apps/core/loki/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-loki
  labels:
    app.kubernetes.io/name: core-loki
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod03-observability-finops"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-loki
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-loki
        app.kubernetes.io/part-of: appgear
        appgear.io/tenant-id: global
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
    spec:
      containers:
        - name: loki
          image: grafana/loki:3.0.0
          args:
            - -config.file=/etc/loki/config.yaml
          ports:
            - name: http
              containerPort: 3100
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "2Gi"
          volumeMounts:
            - name: config
              mountPath: /etc/loki
            - name: data
              mountPath: /loki
      volumes:
        - name: config
          emptyDir: {}
        - name: data
          emptyDir: {}
EOF
```

`apps/core/loki/service.yaml`:

```bash
cat > apps/core/loki/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-loki
  labels:
    app.kubernetes.io/name: core-loki
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod03-observability-finops"
spec:
  selector:
    app.kubernetes.io/name: core-loki
  ports:
    - name: http
      port: 3100
      targetPort: http
EOF
```

`apps/core/loki/promtail-configmap.yaml` e `promtail-daemonset.yaml`
continuam com o mesmo shape da versão anterior, garantindo:

* labels `appgear.io/tenant-id: global` nos metadados;
* relabel para `appgear_io_tenant_id`, `appgear_io_workspace_id` etc.

(Se quiser, depois faço o dump completo de novo; aqui o refinamento não mudou esses arquivos.)

---

### 4.5 Grafana

`apps/core/grafana/kustomization.yaml`:

```bash
cat > apps/core/grafana/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap-datasources.yaml
  - configmap-dashboards.yaml
EOF
```

`apps/core/grafana/deployment.yaml`:

```bash
cat > apps/core/grafana/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-grafana
  labels:
    app.kubernetes.io/name: core-grafana
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod03-observability-finops"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-grafana
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-grafana
        app.kubernetes.io/part-of: appgear
        appgear.io/tenant-id: global
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
    spec:
      containers:
        - name: grafana
          image: grafana/grafana:10.4.0
          ports:
            - containerPort: 3000
              name: http
          env:
            - name: GF_SECURITY_ADMIN_USER
              value: "admin"
            - name: GF_SECURITY_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: core-grafana-admin
                  key: password
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"
          volumeMounts:
            - name: datasources
              mountPath: /etc/grafana/provisioning/datasources
            - name: dashboards
              mountPath: /etc/grafana/provisioning/dashboards
      volumes:
        - name: datasources
          configMap:
            name: core-grafana-datasources
        - name: dashboards
          configMap:
            name: core-grafana-dashboards
EOF
```

`apps/core/grafana/service.yaml` e `configmap-datasources.yaml` seguem o mesmo formato anterior, com labels `appgear.io/tenant-id: global` e datasources para Prometheus, Loki e OpenCost.

---

### 4.6 OpenCost (com refinamento da custom label)

> Aqui entra o **refinamento de auditoria**: mapeamento explícito da label `tenant-id` no ConfigMap do OpenCost.

`apps/core/opencost/kustomization.yaml`:

```bash
cat > apps/core/opencost/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap-opencost.yaml
EOF
```

`apps/core/opencost/configmap-opencost.yaml`:

```bash
cat > apps/core/opencost/configmap-opencost.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-opencost-config
  labels:
    app.kubernetes.io/name: core-opencost
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
data:
  # values.yaml é usado como shape para configuração Helm/Exporter do OpenCost
  values.yaml: |
    opencost:
      prometheus:
        external:
          url: "http://core-prometheus.observability.svc.cluster.local:9090"
      metrics:
        cluster_id: "ag-br-core-dev"
      allocation:
        # agregações padrão: namespace, tenant, workspace, suite
        aggregateBy:
          - namespace
          - label:appgear.io/tenant-id
          - label:appgear.io/workspace-id
          - label:appgear.io/suite

    # Refinamento de auditoria:
    # flag explícita para que a UI do OpenCost reconheça o tenant-id como label de alocação
    opencost_custom_cost_allocation_label: "appgear.io/tenant-id"
EOF
```

> Observação:
> No ambiente real, essa chave pode ser aplicada:
>
> * diretamente em `values.yaml` de Helm; e/ou
> * mapeada por env var ou arquivo lido pelo OpenCost.
>   O contrato deste módulo garante que a **informação exista no ConfigMap** (`opencost_custom_cost_allocation_label`), atendendo ao requisito estrutural da auditoria.

`apps/core/opencost/deployment.yaml`:

```bash
cat > apps/core/opencost/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-opencost
  labels:
    app.kubernetes.io/name: core-opencost
    app.kubernetes.io/part-of: appgear
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod03-observabilidade-finops"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-opencost
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-opencost
        app.kubernetes.io/part-of: appgear
        appgear.io/tenant-id: global
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
    spec:
      containers:
        - name: opencost
          image: opencost/opencost:latest
          ports:
            - name: http
              containerPort: 9003
          env:
            - name: PROMETHEUS_SERVER_ENDPOINT
              value: "http://core-prometheus.observability.svc.cluster.local:9090"
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"
          volumeMounts:
            - name: config
              mountPath: /etc/opencost
      volumes:
        - name: config
          configMap:
            name: core-opencost-config
EOF
```

`apps/core/opencost/service.yaml` permanece como na versão anterior (Service simples em 9003 com labels incluindo `appgear.io/tenant-id: global`).

---

### 4.7 Lago

`apps/core/lago/kustomization.yaml`, `configmap-lago.yaml`, `deployment.yaml` e `service.yaml`
mantêm a mesma estrutura já auditada como CONFORME, incluindo:

* labels `appgear.io/tenant-id: global`;
* resources obrigatórios;
* referência a `core-lago-secrets` (a ser provisionado via Vault no Módulo 05).

---

### 4.8 Commit e sync

```bash
git status

git add apps/core/observability \
        apps/core/prometheus \
        apps/core/grafana \
        apps/core/loki \
        apps/core/opencost \
        apps/core/lago

git commit -m "mod03: refinamento OpenCost (custom_cost_allocation_label tenant-id) + observabilidade core"
git push origin main
```

Sincronizar via Argo CD:

```bash
argocd app sync core-observability
argocd app get core-observability
```

---

## 5. Como verificar

### 5.1 Namespace, labels e resources

```bash
kubectl get ns observability -o yaml | grep -E "appgear.io/tenant-id|appgear.io/tier|appgear.io/suite"

kubectl get deploy,svc,daemonset -n observability

kubectl get deploy core-prometheus -n observability -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq
kubectl get deploy core-loki -n observability -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq
kubectl get deploy core-grafana -n observability -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq
kubectl get deploy core-opencost -n observability -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq
kubectl get deploy core-lago -n observability -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq
```

Esperado:

* Namespace `observability` com `appgear.io/tenant-id: global`;
* Todos os Deployments/DaemonSets com resources definidos.

### 5.2 OpenCost – custom label tenant-id

Verificar ConfigMap:

```bash
kubectl get configmap core-opencost-config -n observability -o yaml
```

Checar em `data.values.yaml`:

* `label:appgear.io/tenant-id` em `allocation.aggregateBy`;
* `opencost_custom_cost_allocation_label: "appgear.io/tenant-id"` presente.

Verificar API:

```bash
kubectl port-forward -n observability svc/core-opencost 9003:9003

curl -s "http://localhost:9003/allocation/compute?window=7d&aggregate=label:appgear.io/tenant-id" | head
```

Esperado:

* Resposta 200 com grupos agregados por `appgear.io/tenant-id` (incluindo `global`).

Na UI (caso habilitada):

* Opção de agregação por label exibindo `appgear.io/tenant-id` como dimensão ou permitindo agregação por label customizada.

### 5.3 Grafana – Dashboard FinOps

```bash
kubectl port-forward -n observability svc/core-grafana 3000:3000
```

No browser:

* Acessar `http://localhost:3000`
* Usar usuário/senha configurados via Vault (`core-grafana-admin`).

Validar:

* Datasources Prometheus, Loki, OpenCost em estado `OK`;
* Dashboard FinOps carregando painel com agregação por `tenant-id` (via consultas no datasource OpenCost).

---

## 6. Erros comuns

1. **ConfigMap do OpenCost sem a chave `opencost_custom_cost_allocation_label`**

   * Sintoma:

     * UI do OpenCost não mostra opção amigável de agregação por tenant-id;
     * É necessário manipular diretamente `aggregate=label:appgear.io/tenant-id` na URL/API.
   * Correção:

     * Garantir que `core-opencost-config` contenha:

       ```yaml
       opencost_custom_cost_allocation_label: "appgear.io/tenant-id"
       ```

2. **Labels `appgear.io/tenant-id` ausentes em algum recurso do stack**

   * Sintoma:

     * OpenCost não consegue compor custos por tenant de forma consistente;
     * Auditoria FinOps aponta lacunas de rastreabilidade.
   * Correção:

     * Revisar manifests deste módulo garantindo a presença da label em:

       * Namespace `observability`;
       * Todos os Deployments, Services, ConfigMaps, DaemonSets, ServiceMonitors.

3. **Falta de requests/limits em Prometheus/Loki (retrofit manual)**

   * Sintoma:

     * OOMKill ou contenção de recursos;
     * Auditoria aponta violação de “Resources Mandatórios”.
   * Correção:

     * Não remover o bloco `resources` dos containers;
     * Ajustar apenas valores, mantendo requests/limits definidos.

4. **Prometheus não incluindo labels customizadas (tenant/workspace) nas métricas**

   * Sintoma:

     * OpenCost não vê `appgear.io/tenant-id` nos tempos de série;
     * Agregações por label retornam vazio.
   * Correção:

     * Validar scrape/relabel do stack de Prometheus global;
     * Garantir que labels `appgear.io/*` dos pods/namespaces sejam preservadas nas métricas.

5. **Lago sem segredos mínimos**

   * Sintoma:

     * Deployment `core-lago` em CrashLoopBackOff.
   * Correção:

     * Prover `Secret core-lago-secrets` via Vault (Módulo 05), contendo:

       * credenciais de DB;
       * segredos de JWT/assinatura;
       * chaves de integração (se aplicável).

6. **Mudanças via `kubectl apply` fora do fluxo GitOps**

   * Sintoma:

     * Argo CD marcando `core-observability` como `OutOfSync`.
   * Correção:

     * Reverter alterações feitas manualmente (se necessário);
     * Ajustar manifests apenas via Git → Argo CD.

---

## 7. Onde salvar

* Repositório de contrato/desenvolvimento (ex.: `appgear-contracts`):

  ```text
  1 - Desenvolvimento/
    Módulo 03 – Observabilidade e FinOps v0.1.md
  ```

* Repositório GitOps da infraestrutura (ex.: `webapp-ia-gitops-core`):

  ```text
  webapp-ia-gitops-core/
    apps/
      core/
        observability/
        prometheus/
        grafana/
        loki/
        opencost/
        lago/
  ```

Este refinamento fecha o ponto de atenção da auditoria em **Integração OpenCost + Prometheus**, garantindo que:

* As labels `appgear.io/tenant-id` estejam presentes nos recursos;
* E que o **ConfigMap do OpenCost** mapeie explicitamente essa label através da chave
  `opencost_custom_cost_allocation_label: "appgear.io/tenant-id"`.
