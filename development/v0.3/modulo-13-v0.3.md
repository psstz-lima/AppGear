# M13 – Workspaces, vCluster e modelo por cliente (v0.3)

> [!IMPORTANT]
> Este documento define o **Módulo 13 (M13)** da arquitetura AppGear na linha v0.3.  
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

# Módulo 13 – Workspaces, vCluster e modelo por cliente

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

- Formaliza `tenant_id`/`workspace_id`, labels `appgear.io/*` e vClusters por workspace via ApplicationSet.


### Premissas padrão (v0.3)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Define como a AppGear organiza multi-tenancy: tenant_id, workspace_id e um vCluster por workspace quando necessário.
Usa um repositório GitOps específico de workspaces e um ApplicationSet para criar/atualizar vClusters, quotas, NetworkPolicies e metadados por cliente/produto.

---

## 1. O que é

O **Módulo 13** define como a AppGear trata **Workspaces** e o modelo de **vCluster por cliente/produto**, incluindo o registro GitOps e o isolamento de rede/recursos.

1. **Workspace**

* Unidade lógica de trabalho por cliente/produto.
* Identificada por `workspace_id` (ex.: `acme-erp`).
* Associada a um `tenant_id` (ex.: `acme`).

2. **vCluster por workspace**

* Cada `workspace_id` possui um **vCluster dedicado** (hard multi-tenancy lógico):

  * Nome: `vcl-ws-<workspace_id>` (ex.: `vcl-ws-acme-erp`).
  * Rodando em um namespace do cluster físico: `vcluster-ws-<workspace_id>`.

3. **Registro GitOps de Workspaces**

* Repositório Git dedicado: **`appgear-gitops-workspaces`**.
* Estrutura: `workspaces/<workspace_id>/` com os manifests do workspace:

  * vCluster;
  * quotas;
  * NetworkPolicies;
  * metadata (ConfigMap).

4. **Orquestração via ApplicationSet**

* Um único **ApplicationSet** no repositório **`appgear-gitops-core`** (`workspaces-appset`) lê o repositório `appgear-gitops-workspaces` e cria automaticamente os **Applications de cada workspace**, sem edição manual do Core.
* Cada novo diretório em `workspaces/` ⇒ novo workspace provisionado.

5. **Isolamento, Quotas e FinOps**

* Cada workspace tem:

  * `Namespace` host (`vcluster-ws-<workspace_id>`),
  * `ResourceQuota`,
  * `LimitRange`,
  * `NetworkPolicy` de isolamento.
* Todos os recursos do vCluster recebem labels:

  * `appgear.io/tenant-id`;
  * `appgear.io/workspace-id`;
  * além de `appgear.io/tier`, `appgear.io/suite`, `appgear.io/topology`, `appgear.io/contract-version`, `appgear.io/module`.

---

## 2. Por que

1. **Escalabilidade GitOps**

* Situação v0:

  * Para cada cliente, era criado manualmente um `Application` em `appgear-gitops-core`.
* v0.1:

  * Um único **ApplicationSet (`workspaces-appset`)** gera automaticamente os `Applications` dos workspaces a partir do repositório `appgear-gitops-workspaces`.
* Resultado:

  * **Novo workspace** = **novo diretório** em `appgear-gitops-workspaces/workspaces/<workspace_id>`, sem alterar o repositório Core.

2. **Hard Multi-tenancy com vCluster**

* Cada workspace tem um **vCluster isolado**, reduzindo risco de:

  * vazamento de configurações;
  * confusão de RBAC entre clientes.
* Suítes (Factory, Brain, Operations, Guardian) podem ser multi-tenant lógico, mas sempre ancoradas a `tenant_id` e `workspace_id`.

3. **FinOps e Observabilidade (M00/M03)**

* Todos os componentes do vCluster e dos workspaces têm labels padronizados.
* Ferramentas como OpenCost, Lago, Backstage, Grafana e OpenMetadata conseguem:

  * agrupar custos por `tenant_id`, `workspace_id` e por Suíte.

4. **Segurança (NetworkPolicies e mTLS STRICT)**

* vClusters compartilham a rede do host; sem NetworkPolicies, pods de workspaces diferentes poderiam se falar livremente.
* O módulo define uma **NetworkPolicy “deny-all entre workspaces”**, com exceções apenas para namespaces Core (Istio, Segurança, Observabilidade).

5. **Interoperabilidade com outros módulos**

* **M01 – Bootstrap GitOps:**

  * M13 consome o padrão de **ApplicationSets** e não cria Applications “manuais” por workspace.
* **M06 – Identidade/SSO:**

  * Tokens OIDC carregam `workspace_ids`; o backend de Workspaces usa isso para mapear vCluster/namespace.
* **M07 – Backstage:**

  * O plugin de Workspaces comita em `appgear-gitops-workspaces`, não em `appgear-gitops-core`.
* **M09/M10/M11/M12 – Suítes:**

  * Templates das Suítes são instanciados dentro dos vClusters por workspace, sempre com `tenant-id` e `workspace-id`.

---

## 3. Pré-requisitos

### Documentais

* `0 - Contrato v0.md` aceito como fonte de verdade. 
* `1 - Desenvolvimento v0.md` em uso (este módulo será referenciado nele).
* `2 - Auditoria v0.md` e `3 - Interoperabilidade v0.md` disponíveis para consulta.

### Módulos Core já definidos

* M00 – Convenções, Repositórios e Nomenclatura.
* M01 – Bootstrap GitOps e Argo CD (App-of-Apps).
* M02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong).
* M03 – Observabilidade e FinOps.
* M04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, Redpanda).
* M05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA).
* M06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC).
* M07–M12 – Suítes e Portal, ao menos em estado “implantável”.

### Infraestrutura (Topologia B – Kubernetes)

Cluster físico: `ag-<regiao>-core-<env>` com:

* Argo CD operacional (M01).
* Istio em modo **mTLS STRICT STRICT** (M02).
* Storage Ceph pronto (M04).
* Vault, OpenFGA, OPA, Falco (M05).
* Observabilidade (Prometheus, Grafana, Loki, OpenCost, Lago) (M03).

### Repositórios Git

* `appgear-contracts`
* `appgear-gitops-core`
* `appgear-gitops-suites`
* `appgear-backstage`
* `appgear-workspace-template` (template base por workspace)
* **Novo:** `appgear-gitops-workspaces` (registro GitOps de workspaces).

### Ferramentas

* CLI: `git`, `kubectl`, `helm`, `kustomize`, `argocd`, `yq`.
* Acesso de escrita aos repositórios acima.

---

## 4. Como fazer (comandos)

### 1. Criar o repositório de registro de workspaces

No host de desenvolvimento:

```bash
mkdir -p ~/git/appgear-gitops-workspaces
cd ~/git/appgear-gitops-workspaces

git init
git remote add origin git@github.com:appgear/appgear-gitops-workspaces.git
```

`README.md`:

```bash
cat > README.md << 'EOF'
# appgear-gitops-workspaces

Repositório GitOps de registro de Workspaces da AppGear.
Cada diretório em `workspaces/<workspace_id>/` representa um workspace
e contém os manifests de vCluster, quotas, network policies e metadata.
EOF
```

Estrutura inicial:

```bash
mkdir -p workspaces

git add .
git commit -m "chore: init workspaces GitOps registry"
git push -u origin main
```

---

### 2. Criar o primeiro workspace (exemplo: `acme-erp`)

#### 2.1 Estrutura de diretórios

```bash
cd ~/git/appgear-gitops-workspaces

mkdir -p workspaces/acme-erp
cd workspaces/acme-erp
```

Estrutura alvo:

```text
workspaces/acme-erp/
  kustomization.yaml
  namespace-host.yaml
  workspace-configmap.yaml
  resourcequota.yaml
  limitrange.yaml
  networkpolicy-deny-cross-workspaces.yaml
  pvc-vcluster.yaml
  deployment-vcluster.yaml
```

#### 2.2 `kustomization.yaml` do workspace

```bash
cat > kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: vcluster-ws-acme-erp

resources:
  - namespace-host.yaml
  - workspace-configmap.yaml
  - resourcequota.yaml
  - limitrange.yaml
  - networkpolicy-deny-cross-workspaces.yaml
  - pvc-vcluster.yaml
  - deployment-vcluster.yaml
EOF
```

#### 2.3 Namespace host para o vCluster

```bash
cat > namespace-host.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: vcluster-ws-acme-erp
  labels:
    app.kubernetes.io/name: vcl-ws-acme-erp
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: workspace
    appgear.io/topology: B
    appgear.io/workspace-id: acme-erp
    appgear.io/tenant-id: acme
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
EOF
```

#### 2.4 Metadata do workspace (ConfigMap)

```bash
cat > workspace-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ws-acme-erp-metadata
  namespace: vcluster-ws-acme-erp
  labels:
    app.kubernetes.io/name: ws-acme-erp-metadata
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: workspace
    appgear.io/suite: workspace
    appgear.io/topology: B
    appgear.io/workspace-id: acme-erp
    appgear.io/tenant-id: acme
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
data:
  tenant_id: "acme"
  workspace_id: "acme-erp"
  display_name: "Workspace ACME ERP"
  environment: "dev"
EOF
```

#### 2.5 ResourceQuota e LimitRange do namespace host

```bash
cat > resourcequota.yaml << 'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: vcluster-ws-acme-erp-quota
  namespace: vcluster-ws-acme-erp
  labels:
    app.kubernetes.io/name: vcluster-ws-acme-erp
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: workspace
    appgear.io/suite: workspace
    appgear.io/topology: B
    appgear.io/workspace-id: acme-erp
    appgear.io/tenant-id: acme
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
spec:
  hard:
    requests.cpu: "500m"
    limits.cpu: "2"
    requests.memory: "1Gi"
    limits.memory: "4Gi"
    requests.storage: "20Gi"
    pods: "20"
EOF
```

```bash
cat > limitrange.yaml << 'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: vcluster-ws-acme-erp-limits
  namespace: vcluster-ws-acme-erp
  labels:
    app.kubernetes.io/name: vcluster-ws-acme-erp
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: workspace
    appgear.io/suite: workspace
    appgear.io/topology: B
    appgear.io/workspace-id: acme-erp
    appgear.io/tenant-id: acme
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
spec:
  limits:
    - type: Container
      default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "100m"
        memory: "256Mi"
EOF
```

#### 2.6 PVC do vCluster (10Gi)

```bash
cat > pvc-vcluster.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vcluster-ws-acme-erp-data
  namespace: vcluster-ws-acme-erp
  labels:
    app.kubernetes.io/name: vcl-ws-acme-erp
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: workspace
    appgear.io/suite: workspace
    appgear.io/topology: B
    appgear.io/workspace-id: acme-erp
    appgear.io/tenant-id: acme
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ceph-block
  resources:
    requests:
      storage: 10Gi
EOF
```

#### 2.7 Deployment do vCluster com `resources` explícitos

> Shape mínimo compatível com o diagnóstico — em produção, pode-se usar o chart oficial do vCluster, mantendo os mesmos `resources`.

```bash
cat > deployment-vcluster.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vcl-ws-acme-erp
  namespace: vcluster-ws-acme-erp
  labels:
    app.kubernetes.io/name: vcl-ws-acme-erp
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: workspace
    appgear.io/suite: workspace
    appgear.io/topology: B
    appgear.io/workspace-id: acme-erp
    appgear.io/tenant-id: acme
  annotations:
    sidecar.istio.io/inject: "true"
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: vcl-ws-acme-erp
  template:
    metadata:
      labels:
        app.kubernetes.io/name: vcl-ws-acme-erp
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: workspace
        appgear.io/suite: workspace
        appgear.io/topology: B
        appgear.io/workspace-id: acme-erp
        appgear.io/tenant-id: acme
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - name: vcluster-server
          image: loftsh/vcluster:latest
          args:
            - "--name=vcl-ws-acme-erp"
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
          volumeMounts:
            - name: data
              mountPath: /data
        - name: vcluster-syncer
          image: loftsh/vcluster-syncer:latest
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: vcluster-ws-acme-erp-data
EOF
```

> Se usar o **Helm Chart oficial do vCluster**, refletir esses `resources` em `values-vcluster.yaml` (`server.resources`, `syncer.resources`) e renderizar via Argo CD.

#### 2.8 NetworkPolicy – “deny-all” entre workspaces

```bash
cat > networkpolicy-deny-cross-workspaces.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ws-acme-erp-deny-cross-workspaces
  namespace: vcluster-ws-acme-erp
  labels:
    app.kubernetes.io/name: vcl-ws-acme-erp
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: workspace
    appgear.io/suite: workspace
    appgear.io/topology: B
    appgear.io/workspace-id: acme-erp
    appgear.io/tenant-id: acme
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        # Permite tráfego dentro do próprio namespace
        - podSelector: {}
        # Permite tráfego de namespaces Core (istio, segurança, observabilidade)
        - namespaceSelector:
            matchExpressions:
              - key: appgear.io/tier
                operator: In
                values: ["core"]
  egress:
    - {}
EOF
```

#### 2.9 Commit do workspace `acme-erp`

```bash
cd ~/git/appgear-gitops-workspaces
git add workspaces/acme-erp
git commit -m "feat(workspaces): add vcluster and policies for workspace acme-erp"
git push
```

---

### 3. Criar AppProject `appgear-workspaces` no Core (Argo CD)

No repositório `appgear-gitops-core`:

```bash
cd ~/git/appgear-gitops-core
mkdir -p apps/core/workspaces
```

`apps/core/workspaces/argocd-project-workspaces.yaml`:

```bash
cat > apps/core/workspaces/argocd-project-workspaces.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: appgear-workspaces
  namespace: argocd
  labels:
    app.kubernetes.io/name: appgear-workspaces
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io.topology: B
    appgear.io.workspace-id: global
    appgear.io.tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io.module: "mod13-workspaces-vcluster"
spec:
  description: "Projeto Argo CD para gerenciamento GitOps de workspaces/vClusters"
  sourceRepos:
    - git@github.com:appgear/appgear-gitops-workspaces.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: "*"
  clusterResourceWhitelist:
    - group: "*"
      kind: "*"
  namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
EOF
```

Commit:

```bash
git add apps/core/workspaces/argocd-project-workspaces.yaml
git commit -m "feat(core): add appgear-workspaces AppProject"
git push
```

Aplicar no cluster (bootstrap):

```bash
kubectl apply -f apps/core/workspaces/argocd-project-workspaces.yaml -n argocd
```

---

### 4. Criar ApplicationSet `workspaces-appset`

Ainda em `appgear-gitops-core`:

```bash
cat > apps/core/workspaces/workspaces-appset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: workspaces-appset
  namespace: argocd
  labels:
    app.kubernetes.io/name: workspaces-appset
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod13-workspaces-vcluster"
spec:
  generators:
    - git:
        repoURL: git@github.com:appgear/appgear-gitops-workspaces.git
        revision: main
        directories:
          - path: workspaces/*
  template:
    metadata:
      name: ws-{{path.basename}}
      labels:
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: workspace
        appgear.io/suite: workspace
        appgear.io/topology: B
        appgear.io/workspace-id: "{{path.basename}}"
        appgear.io/tenant-id: "unknown"   # definido dentro do workspace-configmap
        appgear.io/contract-version: "v0.1"
        appgear.io/module: "mod13-workspaces-vcluster"
    spec:
      project: appgear-workspaces
      source:
        repoURL: git@github.com:appgear/appgear-gitops-workspaces.git
        targetRevision: main
        path: "{{path}}"
      destination:
        server: https://kubernetes.default.svc
        namespace: vcluster-ws-{{path.basename}}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF
```

Commit:

```bash
git add apps/core/workspaces/workspaces-appset.yaml
git commit -m "feat(core): add workspaces-appset ApplicationSet"
git push
```

Aplicar no cluster:

```bash
kubectl apply -f apps/core/workspaces/workspaces-appset.yaml -n argocd
```

A partir daqui, **qualquer novo diretório** em `appgear-gitops-workspaces/workspaces/<workspace_id>` será descoberto automaticamente e terá um `Application ws-<workspace_id>` criado pelo Argo CD.

---

### 5. Fluxo padrão para criar um novo workspace

1. No repositório `appgear-gitops-workspaces`:

   * Copiar o template de `workspaces/acme-erp` para `workspaces/<workspace_id>`.
   * Ajustar:

     * `workspace-id` e `tenant-id` nos labels;
     * nomes (`vcluster-ws-<workspace_id>`, `vcl-ws-<workspace_id>`);
     * quotas/localidade conforme o cliente.

2. Executar `git add`, `git commit`, `git push`.

3. O `workspaces-appset` detecta o novo diretório e cria automaticamente:

   * `Application ws-<workspace_id>` no Argo CD;
   * Argo aplica os manifests do workspace (Namespace, vCluster, Quotas, NetworkPolicies).

4. O Portal Backstage (M07) deve expor um fluxo que:

   * recebe `tenant_id`, `workspace_id`, `display_name`;
   * Scaffolder copia o template de `appgear-workspace-template` para `appgear-gitops-workspaces/workspaces/<workspace_id>`;
   * faz commit & push (automatizando o passo 1).

---

## 5. Como verificar

### 1. Verificar o ApplicationSet

```bash
kubectl get applicationsets.argoproj.io -n argocd | grep workspaces-appset
kubectl describe applicationset workspaces-appset -n argocd | grep -i error -A3 -B3 || echo "Sem erros aparentes"
```

### 2. Verificar Applications gerados por workspace

```bash
argocd app list | grep ws-
argocd app get ws-acme-erp
```

* Esperado: `ws-acme-erp` com status `Synced` e `Healthy`.

### 3. Verificar recursos no cluster físico

```bash
kubectl get ns | grep vcluster-ws-
kubectl get pvc,deploy,networkpolicy -n vcluster-ws-acme-erp
```

* Esperado:

  * `pvc/vcluster-ws-acme-erp-data`
  * `deployment.apps/vcl-ws-acme-erp`
  * `networkpolicy.networking.k8s.io/ws-acme-erp-deny-cross-workspaces`

### 4. Verificar labels para FinOps

```bash
kubectl get deploy vcl-ws-acme-erp \
  -n vcluster-ws-acme-erp \
  -o jsonpath='{.metadata.labels}' | jq .
```

* Esperado: `appgear.io/tenant-id: acme` e `appgear.io/workspace-id: acme-erp`.

### 5. Verificar NetworkPolicy de isolamento

De outro namespace de workspace (ex.: `vcluster-ws-outro-ws`):

```bash
kubectl run test-client \
  --rm -it \
  --restart=Never \
  --image=alpine \
  -n vcluster-ws-outro-ws \
  -- /bin/sh -c "apk add --no-cache curl && \
  curl -m 5 http://vcl-ws-acme-erp.vcluster-ws-acme-erp.svc.cluster.local:443 || echo 'bloqueado'"
```

* Esperado: timeout ou erro de conexão (bloqueado pela NetworkPolicy), exceto se o namespace tiver labels de Core.

### 6. Verificar uso do vCluster (se CLI `vcluster` instalada)

```bash
vcluster connect vcl-ws-acme-erp -n vcluster-ws-acme-erp -- kubectl get ns
```

* Dentro do vCluster, devem aparecer namespaces internos do workspace (`ws-acme-erp-core`, `ws-acme-erp-factory`, etc.), conforme módulos de Suítes.

---

## 6. Erros comuns

1. **Esquecer de criar o diretório do workspace em `appgear-gitops-workspaces`**

* Sintoma: Backstage mostra workspace, mas Argo CD não cria o app `ws-<workspace_id>`.
* Correção: garantir que o Scaffolder ou o fluxo manual criem `workspaces/<workspace_id>/` com `kustomization.yaml` válido.

2. **Falha no ApplicationSet (erro de acesso ao repositório)**

* Sintoma: `ApplicationSet` reporta “unable to fetch git repo”.
* Causas:

  * `repoURL` incorreto;
  * chave SSH não configurada no Argo CD.
* Correção:

  * ajustar `repoURL` e secret de credenciais no Argo.

3. **Ausência de `appgear.io/tenant-id` ou `workspace-id`**

* Sintoma: relatórios de OpenCost/Lago não mostram custos por workspace.
* Correção:

  * revisar `namespace-host.yaml`, `deployment-vcluster.yaml`, `resourcequota.yaml`, `networkpolicy-*.yaml` e garantir labels obrigatórios.

4. **vCluster sem `resources` definidos (repetição do erro v0)**

* Sintoma: ambientes com muitos workspaces geram overcommit de CPU/memória no cluster físico.
* Correção:

  * ajustar `resources.requests` e `resources.limits` em `deployment-vcluster.yaml` (ou em `values-vcluster.yaml` do chart).

5. **NetworkPolicy permissiva ou ausente**

* Sintoma: um pod de outro workspace acessa serviços de `vcluster-ws-<workspace_id>`.
* Correção:

  * validar `networkpolicy-deny-cross-workspaces.yaml` em cada workspace;
  * garantir que apenas namespaces Core (`appgear.io/tier=core`) tenham permissão de comunicação entre workspaces.

6. **Destino errado no ApplicationSet**

* Sintoma: Argo CD cria recursos do workspace no namespace `default` ou `appgear-core`.
* Correção:

  * checar `destination.namespace` em `workspaces-appset.yaml` (deve usar `vcluster-ws-{{path.basename}}`).

7. **Misturar manifests de workspace em `appgear-gitops-core`**

* Sintoma: diretórios `apps/workspaces` em `appgear-gitops-core` começam a conter configs específicas de clientes.
* Correção:

  * manter **todo** conteúdo de workspace em `appgear-gitops-workspaces`;
  * Core apenas referencia via ApplicationSet.

---

## 7. Onde salvar

1. **Documento de desenvolvimento (contratos)**

* Repositório: `appgear-contracts`.
* Incluir este texto como:

  * `Módulo 13 – Workspaces, vCluster e modelo por cliente v0.1.md`, ou
  * Seção específica em `1 - Desenvolvimento v0.md`:

    * “Módulo 13 – Workspaces, vCluster e modelo por cliente (v0.1)”.

2. **Repositórios GitOps**

* `appgear-gitops-core`:

  * `apps/core/workspaces/argocd-project-workspaces.yaml`;
  * `apps/core/workspaces/workspaces-appset.yaml`;
  * referenciados em `clusters/ag-<regiao>-core-<env>/apps-core.yaml` ou equivalente (M01).

* `appgear-gitops-workspaces`:

  * `README.md`;
  * `workspaces/acme-erp/*` (e demais workspaces), conforme descrito.

3. **Integrações futuras**

* M07 (Backstage):

  * Scaffolder deve usar `appgear-workspace-template` para gerar `workspaces/<workspace_id>/` em `appgear-gitops-workspaces`.
* M14 / Pipelines AI-First (futuro):

  * Pipelines de provisionamento de clientes devem operar exclusivamente via commits em `appgear-gitops-workspaces`, nunca aplicando manifests diretamente via `kubectl`.

---

## 8. Dependências entre os módulos

A posição do **Módulo 13 – Workspaces, vCluster e modelo por cliente** na arquitetura da AppGear é:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * **Pré-requisito direto.**
  * Define:

    * convenções de nomes (`core-*`, `addon-*`, `vcl-ws-*`, `vcluster-ws-*`);
    * forma canônica de artefatos (`*.md`);
    * labels `appgear.io/*` (incluindo `appgear.io/tenant-id`, `appgear.io/workspace-id`);
    * uso de `.env` central (Topologia A) e padrões de FinOps aplicados às labels.

* **Módulo 01 – GitOps e Argo CD (App-of-Apps)**

  * **Pré-requisito direto.**
  * Fornece:

    * Argo CD como controlador GitOps;
    * padrões de `AppProject`, `Application` e `ApplicationSet` utilizados aqui para `appgear-workspaces` e `workspaces-appset`.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Pré-requisito funcional.**
  * Fornece:

    * Istio com mTLS STRICT STRICT, que protege tráfego entre vClusters e serviços Core;
    * topologia de rede padronizada tanto no cluster físico quanto dentro dos vClusters, para ser replicada em templates de Suítes por workspace.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * **Dependência mútua.**
  * M03:

    * coleta métricas de todos os pods, incluindo plano de controle dos vClusters;
    * usa labels `appgear.io/tenant-id` e `appgear.io/workspace-id` para atribuir custos por cliente/workspace.
  * M13:

    * garante que todos os recursos de Workspace/vCluster sejam criados com esses labels;
    * estabelece base para relatórios de custo por workspace e por Suíte dentro de cada workspace.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, Redpanda)**

  * **Pré-requisito técnico.**
  * Fornece:

    * Storage (Ceph) usado pelos PVCs dos vClusters (`ceph-block`);
    * bancos e filas que serão consumidos por workloads rodando dentro de cada vCluster (Suítes Factory, Brain, Ops, Guardian).

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * **Pré-requisito direto.**
  * Fornece:

    * OPA para validar manifests GitOps (labels obrigatórias, proibição de segredos inline, etc.) antes de aplicar workspaces;
    * Vault para segredos específicos de cada tenant/workspace (consumidos pelos serviços dentro do vCluster);
    * Falco monitorando atividades anômalas em pods de vCluster;
    * OpenFGA para políticas de autorização finas em recursos multi-tenant.

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * **Pré-requisito funcional.**
  * Fornece:

    * identidade do usuário contendo `tenant_id` e, quando aplicável, `workspace_ids`;
    * base para que Backstage e APIs determinem qual vCluster/namespace um usuário pode acessar;
    * RBAC por workspace/tenant, refletido em roles de acesso a cada vCluster.

* **Módulo 07 – Portal Backstage e Integrações Core**

  * **Consumidor direto do M13.**
  * Fornece:

    * plugin de Workspaces que:

      * lista workspaces existentes, lendo `appgear-gitops-workspaces`;
      * dispara Scaffolder para criar novos workspaces (comitando em `appgear-gitops-workspaces`);
    * experiência unificada para criação/gestão de workspaces por times internos.

* **Módulos 08, 09, 10, 11, 12 – Suítes (Core Apps, Factory, Brain, Operations, Guardian)**

  * **Consumidores indiretos do M13.**
  * Fornecem:

    * componentes que serão:

      * compartilhados (multi-tenant) no cluster Core; e/ou
      * instanciados dentro dos vClusters por workspace, de acordo com o plano contratado.
  * Dependem do M13 para:

    * saber onde (vcluster/namespace) instanciar suas aplicações em nível de workspace;
    * usar `tenant-id` e `workspace-id` para particionar dados, recursos e custos.

* **Módulo 13 – Workspaces, vCluster e modelo por cliente (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06, M07**;
  * Entrega:

    * a camada de **multi-tenancy lógica e isolada** (por vCluster) para que as Suítes possam ser usadas de forma segura e rastreável por cliente/produto;
    * um **workflow GitOps padronizado** (via `appgear-gitops-workspaces` + `workspaces-appset`) para criação e evolução de workspaces.

* **Módulos posteriores (por exemplo: Pipelines AI-First, Billing avançado, PWA multi-workspace)**

  * **Dependem deste módulo** para:

    * conectar o conceito de “cliente/produto” a workspaces/vClusters concretos;
    * orquestrar provisionamento, upgrades e desligamentos de ambientes completos por cliente, via GitOps.

Em fluxo:

**M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → (M08–M12 Suítes) → M13 → (Pipelines, Billing, PWA, etc.)**

Sem o Módulo 13, a AppGear não teria um modelo padronizado e escalável de **Workspaces e vClusters por cliente**, dificultando o multi-tenancy isolado, a governança GitOps e o rastreamento de custos por cliente/produto.

---

## 9. Metadados
- Gerado automaticamente por CodeGPT
- Versão do módulo: v0.3
- Compatibilidade: full
- Data de geração: 2025-11-24
