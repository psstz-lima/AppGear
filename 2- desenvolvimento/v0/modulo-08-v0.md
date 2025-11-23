Segue o **Módulo 08** totalmente reescrito, já com os ajustes:

* Formato **Markdown** (substitui a versão `.py`);
* **Sem IngressRoute/Traefik direto** para os serviços (exposição só via **Kong** com `ingressClassName: kong`);
* **Sem imagens `:latest`** (uso de tags placeholder `vX.Y.Z` para serem fixadas no pipeline);
* **Integração limpa com Módulo 05**: Vault como SSoT, serviços consumindo DB/segredos via `Secret` (criados a partir do Vault) e sem segredos em Git;
* **Labels FinOps/OPA** completas, incluindo `appgear.io/tenant-id: global`;
* **resources.requests/limits** definidos para todos os serviços Core.

Você pode salvar este conteúdo como:

* `Módulo 08 v0.2.md`
  e/ou
* substituir a seção do Módulo 08 no `1 - Desenvolvimento v0.md`.

---

# Módulo 08 – Serviços de Aplicação Core (LiteLLM, Flowise, N8n, BPMN, Directus, Appsmith, Metabase) – v0.2

> Este módulo define e implanta os **Serviços de Aplicação Core** da plataforma AppGear, em **Topologia B (Kubernetes + GitOps)**:
>
> * IA & Agentes: **LiteLLM** (Gateway de IA), **Flowise** (orquestrador de agentes/Translation Layer);
> * Automação: **N8n** (workflows AI-First), **BPMN/Camunda** (processos humanos);
> * Dados & UI: **Directus** (SSoT de negócio), **Appsmith** (UI low-code), **Metabase** (BI).
>
> Esta versão v0.2:
>
> * Converte o módulo para **Markdown**;
> * Remove o uso direto de **IngressRoute/Traefik** (sem bypass do WAF/Gateway);
> * Exige que o tráfego público passe por **Traefik → Coraza → Kong → Serviços Core**;
> * Garante labels de FinOps (`appgear.io/tenant-id: global`) e `resources.requests/limits` em todos os serviços;
> * Alinha a integração de segredos com o **Módulo 05 (Vault, OPA, Falco, OpenFGA)**.

---

## 1. O que é

Este módulo descreve a **infraestrutura** para a camada de **Serviços de Aplicação Core**:

1. **Serviços Core no namespace `appgear-core`**

   * `core-litellm` – Gateway único de IA (OpenAI, Ollama, etc.);
   * `core-flowise` – Orquestrador de agentes, pipelines e RAG;
   * `core-n8n` – Motor de automação e AI-First Generator;
   * `core-bpmn` – Camunda (motor BPMN para processos humanos);
   * `core-directus` – Headless CMS / SSoT de negócio;
   * `core-appsmith` – Low-code UI;
   * `core-metabase` – BI.

2. **Exposição via Kong (Gateway/API)**

   * Rotas criadas **no Kong**, usando `Ingress` com `ingressClassName: kong`;
   * Prefixos lógicos fixos:

     * `/flowise`, `/n8n`, `/directus`, `/appsmith`, `/bi`, `/bpmn`;
   * Nenhum serviço Core é exposto via `IngressRoute` direto ao Traefik.

3. **Integrações principais**

   * IA:

     * Todos os consumidores (Flowise, N8n, Backstage, Apps) chamam **LiteLLM**;
     * LiteLLM, por sua vez, fala com OpenAI/Ollama/LLMs configurados.
   * Dados:

     * Flowise, N8n, Directus, Metabase usam bancos no `core-postgres`;
     * Qdrant, Redis, RabbitMQ/Redpanda conforme cada serviço.
   * Segurança:

     * Segredos vêm do **Vault** (M05), replicados para K8s via mecanismos definidos lá;
     * OPA valida manifests (labels, ausência de segredos estáticos, imagens não `:latest`);
     * Falco observa runtime;
     * Keycloak (M06) proverá SSO para Directus/Appsmith/N8n etc.

4. **FinOps & Governança**

   * Label `appgear.io/tenant-id: global` garante rastreabilidade do custo das “fábricas de IA/automação”;
   * `resources.requests/limits` evitam que IA/automação derrube o cluster em caso de pico de carga.

---

## 2. Por que

1. **Segurança de Borda (evitar bypass)**

   * A cadeia definida no Módulo 02 é:

     * **Entrada → Traefik → Coraza (WAF) → Kong (API Gateway) → Serviços Core**.
   * IngressRoute direto no Traefik para Flowise/N8n/etc. **quebraria** a cadeia, expondo apps sem WAF/API Gateway.
   * Este módulo garante que:

     * Traefik só conhece `core-coraza`/`core-kong`;
     * Kong conhece `/flowise`, `/n8n`, `/directus`, `/appsmith`, `/bi`, `/bpmn`.

2. **LiteLLM como Gateway Único de IA**

   * Evita:

     * chaves OpenAI/Anthropic/etc. espalhadas em dezenas de serviços;
     * políticas de acesso/modelos duplicadas;
     * observabilidade fragmentada de uso de IA.
   * Centraliza:

     * billing por tenant/projeto;
     * logs de prompts/respostas (conforme LGPD/segurança);
     * lista de modelos autorizados.

3. **FinOps / OPA / Vault (M05)**

   * M05 define que:

     * Vault é SSoT (`kv/appgear/...`, `database/creds/postgres-role-*`);
     * OPA exige labels `appgear.io/*` e **proíbe segredos estáticos e imagens `:latest`**;
     * Segurança também deve ter `resources` para não impactar o cluster.
   * M08 segue isso para os serviços de aplicação:

     * labels completas em todos os objetos;
     * `resources` em todos os Deployments;
     * nenhuma senha/chave em manifesto GitOps.

4. **SSoT de Dados e UI Base**

   * Directus como SSoT de esquemas de dados operacionais;
   * Metabase como camada de BI;
   * Appsmith como fábrica de UIs operacionais sobre estes dados e APIs roteadas via Kong.

---

## 3. Pré-requisitos

### 3.1 Módulos anteriores

* **M00 v0.1** – Convenções, labels obrigatórias, nomenclatura;
* **M01** – GitOps/Argo CD (Application `core-app-services` apontando para `apps/core/app-services`);
* **M02** – Rede/Borda (Traefik, Coraza, Kong, Istio, ingresses globais);
* **M03** – Observabilidade/FinOps (Prometheus, Grafana, Loki, OpenCost, Lago);
* **M04** – Storage e Bancos Core (Ceph, Postgres, Redis, Qdrant, RabbitMQ, Redpanda);
* **M05 v0.1** – Segurança e Segredos (Vault, OPA, Falco, OpenFGA);
* **M06** – Identidade/SSO (Keycloak, midPoint, clientes OIDC);
* **M07** – Portal Backstage (vai consumir estes serviços e exibi-los na App Store interna).

### 3.2 Infraestrutura (Topologia B – Kubernetes)

* Cluster `ag-<regiao>-core-<env>` (ex.: `ag-br-core-dev`);
* Namespaces:

  * `appgear-core` (este módulo);
  * `security`, `observability`, `argocd` já criados.
* Serviços básicos já implantados:

  * `core-postgres`, `core-redis`, `core-qdrant`, `core-rabbitmq`, `core-redpanda`;
  * `core-ollama`, `core-kong`, `core-coraza`, `core-traefik`;
  * `core-keycloak`, `core-vault`, `core-opa`, `core-falco`, `core-openfga`.
* Istio com injeção automática ativada no namespace `appgear-core`.

### 3.3 Vault / Segredos (M05)

* Vault com engines:

  * `kv/appgear/...`;
  * `database/creds/postgres-role-*`;
  * `auth/kubernetes` habilitado.
* Secrets esperados (criadas a partir do Vault, via ExternalSecrets ou jobs definidos no M05/M04), por exemplo:

  * `core-flowise-db` (URL ou user/password para DB Flowise);
  * `core-n8n-db` (credenciais DB do N8n);
  * `core-directus-db`, `core-metabase-db`, `core-appsmith-db`;
  * `core-litellm-openai` (chave(s) OpenAI/LLM externas).

### 3.4 Topologia A (Docker – opcional/dev)

* Servidor Linux com Docker + docker-compose;
* Diretório base `/opt/webapp-ia` com `.env` central de desenvolvimento (não produção).

---

## 4. Como fazer (comandos)

### 4.1 Estrutura GitOps do módulo

No repositório `webapp-ia-gitops-core`:

```bash
cd webapp-ia-gitops-core

mkdir -p apps/core/{app-services,litellm,flowise,n8n,bpmn,directus,appsmith,metabase}
```

#### 4.1.1 Agregador `apps/core/app-services/kustomization.yaml`

```bash
cat > apps/core/app-services/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - ../litellm
  - ../flowise
  - ../n8n
  - ../bpmn
  - ../directus
  - ../appsmith
  - ../metabase

commonLabels:
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

> O `Application` Argo CD `core-app-services` (Módulo 01) deve apontar para este diretório.

---

### 4.2 `core-litellm` – Gateway Único de IA

#### 4.2.1 Kustomization

```bash
cat > apps/core/litellm/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - configmap.yaml
  - deployment.yaml
  - service.yaml

commonLabels:
  app.kubernetes.io/name: core-litellm
  app.kubernetes.io/component: litellm
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

#### 4.2.2 ConfigMap

```bash
cat > apps/core/litellm/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-litellm-config
  namespace: appgear-core
data:
  config.yaml: |
    model_list:
      - model_name: gpt4o
        litellm_params:
          model: openai/gpt-4o
          api_key: "os.environ/OPENAI_API_KEY"
      - model_name: local-llama3
        litellm_params:
          model: ollama/llama3
          api_base: http://core-ollama.appgear-core.svc.cluster.local:11434
          api_key: "dummy-key"
    litellm_settings:
      drop_params: true
EOF
```

#### 4.2.3 Deployment

```bash
cat > apps/core/litellm/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-litellm
  namespace: appgear-core
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-litellm
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-litellm
        appgear.io/tier: core
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: litellm
          image: ghcr.io/berriai/litellm:vX.Y.Z   # ajustar tag real (não usar :latest)
          imagePullPolicy: IfNotPresent
          args:
            - "--config"
            - "/etc/litellm/config.yaml"
            - "--port"
            - "4000"
          ports:
            - containerPort: 4000
              name: http
          env:
            - name: LITELLM_CONFIG
              value: "/etc/litellm/config.yaml"
            - name: LITELLM_PORT
              value: "4000"
            - name: OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: core-litellm-openai
                  key: api_key
          volumeMounts:
            - name: litellm-config
              mountPath: /etc/litellm
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "4Gi"
      volumes:
        - name: litellm-config
          configMap:
            name: core-litellm-config
            items:
              - key: config.yaml
                path: config.yaml
EOF
```

#### 4.2.4 Service

```bash
cat > apps/core/litellm/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-litellm
  namespace: appgear-core
spec:
  selector:
    app.kubernetes.io/name: core-litellm
  ports:
    - name: http
      port: 4000
      targetPort: 4000
EOF
```

> LiteLLM é consumido internamente (Flowise, N8n, Backstage, etc.) e pelo Kong; **não há Ingress/IngressRoute aqui**.

---

### 4.3 `core-flowise` – Orquestrador de IA

#### 4.3.1 Kustomization

```bash
cat > apps/core/flowise/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - deployment.yaml
  - service.yaml
  - ingress-kong.yaml

commonLabels:
  app.kubernetes.io/name: core-flowise
  app.kubernetes.io/component: flowise
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

#### 4.3.2 Deployment

```bash
cat > apps/core/flowise/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-flowise
  namespace: appgear-core
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-flowise
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-flowise
        appgear.io/tier: core
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: flowise
          image: flowiseai/flowise:vX.Y.Z   # ajustar tag real
          imagePullPolicy: IfNotPresent
          env:
            - name: PORT
              value: "3000"
            - name: LITELLM_BASE_URL
              value: "http://core-litellm.appgear-core.svc.cluster.local:4000"
            - name: DATABASE_TYPE
              value: "postgres"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: core-flowise-db
                  key: url
            - name: VECTORSTORE_QDRANT_URL
              value: "http://core-qdrant.appgear-core.svc.cluster.local:6333"
          ports:
            - containerPort: 3000
              name: http
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "4Gi"
EOF
```

#### 4.3.3 Service

```bash
cat > apps/core/flowise/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-flowise
  namespace: appgear-core
spec:
  selector:
    app.kubernetes.io/name: core-flowise
  ports:
    - name: http
      port: 3000
      targetPort: 3000
EOF
```

#### 4.3.4 Ingress (Kong – `/flowise`)

```bash
cat > apps/core/flowise/ingress-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: core-flowise-kong
  namespace: appgear-core
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
    - host: core.dev.appgear.local
      http:
        paths:
          - path: /flowise
            pathType: Prefix
            backend:
              service:
                name: core-flowise
                port:
                  number: 3000
EOF
```

> Traefik vê apenas o host geral; quem resolve `/flowise` é o Kong, preservando a cadeia de segurança.

---

### 4.4 `core-n8n` – Automação / AI-First Generator

#### 4.4.1 Kustomization

```bash
cat > apps/core/n8n/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - deployment.yaml
  - service.yaml
  - ingress-kong.yaml

commonLabels:
  app.kubernetes.io/name: core-n8n
  app.kubernetes.io/component: n8n
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

#### 4.4.2 Deployment

```bash
cat > apps/core/n8n/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-n8n
  namespace: appgear-core
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-n8n
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-n8n
        appgear.io/tier: core
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: n8n
          image: n8nio/n8n:vX.Y.Z     # ajustar tag real
          imagePullPolicy: IfNotPresent
          env:
            - name: N8N_PORT
              value: "5678"
            - name: N8N_PROTOCOL
              value: "https"
            - name: N8N_HOST
              value: "core.dev.appgear.local"
            - name: DB_TYPE
              value: "postgresdb"
            - name: DB_POSTGRESDB_HOST
              value: "core-postgres.appgear-core.svc.cluster.local"
            - name: DB_POSTGRESDB_PORT
              value: "5432"
            - name: DB_POSTGRESDB_DATABASE
              value: "n8n_core"
            - name: DB_POSTGRESDB_USER
              valueFrom:
                secretKeyRef:
                  name: core-n8n-db
                  key: username
            - name: DB_POSTGRESDB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: core-n8n-db
                  key: password
            - name: QUEUE_BULL_REDIS_HOST
              value: "core-redis.appgear-core.svc.cluster.local"
            - name: QUEUE_BULL_REDIS_PORT
              value: "6379"
            - name: LITELLM_BASE_URL
              value: "http://core-litellm.appgear-core.svc.cluster.local:4000"
          ports:
            - containerPort: 5678
              name: http
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "2Gi"
EOF
```

#### 4.4.3 Service

```bash
cat > apps/core/n8n/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-n8n
  namespace: appgear-core
spec:
  selector:
    app.kubernetes.io/name: core-n8n
  ports:
    - name: http
      port: 5678
      targetPort: 5678
EOF
```

#### 4.4.4 Ingress (Kong – `/n8n`)

```bash
cat > apps/core/n8n/ingress-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: core-n8n-kong
  namespace: appgear-core
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
    - host: core.dev.appgear.local
      http:
        paths:
          - path: /n8n
            pathType: Prefix
            backend:
              service:
                name: core-n8n
                port:
                  number: 5678
EOF
```

---

### 4.5 `core-bpmn` – Camunda (Processos Humanos)

#### 4.5.1 Kustomization

```bash
cat > apps/core/bpmn/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - deployment.yaml
  - service.yaml
  - ingress-kong.yaml

commonLabels:
  app.kubernetes.io/name: core-bpmn
  app.kubernetes.io/component: camunda
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

#### 4.5.2 Deployment

```bash
cat > apps/core/bpmn/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-bpmn
  namespace: appgear-core
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-bpmn
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-bpmn
        appgear.io/tier: core
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: camunda
          image: camunda/camunda-bpm-platform:run-vX.Y.Z  # ajustar tag real
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "2Gi"
EOF
```

#### 4.5.3 Service

```bash
cat > apps/core/bpmn/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-bpmn
  namespace: appgear-core
spec:
  selector:
    app.kubernetes.io/name: core-bpmn
  ports:
    - name: http
      port: 8080
      targetPort: 8080
EOF
```

#### 4.5.4 Ingress (Kong – `/bpmn`)

```bash
cat > apps/core/bpmn/ingress-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: core-bpmn-kong
  namespace: appgear-core
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
    - host: core.dev.appgear.local
      http:
        paths:
          - path: /bpmn
            pathType: Prefix
            backend:
              service:
                name: core-bpmn
                port:
                  number: 8080
EOF
```

---

### 4.6 `core-directus` – SSoT de Negócio

#### 4.6.1 Kustomization

```bash
cat > apps/core/directus/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - deployment.yaml
  - service.yaml
  - ingress-kong.yaml

commonLabels:
  app.kubernetes.io/name: core-directus
  app.kubernetes.io/component: directus
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

#### 4.6.2 Deployment

```bash
cat > apps/core/directus/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-directus
  namespace: appgear-core
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-directus
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-directus
        appgear.io/tier: core
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: directus
          image: directus/directus:vX.Y.Z          # ajustar tag real
          imagePullPolicy: IfNotPresent
          env:
            - name: PORT
              value: "8055"
            - name: DB_CLIENT
              value: "pg"
            - name: DB_HOST
              value: "core-postgres.appgear-core.svc.cluster.local"
            - name: DB_PORT
              value: "5432"
            - name: DB_DATABASE
              value: "directus_core"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: core-directus-db
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: core-directus-db
                  key: password
            - name: SECRET
              valueFrom:
                secretKeyRef:
                  name: core-directus-auth
                  key: secret
          ports:
            - containerPort: 8055
              name: http
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "2Gi"
EOF
```

#### 4.6.3 Service

```bash
cat > apps/core/directus/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-directus
  namespace: appgear-core
spec:
  selector:
    app.kubernetes.io/name: core-directus
  ports:
    - name: http
      port: 8055
      targetPort: 8055
EOF
```

#### 4.6.4 Ingress (Kong – `/directus`)

```bash
cat > apps/core/directus/ingress-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: core-directus-kong
  namespace: appgear-core
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
    - host: core.dev.appgear.local
      http:
        paths:
          - path: /directus
            pathType: Prefix
            backend:
              service:
                name: core-directus
                port:
                  number: 8055
EOF
```

---

### 4.7 `core-appsmith` – UI Low-code

#### 4.7.1 Kustomization

```bash
cat > apps/core/appsmith/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - deployment.yaml
  - service.yaml
  - ingress-kong.yaml

commonLabels:
  app.kubernetes.io/name: core-appsmith
  app.kubernetes.io/component: appsmith
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

#### 4.7.2 Deployment

```bash
cat > apps/core/appsmith/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-appsmith
  namespace: appgear-core
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-appsmith
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-appsmith
        appgear.io/tier: core
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: appsmith
          image: appsmith/appsmith-ce:vX.Y.Z    # ajustar tag real
          imagePullPolicy: IfNotPresent
          env:
            - name: APPSMITH_DB_URL
              valueFrom:
                secretKeyRef:
                  name: core-appsmith-db
                  key: url
            - name: APPSMITH_REDIS_URL
              value: "redis://core-redis.appgear-core.svc.cluster.local:6379"
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1.5Gi"
EOF
```

#### 4.7.3 Service

```bash
cat > apps/core/appsmith/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-appsmith
  namespace: appgear-core
spec:
  selector:
    app.kubernetes.io/name: core-appsmith
  ports:
    - name: http
      port: 8080
      targetPort: 8080
EOF
```

#### 4.7.4 Ingress (Kong – `/appsmith`)

```bash
cat > apps/core/appsmith/ingress-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: core-appsmith-kong
  namespace: appgear-core
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
    - host: core.dev.appgear.local
      http:
        paths:
          - path: /appsmith
            pathType: Prefix
            backend:
              service:
                name: core-appsmith
                port:
                  number: 8080
EOF
```

---

### 4.8 `core-metabase` – BI

#### 4.8.1 Kustomization

```bash
cat > apps/core/metabase/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - deployment.yaml
  - service.yaml
  - ingress-kong.yaml

commonLabels:
  app.kubernetes.io/name: core-metabase
  app.kubernetes.io/component: metabase
  app.kubernetes.io/part-of: appgear
  appgear.io/tier: core
  appgear.io/suite: core
  appgear.io/topology: B
  appgear.io/workspace-id: global
  appgear.io/tenant-id: global

commonAnnotations:
  appgear.io/contract-version: "v0.2"
  appgear.io/module: "mod8-core-app-services"
EOF
```

#### 4.8.2 Deployment

```bash
cat > apps/core/metabase/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-metabase
  namespace: appgear-core
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-metabase
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-metabase
        appgear.io/tier: core
        appgear.io/tenant-id: global
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      serviceAccountName: core-services
      containers:
        - name: metabase
          image: metabase/metabase:vX.Y.Z   # ajustar tag real
          imagePullPolicy: IfNotPresent
          env:
            - name: MB_DB_TYPE
              value: "postgres"
            - name: MB_DB_HOST
              value: "core-postgres.appgear-core.svc.cluster.local"
            - name: MB_DB_PORT
              value: "5432"
            - name: MB_DB_DBNAME
              value: "metabase_core"
            - name: MB_DB_USER
              valueFrom:
                secretKeyRef:
                  name: core-metabase-db
                  key: username
            - name: MB_DB_PASS
              valueFrom:
                secretKeyRef:
                  name: core-metabase-db
                  key: password
          ports:
            - containerPort: 3000
              name: http
          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "2Gi"
EOF
```

#### 4.8.3 Service

```bash
cat > apps/core/metabase/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-metabase
  namespace: appgear-core
spec:
  selector:
    app.kubernetes.io/name: core-metabase
  ports:
    - name: http
      port: 3000
      targetPort: 3000
EOF
```

#### 4.8.4 Ingress (Kong – `/bi`)

```bash
cat > apps/core/metabase/ingress-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: core-metabase-kong
  namespace: appgear-core
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
    - host: core.dev.appgear.local
      http:
        paths:
          - path: /bi
            pathType: Prefix
            backend:
              service:
                name: core-metabase
                port:
                  number: 3000
EOF
```

---

### 4.9 Commit e sincronização via Argo CD

```bash
cd webapp-ia-gitops-core

git add apps/core/app-services \
        apps/core/litellm \
        apps/core/flowise \
        apps/core/n8n \
        apps/core/bpmn \
        apps/core/directus \
        apps/core/appsmith \
        apps/core/metabase

git commit -m "mod8 v0.2: core app services via Kong, FinOps labels, resources e integ. com M05"
git push origin main
```

Argo CD:

```bash
argocd app get core-app-services
argocd app sync core-app-services   # se não estiver Synced/Healthy
```

---

### 4.10 Topologia A – docker-compose (dev / legado)

```bash
cd /opt/webapp-ia

cat > docker-compose.core-app-services.yml << 'EOF'
version: "3.9"
services:
  litellm:
    image: ghcr.io/berriai/litellm:vX.Y.Z
    ports:
      - "4000:4000"
    environment:
      - LITELLM_PORT=4000

  flowise:
    image: flowiseai/flowise:vX.Y.Z
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - LITELLM_BASE_URL=http://litellm:4000

  n8n:
    image: n8nio/n8n:vX.Y.Z
    ports:
      - "5678:5678"
    environment:
      - N8N_PORT=5678

  directus:
    image: directus/directus:vX.Y.Z
    ports:
      - "8055:8055"

  appsmith:
    image: appsmith/appsmith-ce:vX.Y.Z
    ports:
      - "8080:8080"

  metabase:
    image: metabase/metabase:vX.Y.Z
    ports:
      - "3001:3000"
EOF
```

> Este compose é apenas para laboratório/dev; não há WAF, Kong ou Vault completos.

---

## 5. Como verificar

1. **Argo CD**

   ```bash
   argocd app get core-app-services
   ```

   * Esperado: `Sync Status: Synced`, `Health Status: Healthy`.

2. **Pods/Services no namespace `appgear-core`**

   ```bash
   kubectl get pods -n appgear-core -l appgear.io/module=mod8-core-app-services
   kubectl get svc -n appgear-core | egrep 'litellm|flowise|n8n|bpmn|directus|appsmith|metabase'
   ```

3. **Ingress (Kong)**

   ```bash
   kubectl get ingress -n appgear-core
   ```

   * Deve listar `core-*-kong` com `ingressClassName: kong`.
   * `kubectl get ingressroute -A` não deve mostrar Flowise/N8n/etc. (sem bypass).

4. **Testes HTTP via cadeia Traefik → Coraza → Kong**

   De uma máquina com DNS para `core.dev.appgear.local`:

   ```bash
   curl -k https://core.dev.appgear.local/flowise/ -I
   curl -k https://core.dev.appgear.local/n8n/ -I
   curl -k https://core.dev.appgear.local/directus/ -I
   curl -k https://core.dev.appgear.local/appsmith/ -I
   curl -k https://core.dev.appgear.local/bi/ -I
   curl -k https://core.dev.appgear.local/bpmn/ -I
   ```

5. **Teste de LiteLLM como gateway**

   ```bash
   kubectl -n appgear-core run litellm-test --rm -it --image=curlimages/curl -- \
     curl -s http://core-litellm:4000/v1/models
   ```

   E um teste de chat:

   ```bash
   kubectl -n appgear-core run litellm-chat-test --rm -it --image=curlimages/curl -- \
     curl -s http://core-litellm:4000/chat/completions \
       -H "Content-Type: application/json" \
       -d '{"model":"local-llama3","messages":[{"role":"user","content":"Teste M08 v0.2"}]}'
   ```

6. **Observabilidade & FinOps**

   * No Grafana, verificar dashboards dos pods `core-*`;
   * No OpenCost/Lago, filtrar por `appgear.io/module=mod8-core-app-services` e `tenant-id=global`;
   * No Loki, verificar logs de chamdas LLM/Workflows.

---

## 6. Erros comuns

1. **IngressRoute ainda presente para M08**

   * Problema: bypass do WAF/Gateway; viola M02 e auditoria.
   * Correção: remover todos os `IngressRoute` de Flowise, N8n, etc. Usar apenas `Ingress` com `ingressClassName: kong`.

2. **Uso de `:latest` nas imagens**

   * Problema: OPA/pipelines vão bloquear; difícil rastrear que versão está rodando.
   * Correção: fixar tags (`vX.Y.Z`) para cada imagem e ajustar no GitOps.

3. **Falta de `appgear.io/tenant-id` em algum recurso**

   * Problema: policy de OPA pode negar; FinOps não enxerga custo.
   * Correção: garantir que `commonLabels` do Kustomize incluam `appgear.io/tenant-id: global` e que os templates de pod herdem isso.

4. **Segredos definidos “na mão” no M08**

   * Problema: contraria M05; segredos em Git podem ser bloqueados pelo OPA.
   * Correção: manter segredos apenas como `secretKeyRef` para Secrets gerados a partir do Vault; não criar `Secret` com `data:` neste módulo.

5. **Flowise/N8n chamando LLM direto (sem LiteLLM)**

   * Problema: quebra do contrato do Gateway de IA; espalha chaves de LLM.
   * Correção: garantir que todas as configurações de LLM em Flowise/N8n usem `LITELLM_BASE_URL` e modelos definidos no LiteLLM.

6. **Conflito com SSO (M06)**

   * Sintoma: login “local” em Directus/Appsmith quando a política é usar Keycloak.
   * Correção: configurar clientes OIDC no Keycloak e variáveis de ambiente específicas (AUTH/SSO) para esses serviços no M06; o M08 só precisa garantir que os pods estão disponíveis e rotas existem.

---

## 7. Onde salvar

* **Repositório GitOps principal (`webapp-ia-gitops-core`)**:

  * `apps/core/app-services/kustomization.yaml`
  * `apps/core/litellm/{kustomization.yaml,configmap.yaml,deployment.yaml,service.yaml}`
  * `apps/core/flowise/{kustomization.yaml,deployment.yaml,service.yaml,ingress-kong.yaml}`
  * `apps/core/n8n/{kustomization.yaml,deployment.yaml,service.yaml,ingress-kong.yaml}`
  * `apps/core/bpmn/{kustomization.yaml,deployment.yaml,service.yaml,ingress-kong.yaml}`
  * `apps/core/directus/{kustomization.yaml,deployment.yaml,service.yaml,ingress-kong.yaml}`
  * `apps/core/appsmith/{kustomization.yaml,deployment.yaml,service.yaml,ingress-kong.yaml}`
  * `apps/core/metabase/{kustomization.yaml,deployment.yaml,service.yaml,ingress-kong.yaml}`

* **Documentação do módulo**:

  * Arquivo: `Módulo 08 v0.2.md`
  * Referência a partir de: `1 - Desenvolvimento v0.md` na seção do Módulo 08.

Se quiser, no próximo passo posso gerar um **diff textual** (estilo patch) entre o M08 v0.1 e este v0.2, destacando exatamente os pontos corrigidos para facilitar a auditoria (G15, G05, M00-3, M08-1).