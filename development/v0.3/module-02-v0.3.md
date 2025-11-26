# M02 – Borda e Malha de Serviço (Traefik, Istio, Coraza, Kong) (v0.3)

> [!IMPORTANT]
> Este documento define o **Módulo 02 (M02)** da arquitetura AppGear na linha v0.3.  
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

# Módulo 02 – Borda e Malha de Serviço (Traefik, Istio, Coraza, Kong)

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

- Confirma a borda única Traefik → Coraza → Kong → Istio com mTLS STRICT STRICT e validação OPA/Kyverno.


### Premissas padrão (v0.3)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Padroniza a entrada/saída de tráfego HTTP/gRPC e a comunicação interna.
Define Traefik (ou outro ingress), WAF (Coraza), API Gateway (Kong) e Istio com mTLS STRICT para proteger rotas e serviços.

---

## 1. O que é

Este módulo define a **rede core da Topologia B (Kubernetes)** para a plataforma **AppGear**, estabelecendo:

1. A **malha de serviço interna** com **Istio** e **mTLS STRICT em modo STRICT** para todo tráfego Leste–Oeste entre serviços `core-*` e `ws-*`.

2. A **cadeia obrigatória de borda** para todo tráfego Norte–Sul:

   ```text
   Cliente externo
     → Traefik (Ingress Controller)
       → Coraza (WAF)
         → Kong (API Gateway)
           → Istio (Service Mesh)
             → Serviços internos (core-* e ws-*)
   ```

3. O uso consistente de **labels de Governança e FinOps** para todos os recursos deste módulo:

   ```yaml
   appgear.io/tier: core
   appgear.io/suite: core
   appgear.io/topology: B
   appgear.io/workspace-id: global
   appgear.io/tenant-id: global
   ```

4. A configuração do **Coraza (WAF)** de forma **GitOps-safe**, garantindo que:

   * Não exista `configMapGenerator envs: [".env"]` em nenhum `kustomization.yaml`;
   * O **upstream do Kong** seja um **DNS interno fixo** de Topologia B:
     `http://core-kong.appgear-core.svc.cluster.local:8000`;
   * Toda configuração relevante esteja em **manifests YAML comitados**, compatíveis com Argo CD.

5. **NetworkPolicies orientadas a Zero Trust para IA**

   * Egress externo bloqueado por padrão no namespace `appgear-core`;
   * Apenas `core-litellm` tem permissão controlada para falar com provedores de LLM externos (`api.openai.com`).

Este módulo é a referência única para **como o tráfego entra**, **como se protege** e **como circula** dentro do cluster AppGear na Topologia B.

---

## 2. Por que

1. **Cumprir Contrato v0, Auditoria v0 e Interoperabilidade v0**

   * G05 – Cadeia de borda formalizada (**Traefik → Coraza → Kong → Istio**);
   * G06 – mTLS STRICT STRICT na malha de serviço (Istio);
   * M00-3 – Labels `appgear.io/tenant-id` e demais labels de Governança aplicadas de forma consistente.
   * Proibição de Shadow IT em IA: somente `core-litellm` pode sair para `api.openai.com` (NetworkPolicies + OPA).

2. **Impor modelo Zero-Trust na borda e dentro do cluster**

   * Nenhum serviço de negócio é exposto via `LoadBalancer`/`NodePort` diretamente;
   * Ninguém publica Ingress/IngressRoute direto para serviços internos;
   * Todo tráfego externo precisa atravessar **WAF + API Gateway + Malha**, com inspeção e controle centralizados.

3. **Eliminar o BUG GITOPS (dependência de `.env` no Kustomize/Argo CD)**

   * Manifests **não podem depender** de arquivos locais não versionados;
   * Qualquer variável de ambiente precisa virar **ConfigMap/Secret gerado via Kustomize** (ou vir do Vault/External Secrets), nunca interpolada em YAML na máquina do desenvolvedor antes do commit;
   * A configuração do Coraza (inclusive upstream) passa a estar **100% descrita em YAML commitado**;
   * Argo CD consegue renderizar Kustomize sem acesso a `.env`.

4. **Evitar dívida técnica em borda e segurança**

   * Upstreams e FQDNs críticos não podem ser “mágica” de variáveis de ambiente;
   * Imagens sensíveis (como WAF) **não podem usar `:latest`**;
   * Cadeia de borda única evita que novas equipes criem rotas paralelas e não auditadas.

5. **Preparar o terreno para módulos futuros (Kong, SSO, Observabilidade)**

   * Kong herda o modelo de borda deste módulo;
   * Módulos de SSO, API Management, Rate Limit e Logging se plugam naturalmente na cadeia já definida.

---

## 3. Pré-requisitos

1. **Governança em vigor**

   * Documentos aprovados:

     * `0 - Contrato v0`
     * `2 - Auditoria v0`
     * `3 - Interoperabilidade v0`

   * Módulo 00 aplicado:

     * Convenções de labels `appgear.io/*`;
     * Tratamento de `.env` (nunca comitado);
     * Proibição de usar `.env` diretamente em Kustomize/Argo CD.

2. **Módulos anteriores**

   * **M00 – Convenções e Nomenclatura**:
     Estrutura de repositórios, nomes de clusters (`ag-<regiao>-core-<env>`), `.env` central.
   * **M01 – Bootstrap GitOps e Argo CD**:
     Argo CD instalado via manifesto vendorizado + Kustomize, App-of-Apps e ApplicationSet apontando para `apps/core/*`.

3. **Repositório GitOps Core**

   Repositório GitOps da Topologia B (ex.: `appgear-gitops-core`), com base:

   ```text
   clusters/
     ag-br-core-dev/
       kustomization.yaml
       apps-core.yaml

   apps/
     core/
       istio/
       traefik/
       security/
         coraza/
   ```

4. **Cluster Kubernetes (Topologia B)**

   * Cluster físico `ag-br-core-<env>` acessível via `kubectl`;

   * Namespaces já existentes (podem ter sido criados em M01 ou bootstrap inicial):

     * `istio-system`
     * `appgear-core`
     * `security`
     * `backstage`
     * `observability`

   * Argo CD reconcilia `clusters/ag-br-core-<env>/apps-core.yaml`.

5. **.env central (apenas para CI/CD e automação, nunca para Kustomize/Argo)**

   Exemplo de conteúdo (M00):

   ```env
   APPGEAR_ENV=dev
   APPGEAR_BASE_DOMAIN=appgear.local
   APPGEAR_CORE_FQDN=core.${APPGEAR_ENV}.${APPGEAR_BASE_DOMAIN}
   APPGEAR_TENANT_ID_GLOBAL=global
   ```

   O **DNS interno do Kong** é tratado como **constante de Topologia B**:

   ```text
   http://core-kong.appgear-core.svc.cluster.local:8000
   ```

   Não há interpolação disso via `.env` em `kustomization.yaml`.

   Variáveis específicas de ambiente devem ser materializadas como **ConfigMaps/Secrets gerados pelo Kustomize** (ou referenciadas por External Secrets apontando para o Vault), nunca como YAML renderizado localmente com `.env` antes do commit.

---

## KEDA e scale-to-zero na borda/malha

* **Ingress (Traefik/Coraza/Istio)**: habilitar `ScaledObject` por padrão para gateways/ingress e sidecars de control plane (quando suportado), com triggers HTTP (RPS) e `minReplicaCount: 0` para ambientes de dev/teste.
* **Sidecars de workload**: Istio sidecar não escala individualmente, mas os deployments da borda (gateway, ingress) devem ter KEDA ativo em `values.yaml`/`kustomization.yaml` **sem flags opcionais**.
* **Parâmetros recomendados:** `pollingInterval: 15s`, `cooldownPeriod: 60–90s`, `targetPendingRequests: 10` para HTTP, replicando o comportamento para control plane ingress e proxies de Ceph expostos via Istio.
* Documentar triggers e tempos em `4-documentos/keda-scale-to-zero.md` e refletir nos charts Helm (Traefik/Coraza/Istio) para que o comportamento seja o padrão da topologia B.

---

## 4. Como fazer (comandos)

> Todos os passos abaixo produzem **manifests YAML versionados** e são aplicados via **Argo CD** (GitOps).
> Em produção, **não** usar `kubectl apply` manual direto nesses arquivos.

---

### 1. Istio – Malha de Serviço com mTLS STRICT STRICT (apps/core/istio)

#### 1.1 Criar pasta e namespace

```bash
cd appgear-gitops-core   # ou repositório GitOps equivalente

mkdir -p apps/core/istio
```

`apps/core/istio/namespace.yaml`:

```bash
cat > apps/core/istio/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
EOF
```

#### 1.2 Kustomization do Istio

`apps/core/istio/kustomization.yaml`:

```bash
cat > apps/core/istio/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - istio-operator.yaml
  - peerauthentication-global-strict.yaml
EOF
```

#### 1.3 IstioOperator (controle + ingress interno)

`apps/core/istio/istio-operator.yaml`:

```bash
cat > apps/core/istio/istio-operator.yaml << 'EOF'
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-controlplane
  namespace: istio-system
  labels:
    app.kubernetes.io/name: core-istio
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
spec:
  profile: default
  meshConfig:
    enableTracing: true
    accessLogFile: /dev/stdout
    enableAutoMtls: true
  components:
    base:
      enabled: true
    pilot:
      enabled: true
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        namespace: istio-system
        k8s:
          service:
            type: ClusterIP
EOF
```

#### 1.4 PeerAuthentication global STRICT

`apps/core/istio/peerauthentication-global-strict.yaml`:

```bash
cat > apps/core/istio/peerauthentication-global-strict.yaml << 'EOF'
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
spec:
  mtls:
    mode: STRICT
EOF
```

#### 1.5 Commit

```bash
git add apps/core/istio
git commit -m "mod02: Istio com mTLS STRICT STRICT e labels de governanca (tenant global)"
git push origin main
```

---

### 2. Traefik – Ingress Controller da Borda (apps/core/traefik)

Traefik será o **único ponto de entrada HTTP/S** do cluster, sempre encaminhando as requisições para o WAF (Coraza) no namespace `security`.

#### 2.1 Kustomization do Traefik

```bash
mkdir -p apps/core/traefik
```

`apps/core/traefik/kustomization.yaml`:

```bash
cat > apps/core/traefik/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: appgear-core

resources:
  - deployment.yaml
  - service.yaml
  - ingressroute-core-edge.yaml
EOF
```

#### 2.2 Deployment do Traefik

`apps/core/traefik/deployment.yaml`:

```bash
cat > apps/core/traefik/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-traefik
  labels:
    app.kubernetes.io/name: core-traefik
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: core-traefik
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-traefik
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      serviceAccountName: core-traefik
      containers:
        - name: traefik
          image: traefik:v3.0
          args:
            - --entrypoints.web.address=:80
            - --entrypoints.websecure.address=:443
            - --providers.kubernetescrd
            - --providers.kubernetesingress
            - --api.dashboard=true
            - --log.level=INFO
          ports:
            - name: web
              containerPort: 80
            - name: websecure
              containerPort: 443
          readinessProbe:
            httpGet:
              path: /ping
              port: 80
          livenessProbe:
            httpGet:
              path: /ping
              port: 80
EOF
```

#### 2.3 Service público do Traefik

`apps/core/traefik/service.yaml`:

```bash
cat > apps/core/traefik/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-traefik
  labels:
    app.kubernetes.io/name: core-traefik
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: core-traefik
  ports:
    - name: web
      port: 80
      targetPort: web
    - name: websecure
      port: 443
      targetPort: websecure
EOF
```

#### 2.4 IngressRoute único → Coraza

`apps/core/traefik/ingressroute-core-edge.yaml`:

```bash
cat > apps/core/traefik/ingressroute-core-edge.yaml << 'EOF'
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: core-edge
  namespace: appgear-core
  labels:
    app.kubernetes.io/name: core-edge
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`core.dev.appgear.local`)
      kind: Rule
      services:
        - name: core-coraza
          namespace: security
          port: 8080
  tls:
    passthrough: false
EOF
```

> Em `stg`/`prod`, o host deve ser ajustado via overlay (por exemplo `core.stg.appgear.cloud`, `core.appgear.cloud`), **sem** uso de `.env` no Kustomize.

#### 2.5 Commit

```bash
git add apps/core/traefik
git commit -m "mod02: Traefik como borda única encaminhando para Coraza (WAF)"
git push origin main
```

---

### 3. Coraza – WAF com upstream fixo para Kong (apps/core/security/coraza)

#### 3.1 Kustomization de Security/Coraza

```bash
mkdir -p apps/core/security/coraza
```

`apps/core/security/kustomization.yaml` (se ainda não existir):

```bash
cat > apps/core/security/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: security

resources:
  - coraza/
EOF
```

`apps/core/security/coraza/kustomization.yaml`:

```bash
cat > apps/core/security/coraza/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - configmap-waf.yaml
  - deployment.yaml
  - service.yaml
EOF
```

> Reforço: não existe `configMapGenerator envs: [".env"]` em nenhum destes arquivos.

#### 3.2 ConfigMap do WAF – upstream fixo

`apps/core/security/coraza/configmap-waf.yaml`:

```bash
cat > apps/core/security/coraza/configmap-waf.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: core-coraza-config
  labels:
    app.kubernetes.io/name: core-coraza-config
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
data:
  waf-config.yaml: |
    # Configuração simplificada do Coraza como reverse-proxy WAF.
    # Upstream fixo na Topologia B:
    #   core-kong.appgear-core.svc.cluster.local:8000
    server:
      listen: ":8080"
      upstream: "http://core-kong.appgear-core.svc.cluster.local:8000"

    waf:
      rules:
        - id: "100000"
          msg: "Exemplo: bloquear /forbidden"
          phase: "request"
          action: "deny"
          match:
            uri: "/forbidden"
EOF
```

#### 3.3 Deployment do Coraza (imagem pinada)

`apps/core/security/coraza/deployment.yaml`:

```bash
cat > apps/core/security/coraza/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-coraza
  labels:
    app.kubernetes.io/name: core-coraza
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: core-coraza
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-coraza
        app.kubernetes.io/part-of: appgear
        appgear.io/tier: core
        appgear.io/suite: core
        appgear.io/topology: B
        appgear.io/workspace-id: global
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: coraza-proxy
          # IMPORTANTE: imagem pinada (sem :latest)
          image: ghcr.io/corazawaf/coraza-proxy:v1.0.0
          args:
            - --config=/etc/coraza/waf-config.yaml
          volumeMounts:
            - name: config
              mountPath: /etc/coraza
      volumes:
        - name: config
          configMap:
            name: core-coraza-config
EOF
```

#### 3.4 Service do Coraza

`apps/core/security/coraza/service.yaml`:

```bash
cat > apps/core/security/coraza/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: core-coraza
  labels:
    app.kubernetes.io/name: core-coraza
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod02-mesh-edge"
spec:
  selector:
    app.kubernetes.io/name: core-coraza
  ports:
    - name: http
      port: 8080
      targetPort: 8080
EOF
```

#### 3.5 Commit

```bash
git add apps/core/security
git commit -m "mod02: Coraza WAF GitOps-safe com upstream fixo para Kong"
git push origin main
```

---

### 4. NetworkPolicies – Bloqueio de egress para LLMs externos

> Objetivo: impedir que workloads chamem `api.openai.com` diretamente. Apenas o `core-litellm` pode sair para provedores de LLM externos.

#### 4.1 Estrutura e kustomization

```bash
mkdir -p apps/core/networkpolicies
```

`apps/core/networkpolicies/kustomization.yaml`:

```bash
cat > apps/core/networkpolicies/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deny-external-egress.yaml
  - allow-litellm-openai.yaml
EOF
```

> A Application raiz (M01) deve referenciar este diretório para que as políticas sejam reconciliadas pelo Argo CD.

#### 4.2 Política default – proibir egress externo em `appgear-core`

`apps/core/networkpolicies/deny-external-egress.yaml`:

```bash
cat > apps/core/networkpolicies/deny-external-egress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-external-egress
  namespace: appgear-core
  labels:
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
    - to:
        - namespaceSelector:
            matchExpressions:
              - key: kubernetes.io/metadata.name
                operator: In
                values: ["appgear-core", "security", "istio-system", "observability"]
      ports:
        - port: 15012
          protocol: TCP
        - port: 15017
          protocol: TCP
        - port: 15090
          protocol: TCP
EOF
```

> Resultado: pods do namespace `appgear-core` só conversam com serviços internos (DNS, malha e security). Não existe regra liberando internet, logo chamadas diretas a `api.openai.com` (ou qualquer FQDN externo) ficam bloqueadas por padrão.

#### 4.3 Exceção controlada – liberar apenas o `core-litellm`

`apps/core/networkpolicies/allow-litellm-openai.yaml`:

```bash
cat > apps/core/networkpolicies/allow-litellm-openai.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-litellm-openai
  namespace: appgear-core
  labels:
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: core-litellm
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - port: 443
          protocol: TCP
EOF
```

> Apenas os pods etiquetados como `core-litellm` conseguem sair para a internet (porta 443), permitindo o acesso ao endpoint `api.openai.com` enquanto o restante da namespace permanece isolado.

#### 4.4 Commit

```bash
git add apps/core/networkpolicies
git commit -m "mod02: NetworkPolicies bloqueiam openai.com para todos exceto core-litellm"
git push origin main
```

---

## 5. Como verificar

### 1. Istio – mTLS STRICT STRICT e componentes

```bash
kubectl get ns istio-system
kubectl get pods -n istio-system
kubectl get istiooperator -n istio-system
kubectl get peerauthentication -n istio-system
kubectl get peerauthentication default -n istio-system -o yaml
```

Verificar:

```yaml
mtls:
  mode: STRICT
```

### 2. Traefik – borda única

```bash
kubectl get deploy,svc -n appgear-core | grep core-traefik
kubectl get ingressroute -n appgear-core
```

Esperado:

* Deployment `core-traefik` em `READY`;
* Service `core-traefik` do tipo `LoadBalancer` (ou `NodePort`, conforme ambiente);
* `IngressRoute` `core-edge` com único backend `core-coraza` em `security`.

### 3. Coraza – WAF e upstream fixo

```bash
kubectl get deploy,svc,configmap -n security | grep core-coraza
```

Esperado:

* Deployment `core-coraza` em `READY`;
* Service `core-coraza` porta `8080`;
* ConfigMap `core-coraza-config` presente.

Verificar upstream:

```bash
kubectl get configmap core-coraza-config -n security -o jsonpath='{.data.waf-config\.yaml}'
echo
```

Esperado:

* Linha com:
  `upstream: "http://core-kong.appgear-core.svc.cluster.local:8000"`

Verificar imagem:

```bash
kubectl get deploy core-coraza -n security -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Esperado:

* `ghcr.io/corazawaf/coraza-proxy:v1.0.0` (ou tag fixa definida).

### 4. Labels de Governança e FinOps (`tenant-id`)

```bash
kubectl get ns istio-system -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get deploy core-traefik -n appgear-core -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get svc core-traefik -n appgear-core -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get deploy core-coraza -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get configmap core-coraza-config -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
```

Esperado: todos retornando `global`.

### 5. Fluxo fim-a-fim (sem ainda validar Kong/serviços internos)

Com DNS da borda configurado:

```bash
curl -k https://core.dev.appgear.local/healthz -v
```

Verificar:

* A requisição é atendida por `core-traefik` (logs em `appgear-core`);
* A requisição é encaminhada a `core-coraza` (logs em `security`);
* A partir deste módulo, o próximo passo é validar a integração com Kong (módulo específico de Kong/API Gateway).

### 6. NetworkPolicies – bloqueio de egress para LLMs

```bash
kubectl get networkpolicy -n appgear-core | grep egress
kubectl describe networkpolicy allow-litellm-openai -n appgear-core
```

Esperado:

* `deny-external-egress` presente e selecionando todos os pods em `appgear-core`;
* `allow-litellm-openai` presente com `podSelector` filtrando apenas `core-litellm`.

---

## 6. Erros comuns

* **Reintroduzir `.env` em Kustomize/Argo CD**

  * Sintoma: Argo CD falha na renderização (`configMapGenerator` com `envs: [".env"]`).
  * Correção:

    * Remover qualquer uso de `.env` em `kustomization.yaml`;
    * Manter upstream/URLs somente em manifests YAML.

* **Criar Ingress/IngressRoute direto para serviços internos (bypass do WAF/Kong)**

  * Sintoma: caminhos HTTP externos que não passam por `core-edge`.
  * Correção:

    * Proibir Ingress/IngressRoute que não apontem para `core-coraza` (ou para camada documentada em módulo futuro);
    * Remover objetos fora do padrão e redirecionar via Kong.

* **Alterar upstream do Coraza sem coordenar com o DNS interno do Kong**

  * Sintoma: `502 Bad Gateway` no WAF.
  * Correção:

    * Garantir que o Service do Kong seja sempre `core-kong.appgear-core.svc.cluster.local:8000`;
    * Atualizar ConfigMap e rede só via change control.

* **Omitir `appgear.io/tenant-id` ou demais labels de Governança**

  * Sintoma: relatórios de FinOps e Auditoria sem correlação por tenant/topologia.
  * Correção:

    * Adicionar labels `appgear.io/*` em TODOS os manifests do módulo.

* **Alterar `mTLS STRICT` para `PERMISSIVE` em `PeerAuthentication`**

  * Sintoma: perda de segurança Leste–Oeste, permitindo tráfego em texto claro.
  * Correção:

    * Restaurar manifest conforme `peerauthentication-global-strict.yaml` deste módulo.

---

## 7. Onde salvar

* **Documento de governança deste módulo:**

  * Repositório: `appgear-contracts` (ou `appgear-docs`, conforme estratégia de documentação unificada);
  * Arquivo sugerido:

    * `desenvolvimento/2 - Malha de Serviço e Borda v0.md`
      ou
    * `docs/architecture/Modulo 02 - Malha de Serviço e Borda v0.md`.

* **Manifests GitOps (Topologia B):**

  * Repositório: `appgear-gitops-core` (ou equivalente definido pelo M00/M01)
  * Estrutura:

    ```text
    apps/core/istio/
      namespace.yaml
      istio-operator.yaml
      peerauthentication-global-strict.yaml
      kustomization.yaml

    apps/core/traefik/
      deployment.yaml
      service.yaml
      ingressroute-core-edge.yaml
      kustomization.yaml

    apps/core/security/
      kustomization.yaml
      coraza/
        configmap-waf.yaml
        deployment.yaml
        service.yaml
        kustomization.yaml
    ```

* **Referências cruzadas:**

  * `1 - Desenvolvimento v0` deve apontar este módulo como **padrão obrigatório** de tráfego Norte–Sul e Leste–Oeste na Topologia B;
  * `2 - Auditoria v0` deve usar a cadeia Traefik → Coraza → Kong → Istio e mTLS STRICT STRICT como critérios de conformidade;
  * Módulo de Kong/API Gateway deve referenciar explicitamente este módulo como base da borda.

---

## 8. Dependências entre os módulos

A relação deste módulo com os demais módulos AppGear deve ser respeitada para garantir uma implantação ordenada e coerente:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * É **pré-requisito direto** deste módulo.
  * Fornece:

    * convenções de nomes de clusters (`ag-<regiao>-core-<env>`),
    * padrão de labels `appgear.io/*` usado em todos os manifests aqui,
    * regras de uso de `.env` (nunca em Kustomize/Argo CD),
    * diretrizes gerais de governança, healthchecks e Policy as Code.

* **Módulo 01 – Bootstrap GitOps e Argo CD**

  * Também é **pré-requisito** deste módulo.
  * Fornece:

    * Argo CD instalado e configurado,
    * AppProjects e Applications root para `appgear-gitops-core`,
    * fluxo GitOps pelo qual este módulo é aplicado (não se aplica direto via `kubectl apply`).

* **Módulo 02 – Malha de Serviço e Borda (este módulo)**

  * Depende de:

    * **M00** (governança, labels, nomenclatura),
    * **M01** (GitOps/Argo CD).
  * Entrega:

    * Istio com mTLS STRICT STRICT na Topologia B,
    * Traefik como borda única,
    * Coraza como WAF com upstream fixo para Kong,
    * cadeia de borda formalizada: **Traefik → Coraza → Kong → Istio**.

* **Módulo 03 – Observabilidade e FinOps**

  * **Depende deste módulo** para:

    * coletar métricas e logs de Traefik, Istio e Coraza,
    * aplicar FinOps sobre custos de borda e malha utilizando labels `appgear.io/*`.

* **Módulo 04 – Armazenamento e Bancos Core**

  * **Depende indiretamente deste módulo**:

    * todo tráfego de aplicações que consomem bancos/brokers passa pela malha (Istio mTLS STRICT STRICT),
    * exposição de APIs de dados (quando aplicável) deve respeitar a cadeia de borda definida aqui.

* **Módulos de Kong/API Gateway, SSO, Segurança/Segredos e Suites**

  * Devem:

    * se encaixar na cadeia **Traefik → Coraza → Kong → Istio** definida neste módulo,
    * reutilizar labels, namespaces e padrões de borda/malha estabelecidos aqui,
    * não criar rotas paralelas que bypassam WAF ou malha.

Em resumo:

* **M00 → M01 → M02 → (M03, M04, Kong, SSO, Suites, etc.)**
* Qualquer componente que exponha tráfego HTTP(s) ou RPC do cluster AppGear na Topologia B deve ser compatível e aderente à malha e borda definidas neste Módulo 02.

---

## 9. Metadados
- Gerado automaticamente por CodeGPT
- Versão do módulo: v0.3
- Compatibilidade: full
- Data de geração: 2025-11-24
