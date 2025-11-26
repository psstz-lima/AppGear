# M12 – Suíte Guardian (Security Suite, Legal AI, Chaos, App Store) (v0.3)

> [!IMPORTANT]
> Este documento define o **Módulo 12 (M12)** da arquitetura AppGear na linha v0.3.  
> Deve ser lido em conjunto com:
> - `docs/architecture/contract/contract-v0.md`
> - `docs/architecture/audit/audit-v0.md`
> - `docs/architecture/interoperability/interoperability-v0.md`
> - `docs/architecture/interoperability/resources/fluxos-ai-first.md`
> - `docs/architecture/interoperability/resources/mapa-global.md`

Versão do módulo: v0.3  
Compatibilidade: linha v0 / v0.3  

---

> **Metadados v0.3**  
> version: v0.3 — schema: appgear-stack — compatibility: full  
> baseline: `development/v0.3/stack-unificada-v0.3.yaml`

## Contexto v0.3

### Padronização v0.3

- `.env` centralizado em `/opt/appgear/.env` (Topologia A) ou segredos via Vault/ExternalSecrets (Topologia B); apenas `.env.example` permanece versionado.
- Cadeia obrigatória `Traefik (TLS passthrough SNI) → Coraza WAF → Kong → Istio IngressGateway → Service Mesh` com mTLS **STRICT**, registrando exceções no quadro de monitoramento.
- Stack integrada sob controle GitOps via ArgoCD com **ApplicationSet list-generator** e labels `appgear.io/*`; App-of-Apps fica restrito ao bootstrap do Argo CD.
- Trilha CI/CD v1.1 com MAPA_NC → PLANO_CORRECAO → MODULO_REESCRITO → CHECKLIST e artefatos em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` com hash SHA-256 de SBOM.

---

# Módulo 12 – Suíte Guardian

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

- Guardian: segurança/compliance/chaos com Tika/Gotenberg/SignServer e validações OPA/Falco do M05.


### Premissas padrão (v0.3)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Foca em segurança operacional, caos e conformidade contínua.
Engloba testes de caos, scanners, validações de segurança, controles de postura e integrações com Falco/OPA/OpenFGA. 

---

## 1. O que é

A **Suíte Guardian** é a suíte de **Security & Governance** da AppGear, responsável por prover segurança de aplicação, governança de apps, legal/compliance e plataformas de caos/resiliência, de forma **cross-cutting** para todas as demais suítes e workspaces.

Ela é composta por quatro blocos principais:

1. **Security Suite**

   * **Pentest AI** (`addon-guardian-pentest-ai`):

     * Orquestra scanners (ZAP, Nuclei, Trivy, etc.);
     * Usa LLMs (via Brain/M08) para interpretar resultados e gerar relatórios em linguagem de negócio.
   * **Browser Isolation** (`addon-guardian-browser-isolation`):

     * Navegador remoto isolado, acessado via HTTP, para navegação segura.

2. **Legal AI & Compliance**

   * **Core (Módulo 4)**:

     * `core-tika`: extração de texto de documentos;
     * `core-gotenberg`: normalização/conversão de documentos (PDF, etc.);
     * `core-signserver`: assinatura digital.
   * **Add-on Guardian**:

     * `addon-guardian-legal-ai`: API que usa Tika + Gotenberg + LLM para:

       * revisão contratual;
       * resumo de riscos;
       * apoio a compliance de licenças (via SBOM/Syft/Trivy).

3. **Chaos / Resilience**

   * `guardian-chaos` (LitmusChaos ou equivalente):

     * Experimentos do tipo `pod-delete`, `network-latency`, `cpu-hog`, etc.;
     * Nunca exposto diretamente via Traefik; acesso apenas:

       * via `Ingress` com `ingressClassName: kong` + OIDC (Keycloak), ou
       * via `kubectl port-forward` em contexto de segurança administrativa.

4. **Guardian App Store Policy**

   * **UI**: plugin da **Private App Store do Backstage** (M07);
   * **API**: `addon-guardian-appstore-policy`, serviço interno que consulta:

     * Legal AI (riscos contratuais/licenças),
     * Pentest AI (estado de risco de segurança),
     * FinOps (OpenCost/Lago),
     * IGA (midPoint), RBAC/ReBAC (Keycloak/OpenFGA),
   * e decide se um app/workspace é **aprovado**, **pendente** ou **negado**.

5. **Cross-cutting com Workspaces (M13)**

   * Guardian é **transversal**:

     * M13 poderá injetar sidecars/agents de segurança em workspaces que contratem o pacote Guardian;
     * Essa injeção é dirigida por labels/annotations definidas neste módulo.

---

## 2. Por que

### 1. Atender ao diagnóstico v0 (forma, segurança, FinOps, recursos) 

Principais problemas do artefato anterior:

1. **G15 – Forma Canônica**

   * O módulo estava em `.py`, não em `.md`, quebrando o padrão de documentação.

2. **G05 – Segurança de Borda (Crítico)**

   * Pentest e Chaos eram propostos com **IngressRoute direto no Traefik**, bypassando:

     * Traefik → Coraza (WAF) → Kong (API Gateway) → Istio (mTLS STRICT).
   * Expor ferramentas de pentest/chaos sem OIDC/RBAC central gera risco extremo.

3. **M00-3 – FinOps (Crítico)**

   * Ausência de `appgear.io/tenant-id` nos manifests da suíte:

     * Impedia atribuição de custo de scanners, browser isolation e chaos experiments por tenant/cliente.

4. **M00-3 – `resources` em workloads pesados**

   * Workloads como Browser Isolation (navegador), scanners e chaos pod estavam sem `requests/limits`, favorecendo:

     * overcommit do cluster;
     * impacto de uma única execução sobre nó inteiro.

5. **Interoperabilidade com App Store, Rede, Segurança e Workspaces**

   * App Store estava pouco integrada com Backstage (poderia virar app separado);
   * Chaos exposto sem definitivos controles de autenticação;
   * Não havia padrão claro para o M13 injetar segurança em workspaces.

### 2. Como o v0.1 resolve

* **Formato**

  * Este módulo é entregue em **Markdown**: `Módulo 12 – Suíte Guardian v0.1.md`.

* **Borda / Kong / Istio**

  * Pentest, Chaos e Browser Isolation:

    * Não possuem IngressRoute próprio;
    * Quando expostos, são via `Ingress` com `ingressClassName: kong` + plugins OIDC (Keycloak);
    * Mantêm a cadeia M02: **Traefik → Coraza → Kong → Istio**.

* **FinOps**

  * Todos exemplos de manifests Guardian trazem:

    * `appgear.io/tenant-id` (`global` ou `tenant-<id>`);
    * `appgear.io/suite: guardian`.
  * Isso permite:

    * Relatórios de custo por suíte e por tenant.

* **Resources**

  * Browser Isolation, Pentest e Chaos usam `requests/limits` explícitos adequados para workloads pesados;
  * Evita saturação de nós por uso indevido.

* **App Store e Workspaces**

  * UI da App Store permanece como **plugin Backstage** (não app separado);
  * Backend consulta a API Guardian Policy;
  * M13 poderá injetar sidecars em pods que tenham annotations `guardian.appgear.io/enabled=true`.

---

## 3. Pré-requisitos

### Organizacionais

* Contrato v0 aprovado como base da arquitetura. 
* Módulos 0 a 11 disponíveis em versão v0.1 (ou em retrofit), em especial:

  * **M00** – Convenções, labels `appgear.io/*`, FinOps;
  * **M01** – GitOps/Argo CD;
  * **M02** – Rede e Borda (Traefik, Coraza, Kong, Istio);
  * **M03** – Observabilidade/FinOps (Prometheus, Grafana, Loki, OpenCost, Lago);
  * **M04** – Storage e Bancos (Ceph, Postgres, Redis, Qdrant, Redpanda, etc.);
  * **M05** – Segurança/Segredos (Vault, OPA, Falco, OpenFGA);
  * **M06** – Identidade/SSO (Keycloak, midPoint, RBAC/ReBAC);
  * **M07** – Portal Backstage e Private App Store;
  * **M08** – Serviços Core (Flowise, LiteLLM, N8n, Directus, Appsmith, etc.);
  * **M09** – Factory;
  * **M10** – Brain;
  * **M11** – Operations.

### Infraestrutura – Topologia B (Kubernetes)

* Cluster `ag-<regiao>-core-<env>` com:

  * Traefik, Coraza, Kong como borda;
  * Istio com mTLS STRICT STRICT;
  * Vault, OPA, Falco, OpenFGA em produção;
  * Prometheus, Grafana, Loki, OpenCost, Lago;
  * Backstage com Private App Store;
  * KEDA habilitado.

* Namespaces para Guardian:

  * `guardian-security` (Pentest AI, Browser Isolation);
  * `guardian-legal` (Legal AI);
  * `guardian-chaos` (Chaos);
  * `guardian-appstore` (App Store Policy).

### Ferramentas

* `git`, `kubectl`, `kustomize`, `helm`, `argocd`, `yq`;
* Acesso a repositórios:

  * `appgear-gitops-core`;
  * `appgear-gitops-suites`;
  * `appgear-backstage`.

### Topologia A (Docker – demo)

* Host Ubuntu LTS com Docker + docker-compose;
* `.env` central em `/opt/appgear/.env`;
* Traefik local para demos (sem Kong/Coraza).

---

## 4. Como fazer (comandos)

### 1. Criar o artefato canônico `Módulo 12 v0.1.md`

No repositório de contratos (ex.: `appgear-contracts`):

```bash
cd appgear-contracts

# (Opcional) arquivar o artefato legado, se existir
mkdir -p legacy
git mv "Módulo 12 v0.py" legacy/ 2>/dev/null || true

cat > "Módulo 12 v0.1.md" << 'EOF'
# Módulo 12 – Suíte Guardian (Security Suite, Legal AI, Chaos, App Store) v0.1

(cole aqui este conteúdo)

EOF

git add "Módulo 12 v0.1.md" legacy/ 2>/dev/null || git add "Módulo 12 v0.1.md"
git commit -m "M12 v0.1: Retrofit Guardian (Formato, Borda, FinOps, Resources)"
git push
```

---

### 2. Padrão de labels e resources (FinOps/Performance)

Padrão de labels mínimo para workloads Guardian:

```yaml
metadata:
  labels:
    app.kubernetes.io/name: addon-guardian-pentest-ai   # ou outro nome
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon                               # core|addon
    appgear.io/suite: guardian                           # core|factory|brain|ops|guardian...
    appgear.io/topology: B                               # A|B
    appgear.io/workspace-id: global                      # ou ws-<id>
    appgear.io/tenant-id: global                         # ou tenant-<id>
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod12-suite-guardian"
```

Exemplo de `resources` para Browser Isolation:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2"
    memory: "3Gi"
```

Scanners e serviços leves podem usar valores menores, mas sempre com `requests/limits` definidos.

---

### 3. Security Suite – Pentest AI (Deployment, Service, RBAC, Kong)

No repositório `appgear-gitops-suites`:

```bash
cd appgear-gitops-suites
mkdir -p apps/guardian/security-suite/pentest-ai
```

#### 3.1 Deployment + Service

`apps/guardian/security-suite/pentest-ai/deployment.yaml`:

```bash
cat > apps/guardian/security-suite/pentest-ai/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-guardian-pentest-ai
  namespace: guardian-security
  labels:
    app.kubernetes.io/name: addon-guardian-pentest-ai
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: guardian
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod12-suite-guardian"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-guardian-pentest-ai
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-guardian-pentest-ai
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: addon
        appgear.io/suite: guardian
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      serviceAccountName: sa-guardian-pentest-ai
      containers:
        - name: pentest-ai
          image: ghcr.io/appgear/addon-guardian-pentest-ai:0.1.0
          imagePullPolicy: IfNotPresent
          env:
            - name: RABBITMQ_URL
              valueFrom:
                secretKeyRef:
                  name: guardian-pentest-secrets
                  key: rabbitmq_url
            - name: FLOWISE_URL
              valueFrom:
                secretKeyRef:
                  name: guardian-pentest-secrets
                  key: flowise_url
          ports:
            - name: http
              containerPort: 8080
          resources:
            requests:
              cpu: "200m"
              memory: "256Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
EOF
```

`apps/guardian/security-suite/pentest-ai/service.yaml`:

```bash
cat > apps/guardian/security-suite/pentest-ai/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-guardian-pentest-ai
  namespace: guardian-security
  labels:
    app.kubernetes.io/name: addon-guardian-pentest-ai
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
spec:
  selector:
    app.kubernetes.io/name: addon-guardian-pentest-ai
  ports:
    - name: http
      port: 80
      targetPort: http
EOF
```

#### 3.2 RBAC mínimo (M05 + Falco)

`apps/guardian/security-suite/pentest-ai/rbac.yaml`:

```bash
cat > apps/guardian/security-suite/pentest-ai/rbac.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-guardian-pentest-ai
  namespace: guardian-security
  labels:
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: role-guardian-pentest-ai
  namespace: guardian-security
  labels:
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rb-guardian-pentest-ai
  namespace: guardian-security
  labels:
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
subjects:
  - kind: ServiceAccount
    name: sa-guardian-pentest-ai
    namespace: guardian-security
roleRef:
  kind: Role
  name: role-guardian-pentest-ai
  apiGroup: rbac.authorization.k8s.io
EOF
```

Falco (M05) deve ter regras específicas para monitorar qualquer comportamento fora desse escopo.

#### 3.3 Ingress via Kong (sem IngressRoute)

`apps/guardian/security-suite/pentest-ai/ingress-kong.yaml`:

```bash
cat > apps/guardian/security-suite/pentest-ai/ingress-kong.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guardian-pentest-ai
  namespace: guardian-security
  labels:
    app.kubernetes.io/name: addon-guardian-pentest-ai
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
  annotations:
    konghq.com/plugins: oidc-keycloak
spec:
  ingressClassName: kong
  rules:
    - host: security.dev.appgear.local
      http:
        paths:
          - path: /pentest
            pathType: Prefix
            backend:
              service:
                name: addon-guardian-pentest-ai
                port:
                  number: 80
EOF
```

---

### 4. Security Suite – Browser Isolation (Deployment + Service)

```bash
mkdir -p apps/guardian/security-suite/browser-isolation
```

`apps/guardian/security-suite/browser-isolation/deployment.yaml`:

```bash
cat > apps/guardian/security-suite/browser-isolation/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-guardian-browser-isolation
  namespace: guardian-security
  labels:
    app.kubernetes.io/name: addon-guardian-browser-isolation
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: addon
    appgear.io/suite: guardian
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod12-suite-guardian"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-guardian-browser-isolation
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-guardian-browser-isolation
        appgear.io/tier: addon
        appgear.io/suite: guardian
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: browser
          image: ghcr.io/appgear/addon-guardian-browser-isolation:0.1.0
          ports:
            - name: http
              containerPort: 3000
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "3Gi"
EOF
```

`apps/guardian/security-suite/browser-isolation/service.yaml`:

```bash
cat > apps/guardian/security-suite/browser-isolation/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: addon-guardian-browser-isolation
  namespace: guardian-security
  labels:
    app.kubernetes.io/name: addon-guardian-browser-isolation
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
spec:
  selector:
    app.kubernetes.io/name: addon-guardian-browser-isolation
  ports:
    - name: http
      port: 80
      targetPort: http
EOF
```

Ingress para Browser Isolation pode seguir o padrão do Pentest (Kong + OIDC), se necessário.

---

### 5. Legal AI – Core (Tika, Gotenberg) + Add-on Guardian

#### 5.1 Core Legal (em `appgear-gitops-core`)

```bash
cd ../appgear-gitops-core
mkdir -p apps/core/legal
```

`apps/core/legal/tika-deployment.yaml`:

```bash
cat > apps/core/legal/tika-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-tika
  namespace: legal
  labels:
    app.kubernetes.io/name: core-tika
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: core-tika
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-tika
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: tika
          image: apache/tika:latest
          ports:
            - name: http
              containerPort: 9998
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
EOF
```

> `core-gotenberg` e `core-signserver` seguem o mesmo padrão de labels/resources.

#### 5.2 Add-on Legal AI (em `appgear-gitops-suites`)

```bash
cd ../appgear-gitops-suites
mkdir -p apps/guardian/legal-ai
```

`apps/guardian/legal-ai/deployment.yaml`:

```bash
cat > apps/guardian/legal-ai/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-guardian-legal-ai
  namespace: guardian-legal
  labels:
    app.kubernetes.io/name: addon-guardian-legal-ai
    appgear.io/tier: addon
    appgear.io/suite: guardian
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod12-suite-guardian"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-guardian-legal-ai
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-guardian-legal-ai
        appgear.io/tier: addon
        appgear.io/suite: guardian
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: legal-ai
          image: ghcr.io/appgear/addon-guardian-legal-ai:0.1.0
          env:
            - name: TIKA_URL
              value: http://core-tika.legal.svc.cluster.local:9998
            - name: GOTENBERG_URL
              value: http://core-gotenberg.legal.svc.cluster.local:3000
          ports:
            - name: http
              containerPort: 8080
          resources:
            requests:
              cpu: "200m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
EOF
```

---

### 6. Chaos – Experimentos e UI via Kong

Pasta em `appgear-gitops-suites`:

```bash
mkdir -p apps/guardian/chaos
```

Exemplo de ChaosExperiment/ChaosEngine (Litmus):

```bash
cat > apps/guardian/chaos/chaos-experiments.yaml << 'EOF'
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: pod-delete-appgear-core
  namespace: guardian-chaos
  labels:
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
spec:
  definition:
    scope: Namespaced
    image: litmuschaos/go-runner:latest
---
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: engine-pod-delete-core
  namespace: guardian-chaos
  labels:
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
spec:
  annotationCheck: "true"
  appinfo:
    appns: appgear-core
    applabel: "app.kubernetes.io/part-of=appgear"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete-appgear-core
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
EOF
```

Ingress via Kong, se a UI for exposta:

```bash
cat > apps/guardian/chaos/ingress-kong-chaos.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guardian-chaos-dashboard
  namespace: guardian-chaos
  labels:
    appgear.io/suite: guardian
    appgear.io/tenant-id: global
  annotations:
    konghq.com/plugins: oidc-keycloak
spec:
  ingressClassName: kong
  rules:
    - host: security.dev.appgear.local
      http:
        paths:
          - path: /chaos
            pathType: Prefix
            backend:
              service:
                name: litmusportal-service
                port:
                  number: 9002
EOF
```

Annotations padrão para M13 injetar sidecars em workspaces:

```yaml
metadata:
  annotations:
    guardian.appgear.io/enabled: "true"
    guardian.appgear.io/profile: "full"  # ou "lite"
```

---

### 7. Guardian App Store – API Policy + Plugin Backstage

#### 7.1 API de política (AppGear Guardian)

```bash
mkdir -p apps/guardian/appstore
```

`apps/guardian/appstore/deployment.yaml`:

```bash
cat > apps/guardian/appstore/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-guardian-appstore-policy
  namespace: guardian-appstore
  labels:
    app.kubernetes.io/name: addon-guardian-appstore-policy
    appgear.io/tier: addon
    appgear.io/suite: guardian
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: addon-guardian-appstore-policy
  template:
    metadata:
      labels:
        app.kubernetes.io/name: addon-guardian-appstore-policy
        appgear.io/suite: guardian
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: policy-api
          image: ghcr.io/appgear/addon-guardian-appstore-policy:0.1.0
          env:
            - name: LEGAL_AI_URL
              value: http://addon-guardian-legal-ai.guardian-legal.svc.cluster.local
            - name: PENTEST_AI_URL
              value: http://addon-guardian-pentest-ai.guardian-security.svc.cluster.local
          ports:
            - name: http
              containerPort: 8080
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
EOF
```

#### 7.2 Plugin da Private App Store (Backstage, M07)

No repositório `appgear-backstage`, backend do plugin Private App Store:

```ts
// plugins/private-app-store-backend/src/service/router.ts
import { Router } from 'express';
import fetch from 'node-fetch';

export async function createRouter(): Promise<Router> {
  const router = Router();
  const policyUrl =
    process.env.GUARDIAN_APPSTORE_POLICY_URL ??
    'http://addon-guardian-appstore-policy.guardian-appstore.svc.cluster.local';

  router.post('/request-access', async (req, res) => {
    const { appId, userId, workspaceId } = req.body;

    const resp = await fetch(`${policyUrl}/evaluate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appId, userId, workspaceId }),
    });

    const decision = await resp.json();
    return res.json(decision);
  });

  return router;
}
```

UI continua com Tailwind CSS + shadcn/ui, conforme diretrizes gerais.

---

### 8. Topologia A – Docker (demo)

Em host de desenvolvimento:

```bash
cd /opt/appgear
mkdir -p guardian
```

`.env` (trecho):

```bash
cat >> .env << 'EOF'
GUARDIAN_LEGAL_AI_PORT=8085
GUARDIAN_PENTEST_AI_PORT=8086
EOF
```

`/opt/appgear/guardian/docker-compose.guardian.yml`:

```bash
cat > guardian/docker-compose.guardian.yml << 'EOF'
version: "3.8"

services:
  core-tika:
    image: apache/tika:latest
    container_name: core-tika
    ports:
      - "9998:9998"

  core-gotenberg:
    image: gotenberg/gotenberg:8
    container_name: core-gotenberg
    ports:
      - "3000:3000"

  addon-guardian-legal-ai:
    image: ghcr.io/appgear/addon-guardian-legal-ai:0.1.0
    container_name: addon-guardian-legal-ai
    environment:
      - TIKA_URL=http://core-tika:9998
      - GOTENBERG_URL=http://core-gotenberg:3000
    ports:
      - "${GUARDIAN_LEGAL_AI_PORT}:8080"

  addon-guardian-pentest-ai:
    image: ghcr.io/appgear/addon-guardian-pentest-ai:0.1.0
    container_name: addon-guardian-pentest-ai
    ports:
      - "${GUARDIAN_PENTEST_AI_PORT}:8080"
EOF
```

Subir demo:

```bash
cd /opt/appgear
docker compose -f guardian/docker-compose.guardian.yml up -d
```

> Topologia A é apenas para **dev/demo**, sem WAF/Kong/Coraza.

---

## 5. Como verificar

1. **Artefato canônico**

   ```bash
   cd appgear-contracts
   ls "Módulo 12 v0.1.md"
   ```

2. **Argo CD – Suíte Guardian**

   ```bash
   argocd app list | grep suite-guardian
   argocd app get suite-guardian
   ```

3. **Labels/FinOps**

   ```bash
   kubectl get deploy -A -l appgear.io/suite=guardian -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.metadata.labels.appgear\.io/tenant-id}{"\n"}{end}'
   ```

4. **Resources**

   ```bash
   kubectl get deploy addon-guardian-browser-isolation \
     -n guardian-security -o yaml | yq '.spec.template.spec.containers[0].resources'
   ```

5. **Borda/Kong**

   ```bash
   kubectl get ingress -A -l appgear.io/suite=guardian
   kubectl get ingressroute -A | grep -i guardian || echo "OK: Guardian sem IngressRoute direto"
   ```

6. **RBAC Pentest**

   ```bash
   kubectl get sa,role,rolebinding -n guardian-security | grep pentest
   ```

7. **App Store**

   * No Backstage, acessar a Private App Store, solicitar acesso a um app;
   * Conferir logs do backend do plugin e do `addon-guardian-appstore-policy`.

8. **Topologia A (demo)**

   ```bash
   cd /opt/appgear
   docker ps | egrep 'guardian|tika|gotenberg'
   ```

---

## 6. Erros comuns

1. **Criar IngressRoute para Pentest/Chaos**

   * Reabre bypass do WAF/API Gateway;
   * Correção: usar somente `Ingress` com `ingressClassName: kong` e plugins OIDC.

2. **Omitir `appgear.io/tenant-id`**

   * Impede FinOps de atribuir custos de segurança por cliente;
   * Correção: garantir label em todos os recursos da suíte.

3. **Workloads pesados sem `resources`**

   * Browser Isolation/Chaos/Scanners podem saturar o cluster;
   * Correção: sempre definir `requests/limits` adequados.

4. **RBAC excessivamente amplo para Pentest**

   * Scanners podem virar vetor de ataque;
   * Correção: manter Role minimalista e monitorar com Falco.

5. **Tratar App Store como app separado**

   * Fere visão de Backstage como portal único;
   * Correção: manter App Store como plugin Backstage, usando apenas API Guardian para decisões.

6. **Chaos exposto sem autenticação robusta**

   * UI aberta pode derrubar o cluster;
   * Correção: proteger com Kong+Keycloak ou apenas port-forward restrito.

7. **Usar Topologia A como produção**

   * Sem WAF, sem Kong, sem Zero-Trust;
   * Correção: limitar Topologia A a dev/lab.

---

## 7. Onde salvar

1. **Contrato / Documentação**

   * Repositório: `appgear-contracts`;
   * Arquivo: `Módulo 12 – Suíte Guardian (Security Suite, Legal AI, Chaos, App Store) v0.1.md`;
   * Referenciar em: `1 - Desenvolvimento v0.md`, seção “Módulo 12 – Suíte Guardian”.

2. **GitOps – Core**

   * Repositório: `appgear-gitops-core`;
   * Pastas:

     * `apps/core/legal/` (Tika, Gotenberg, SignServer).

3. **GitOps – Suítes**

   * Repositório: `appgear-gitops-suites`;
   * Pastas:

     * `apps/guardian/security-suite/` (Pentest, Browser);
     * `apps/guardian/legal-ai/`;
     * `apps/guardian/chaos/`;
     * `apps/guardian/appstore/`;
   * Application da suíte Guardian registrada em:

     * `clusters/ag-<regiao>-core-<env>/apps-suites.yaml`.

4. **Backstage / App Store**

   * Repositório: `appgear-backstage`;
   * Ajustar backend do plugin Private App Store para usar `GUARDIAN_APPSTORE_POLICY_URL`.

5. **Topologia A (Docker)**

   * Host:

     * `/opt/appgear/.env`;
     * `/opt/appgear/guardian/docker-compose.guardian.yml`;
     * `/opt/appgear/guardian/` (dados adicionais, se necessário).

---

## 8. Dependências entre os módulos

A posição da Suíte Guardian (Módulo 12) na arquitetura AppGear é:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * Define:

    * Forma canônica (`*.md`);
    * Convenções de repositório (`appgear-gitops-core`, `appgear-gitops-suites`, `appgear-contracts`, `appgear-backstage`);
    * Labels `appgear.io/*` (incluindo `appgear.io/tenant-id`, `appgear.io/workspace-id`, `appgear.io/suite`);
    * Diretrizes de FinOps que este módulo aplica a todos os manifests Guardian.

* **Módulo 01 – GitOps e Argo CD**

  * Fornece:

    * Argo CD para sincronizar:

      * core legal (Tika, Gotenberg, SignServer) em `appgear-gitops-core`;
      * Pentest, Browser Isolation, Legal AI, Chaos e Policy em `appgear-gitops-suites`;
    * `apps-suites.yaml` contendo `suite-guardian`.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * Define:

    * Cadeia de borda HTTP **Traefik → Coraza → Kong → Istio**;
    * Kong como Ingress Controller e API Gateway oficial;
  * Este módulo:

    * Usa apenas `Ingress` com `ingressClassName: kong` para expor Pentest, Chaos, Legal AI e App Store Policy;
    * Não cria IngressRoute direto para esses serviços.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * M03:

    * Coleta métricas e custos da Suíte Guardian (`appgear.io/suite=guardian`);
  * M12:

    * Garante `appgear.io/tenant-id` e `appgear.io/suite=guardian` em todos os recursos;
    * Produz métricas de uso de scanners, browser, chaos e decisões de App Store.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, Redpanda, etc.)**

  * Fornece:

    * Storage para documentos (Legal AI);
    * Bancos e filas usados por Pentest AI, Chaos e App Store Policy.

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * Fornece:

    * Vault para segredos dos scanners, Legal AI, App Store Policy;
    * OPA para validar manifests Guardian (labels, `resources`, ausência de segredos inline);
    * Falco para monitorar comportamentos anômalos de pods de Pentest/Chaos;
    * OpenFGA para decisões de acesso a funcionalidades críticas.

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * Fornece:

    * OIDC/SSO para UIs de Pentest, Chaos, Legal AI e App Store;
    * Contexto de usuário (tenant, grupos, roles) usado nas decisões de política (App Store Policy).

* **Módulo 07 – Portal Backstage e Private App Store**

  * UI principal:

    * Private App Store como plugin Backstage;
  * M12:

    * Fornece a API `addon-guardian-appstore-policy` que o plugin consome para decidir aprovação/negação de apps.

* **Módulo 08 – Serviços de Aplicação Core (Flowise, LiteLLM, N8n, Directus, Appsmith, Metabase)**

  * Fornece:

    * Flowise/LiteLLM usados internamente por Pentest AI e Legal AI;
    * N8n para automatizar fluxos pós-pentest ou pós-análise legal.

* **Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer)**

  * Fornece:

    * CDEs e pipelines que podem ser alvo de Pentest;
    * Artefatos que passam pela App Store antes de serem promovidos.

* **Módulo 10 – Suíte Brain (RAG, Agentes, AutoML)**

  * Fornece:

    * LLMs, agentes e RAG usados por Pentest AI e Legal AI para interpretação de resultados e documentos.

* **Módulo 11 – Suíte Operations (IoT, Digital Twins, RPA, KubeEdge)**

  * Fornece:

    * Workloads de campo que também podem ser avaliados por Guardian (risco operacional/segurança).

* **Módulo 12 – Suíte Guardian (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06, M07, M08, M09, M10, M11**;
  * Entrega:

    * Camada transversal de segurança, legal/compliance, chaos e política de App Store para toda a plataforma.

* **Módulo 13 – Workspaces e vClusters (futuro)**

  * Irá:

    * Usar annotations `guardian.appgear.io/enabled` para decidir quando injetar sidecars/agents de segurança em workspaces;
    * Integrar a App Store Policy na criação e atualização de workspaces.

Fluxo de dependência:

**M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → M09 → M10 → M11 → M12 → (M13, suítes adicionais, PWA, etc.)**

Sem o Módulo 12, a AppGear não possui uma camada padronizada de **governança e segurança transversal** (Pentest, Legal, Chaos, App Store Policy), comprometendo a confiabilidade e o compliance da plataforma como um todo.

---

## 9. Metadados
- Gerado automaticamente por CodeGPT
- Versão do módulo: v0.3
- Compatibilidade: full
- Data de geração: 2025-11-24
