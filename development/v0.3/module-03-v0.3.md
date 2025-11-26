# M03 – Observabilidade e FinOps (v0.3)

> [!IMPORTANT]
> Este documento define o **Módulo 03 (M03)** da arquitetura AppGear na linha v0.3.  
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

# Módulo 03 – Observabilidade e FinOps

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

- Exige rotulagem `appgear.io/*` para FinOps multi-tenant em Prometheus/Loki/Grafana/OpenCost/Lago.


### Premissas padrão (v0.3)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Define stack de métricas, logs, traces e custos: Prometheus, Loki, Grafana, OpenCost, Lago, etc.
Garante que todos os recursos sejam rotulados para permitir visão por tenant, workspace, módulo e suíte.

---

## 1. O que é

Este módulo define a arquitetura e os manifests GitOps do **Stack de Observabilidade e FinOps** da plataforma **AppGear** na **Topologia B (Kubernetes)**, composto por:

* **Observabilidade**

  * `core-prometheus` – coleta de métricas de:

    * cluster Kubernetes,
    * Istio,
    * componentes core,
    * (quando aplicável) KEDA e workloads relevantes.
  * `core-loki` + `core-promtail` – centralização e indexação de logs.
  * `core-grafana` – camada de visualização única (infra, apps, FinOps).

* **FinOps**

  * `core-opencost` – cálculo de custo por:

    * namespace,
    * `appgear.io/tenant-id`,
    * `appgear.io/workspace-id`,
    * `appgear.io/suite`.
  * `core-lago` – camada de **metering & billing** (uso de produto/API), integrada ao ecossistema (Kong, Backstage, etc.).

Tudo é implantado:

* no namespace **`observability`**;
* via **Argo CD (GitOps)**;
* com labels de governança padronizadas:

  ```yaml
  appgear.io/tenant-id: global
  appgear.io/workspace-id: global
  appgear.io/suite: core
  appgear.io/tier: core
  appgear.io/topology: B
  ```

---

## 2. Por que

1. **Atender Contrato v0 e Módulo 00 (Governança)** 

   * Observabilidade core baseada em **Prometheus, Loki, Grafana**.
   * FinOps baseado em **OpenCost + Lago**.
   * Labels `appgear.io/*` como base para auditoria, recorte de custo e rastreabilidade.

2. **Medir custo por tenant/workspace/suite de forma nativa**

   * OpenCost precisa reconhecer `appgear.io/tenant-id` como dimensão primária de alocação.
   * A chave `opencost_custom_cost_allocation_label: appgear.io/tenant-id` garante que a **UI do OpenCost** exiba agregações por tenant sem gambiarras de query.

3. **Evitar “observabilidade invisível” e custo não rastreável**

   * Sem `resources` e labels corretas, a própria pilha de observabilidade fica fora do modelo de custo.
   * Este módulo garante que o **custo da observabilidade** é atribuído ao tenant `global` (plataforma).

4. **Preparar dados para API Economy e Billing de Produto (Lago)**

   * Dados de uso/custo expostos via Grafana/OpenCost/Lago são base para:

     * precificação,
     * planos de cobrança,
     * monitoração de rentabilidade por tenant e por workspace.

5. **Convergir práticas de Dev, Ops e FinOps**

   * Tudo segue o mesmo padrão:

     * Git como fonte de verdade,
     * Argo CD como reconciliador,
     * labels `appgear.io/*` como eixo para custo, auditoria e filtros de dashboards,
     * `requests/limits` obrigatórios em todos os workloads da stack.

---

## 3. Pré-requisitos

### 1. Governança e Contrato

* **0 - Contrato v0** aprovado e em vigor. 
* **Módulo 00 – Convenções e Nomenclatura v0** aplicado:

  * Padrão de labels `appgear.io/*` (tenant, workspace, suite, tier, topology).
  * Regra de **resources obrigatórios** em workloads de infraestrutura.
  * Padrão de documentação em `.md` e repositórios organizados por módulos.

### 2. GitOps / Argo CD

* **Módulo 01 – Bootstrap GitOps e Argo CD** aplicado:

  * Argo CD instalado e sincronizando o cluster `ag-<regiao>-core-<env>`.
  * Application `core-observability` (ou equivalente) cadastrado em `apps-core.yaml`, apontando para `apps/core/observability`.

### 3. Borda / Malha

* **Módulo 02 – Malha de Serviço e Borda** funcional:

  * Istio com `mTLS STRICT STRICT` para tráfego Leste–Oeste.
  * Cadeia `Traefik → Coraza → Kong → Istio` funcional para tráfego Norte–Sul, garantindo caminhos de entrada bem definidos para logs/métricas.

### 4. Repositório GitOps

Repositório core (exemplo: `appgear-gitops-core`):

```text
appgear-gitops-core/
  clusters/
    ag-br-core-dev/
      apps-core.yaml      # inclui o Application core-observability
  apps/
    core/
      # outros módulos core
      # este módulo criará:
      #   observability/
      #   prometheus/
      #   grafana/
      #   loki/
      #   opencost/
      #   lago/
```

### 5. Cluster e Ferramentas

* Cluster Kubernetes ativo (ex.: `ag-br-core-dev`).
* Ferramentas no host DevOps:

  * `kubectl`
  * `kustomize` (ou `kubectl kustomize`)
  * `git`
  * `argocd` (CLI opcional).

### 6. Baseline de Resources (mínimos recomendados)

Podem ser ajustados por ambiente, mas **não podem ser removidos**:

* Prometheus

  ```yaml
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
  ```

* Loki

  ```yaml
  requests:
    cpu: "200m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "2Gi"
  ```

* Grafana

  ```yaml
  requests:
    cpu: "100m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "1Gi"
  ```

* OpenCost

  ```yaml
  requests:
    cpu: "100m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "1Gi"
  ```

* Lago

  ```yaml
  requests:
    cpu: "200m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
  ```

---

## KEDA e scale-to-zero para observabilidade

* **Objetivo:** reduzir footprint em dev/pequeno porte mantendo ingestão controlada. `ScaledObject` deve ser habilitado por padrão para Loki/Promtail, beats/agents do ELK (quando usados) e ingest gateways (Grafana Agent/Loki Gateway).
* **Triggers sugeridos:**

  * **Logs HTTP**: trigger HTTP do KEDA para Loki Gateway/Ingress, com `targetPendingRequests: 20` e `cooldownPeriod: 120s`.
  * **Métrica de ingestão**: trigger Prometheus (`loki_ingester_request_duration_seconds_count` ou equivalente), limitando a escala quando não há ingestão.
  * **Filas**: se houver buffer em Redpanda/RabbitMQ, usar `queueLength` como fallback para `ScaledJob` de reprocessamento.
* **Defaults de chart/kustomize:** `minReplicaCount: 0`, `pollingInterval: 15s`, `cooldownPeriod: 120s`, `maxReplicaCount` alinhado ao cluster (ex.: `5`). Devem ficar **ligados por padrão** em `values.yaml`/`kustomization.yaml`.
* **Documentação**: registrar os parâmetros no repositório `docs/` e referenciar nas pipelines de observabilidade para que o comportamento seja auditável.

---

## 4. Como fazer (comandos)

> Ajuste `appgear-gitops-core` para o nome real do repositório GitOps core utilizado.

---

### 1. Criar a estrutura GitOps do módulo

```bash
cd appgear-gitops-core

mkdir -p apps/core/{observability,prometheus,grafana,loki,opencost,lago}
```

---

### 2. Namespace `observability` e agregador do stack

#### 2.1 Namespace com labels de Governança

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

#### 2.2 Kustomization agregando os componentes

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

### 3. Prometheus – métricas core

#### 3.1 Kustomization

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

#### 3.2 Deployment

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

#### 3.3 Service

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

> Os `ServiceMonitors` para cluster e Istio seguem o mesmo padrão, com labels `appgear.io/*`, respeitando a stack de Prometheus (operator ou vanilla).

---

### 4. Loki + promtail – logs centralizados

#### 4.1 Kustomization

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

#### 4.2 Deployment do Loki

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

#### 4.3 Service do Loki

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

> `promtail-configmap.yaml` e `promtail-daemonset.yaml` devem enviar logs para `core-loki`, preservando (quando possível) as labels `appgear.io/*` como labels de série de log.

---

### 5. Grafana – visualização

#### 5.1 Kustomization

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

#### 5.2 Deployment

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

> `configmap-datasources.yaml` deve provisionar datasources para:
>
> * Prometheus (`core-prometheus`),
> * Loki (`core-loki`),
> * OpenCost (`core-opencost`).

---

### 6. OpenCost – custo por tenant/workspace (com label customizada)

#### 6.1 Kustomization

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

#### 6.2 ConfigMap com `opencost_custom_cost_allocation_label`

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
  values.yaml: |
    opencost:
      prometheus:
        external:
          url: "http://core-prometheus.observability.svc.cluster.local:9090"
      metrics:
        cluster_id: "ag-br-core-dev"
      allocation:
        aggregateBy:
          - namespace
          - label:appgear.io/tenant-id
          - label:appgear.io/workspace-id
          - label:appgear.io/suite

    # chave de auditoria: label padrão de tenant
    opencost_custom_cost_allocation_label: "appgear.io/tenant-id"
EOF
```

#### 6.3 Deployment

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
    appgear.io/module: "mod03-observability-finops"
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

> A forma exata como o OpenCost consome `opencost_custom_cost_allocation_label` depende da distribuição/Helm Chart, mas **este módulo garante** que a informação esteja presente no ConfigMap sob controle Git, conforme exigido por auditoria.

---

### 7. Lago – metering & billing

A estrutura segue o mesmo padrão (labels `appgear.io/*`, resources obrigatórios):

* `apps/core/lago/kustomization.yaml`
* `apps/core/lago/configmap-lago.yaml`
* `apps/core/lago/deployment.yaml`
* `apps/core/lago/service.yaml`

Com:

* `core-lago` expondo API HTTP;
* Secrets sensíveis provisionados via Vault/Módulo de Segurança (não versionados aqui).

---

### 8. Commit e sync via Argo CD

```bash
git add apps/core/observability \
        apps/core/prometheus \
        apps/core/grafana \
        apps/core/loki \
        apps/core/opencost \
        apps/core/lago

git commit -m "mod03: observabilidade core + OpenCost com tenant-id configurado"
git push origin main
```

Sincronizar:

```bash
argocd app sync core-observability
argocd app get core-observability
```

---

## 5. Como verificar

### 1. Namespace, labels e resources

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
* Todos os Deployments com bloco `resources` definido.

### 2. OpenCost – label customizada de tenant

Verificar ConfigMap:

```bash
kubectl get configmap core-opencost-config -n observability -o yaml
```

Checar:

* Em `data.values.yaml`:

  * `label:appgear.io/tenant-id` listado em `allocation.aggregateBy`;
  * `opencost_custom_cost_allocation_label: "appgear.io/tenant-id"` presente.

Testar endpoint:

```bash
kubectl port-forward -n observability svc/core-opencost 9003:9003

curl -s "http://localhost:9003/allocation/compute?window=7d&aggregate=label:appgear.io/tenant-id" | head
```

Esperado:

* Resposta HTTP 200, com grupos agregados por `appgear.io/tenant-id` (ex.: `global`).

### 3. Grafana – datasources e dashboards

```bash
kubectl port-forward -n observability svc/core-grafana 3000:3000
```

No navegador:

* Acessar `http://localhost:3000`;
* Autenticar com usuário/senha configurados no Secret `core-grafana-admin`;
* Verificar:

  * Datasources Prometheus, Loki, OpenCost em estado `OK`;
  * Dashboard de FinOps exibindo painéis agregando custos por:

    * namespace,
    * `appgear.io/tenant-id`,
    * `appgear.io/workspace-id`,
    * `appgear.io/suite` (quando mapeado).

### 4. Saúde geral dos componentes

```bash
kubectl get pods -n observability
```

Esperado:

* Pods de `core-prometheus`, `core-loki`, `core-grafana`, `core-opencost`, `core-lago` em `Running` (ou `Completed`, se aplicável);
* Sem `CrashLoopBackOff`.

---

## 6. Erros comuns

* **Esquecer a chave `opencost_custom_cost_allocation_label` no ConfigMap**

  * Efeito: UI do OpenCost não exibe corretamente a dimensão de tenant; relatórios de FinOps ficam inconsistentes.
  * Correção: garantir que a chave exista em `core-opencost-config` e seja versionada em Git.

* **Remover `requests/limits` dos componentes de Observabilidade**

  * Efeito: risco de OOMKill e impacto em workloads de negócio.
  * Correção: manter sempre bloco `resources`; apenas ajustar valores por ambiente.

* **Ausência de `appgear.io/tenant-id` em namespace ou pods**

  * Efeito: OpenCost não consegue consolidar custo por tenant; auditoria não consegue rastrear gasto da pilha.
  * Correção: revisar todos os manifests deste módulo e garantir a presença da label.

* **Alterar manifests diretamente via `kubectl apply` em vez de GitOps**

  * Efeito: Argo CD marca `core-observability` como `OutOfSync`; mudanças se perdem no próximo sync.
  * Correção: aplicar alterações somente via Git → Argo CD.

* **Configurar OpenCost apontando para endpoint Prometheus incorreto**

  * Efeito: falha na coleta de métricas de custo.
  * Correção: revisar `PROMETHEUS_SERVER_ENDPOINT` e `values.yaml` do ConfigMap para apontar para `core-prometheus` no namespace `observability`.

* **Deploy do Lago sem secrets obrigatórios**

  * Efeito: `core-lago` entra em `CrashLoopBackOff`.
  * Correção: provisionar `core-lago-secrets` via fluxo de segredos (Vault / Módulo de Segurança).

---

## 7. Onde salvar

* **Documento de governança (este módulo)**

  * Repositório: `appgear-docs` ou `appgear-contracts` (conforme organização interna).
  * Caminho sugerido:

    * `docs/architecture/Modulo 03 - Observabilidade e FinOps v0.1.md`
      ou
    * `1 - Desenvolvimento v0/Módulo 03 – Observabilidade e FinOps v0.1.md`.

* **Manifests GitOps (Topologia B)**

  * Repositório: `appgear-gitops-core` (ou equivalente definido no Módulo 01).
  * Estrutura:

    ```text
    apps/core/observability/
      namespace.yaml
      kustomization.yaml

    apps/core/prometheus/
      deployment.yaml
      service.yaml
      servicemonitor-kube.yaml
      servicemonitor-istio.yaml
      kustomization.yaml

    apps/core/loki/
      deployment.yaml
      service.yaml
      promtail-configmap.yaml
      promtail-daemonset.yaml
      kustomization.yaml

    apps/core/grafana/
      deployment.yaml
      service.yaml
      configmap-datasources.yaml
      configmap-dashboards.yaml
      kustomization.yaml

    apps/core/opencost/
      deployment.yaml
      service.yaml
      configmap-opencost.yaml
      kustomization.yaml

    apps/core/lago/
      deployment.yaml
      service.yaml
      configmap-lago.yaml
      kustomization.yaml
    ```

Este módulo passa a ser a referência para qualquer implantação, retrofit ou auditoria relacionada a **Observabilidade e FinOps** na plataforma AppGear.

---

## 8. Dependências entre os módulos

A relação deste Módulo 03 com os demais módulos AppGear deve ser respeitada para garantir implantação ordenada e coerente:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * É **pré-requisito direto** deste módulo.
  * Fornece:

    * padrão de labels `appgear.io/*` (usadas em todos os manifests aqui),
    * regra de `resources` obrigatórios,
    * organização dos repositórios (incluindo `appgear-gitops-core`),
    * convenções para namespaces (`observability`) e topologia (`B`).

* **Módulo 01 – Bootstrap GitOps e Argo CD**

  * Também é **pré-requisito**.
  * Fornece:

    * Argo CD instalado,
    * AppProjects e Applications root,
    * Application `core-observability` em `apps-core.yaml` apontando para `apps/core/observability`.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * É **pré-requisito funcional**:

    * Observabilidade coleta métricas/logs da malha e da cadeia de borda;
    * Dados de tráfego (Kong, Istio, Traefik, Coraza) alimentam dashboards e análises de custo.

* **Módulo 03 – Observabilidade e FinOps (este módulo)**

  * Depende de:

    * **M00** (governança e labels),
    * **M01** (GitOps/Argo CD),
    * **M02** (malha e borda).
  * Entrega:

    * stack de observabilidade (Prometheus, Loki, Grafana) consolidado,
    * stack de FinOps (OpenCost, Lago) com custo por tenant/workspace/suite,
    * ConfigMap do OpenCost com `opencost_custom_cost_allocation_label: appgear.io/tenant-id`.

* **Módulo 04 – Armazenamento e Bancos Core**

  * **Depende deste módulo** para:

    * visibilidade de métricas e logs de bancos/brokers (Postgres, Redis, Qdrant, RabbitMQ, Redpanda),
    * cálculo de custo de storage/compute desses componentes por tenant (`global` no caso core).

* **Demais módulos (SSO, Segurança/Segredos, Suites, Workspaces, PWA, etc.)**

  * Devem:

    * expor métricas e logs consumíveis por este stack,
    * utilizar labels `appgear.io/*` para permitir recortes de custo e auditoria,
    * consumir dados de OpenCost/Lago para decisões de produto e operação.

Em resumo:

* **M00 → M01 → M02 → M03 → (M04, Suites, Workspaces, etc.)**
* Sem M03, a plataforma AppGear não tem **observabilidade consolidada** nem **FinOps efetivo**; sem M00–M02, este módulo não pode ser considerado conforme.

---

## 9. Metadados
- Gerado automaticamente por CodeGPT
- Versão do módulo: v0.3
- Compatibilidade: full
- Data de geração: 2025-11-24
