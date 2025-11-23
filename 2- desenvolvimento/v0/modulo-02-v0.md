Perfeito, vamos fechar o Módulo 02 sem nenhuma pendência de correção futura, incluindo o ajuste do BUG GITOPS e a decisão de **tratar o upstream do Kong como constante arquitetural**, sem depender de `.env` no Kustomize/Argo CD.

Abaixo está o **Módulo 2 completo, reescrito do zero**, já com:

* Cadeia de borda obrigatória
  `Traefik → Coraza → Kong → Istio → Serviços`.
* Istio com **mTLS STRICT**.
* Labels de governança incluindo `appgear.io/tenant-id: global`.
* Coraza com imagem **pinada**.
* **Sem uso de `.env` local no Kustomize**: o upstream `core-kong.appgear-core.svc.cluster.local:8000` é tratado como **constante da Topologia B** e configurado diretamente em `ConfigMap` YAML (GitOps-safe).

Você pode substituir diretamente a seção do Módulo 2 em `1 - Desenvolvimento v0.md` por este texto.

---

# Módulo 2 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong) – v0.2

## O que é

Este módulo define a **rede core** da plataforma AppGear na **Topologia B (Kubernetes)**, estabelecendo que:

1. Todo tráfego **interno** (Leste–Oeste) passa pela **malha de serviço Istio**, com **mTLS em modo STRICT**.

2. Todo tráfego **externo** (Norte–Sul) é obrigado a seguir a cadeia:

   ```text
   Traefik (Ingress Controller)
     → Coraza (WAF)
       → Kong (API Gateway)
         → Istio (Service Mesh)
           → Serviços internos (core-* e ws-*)
   ```

3. Todos os recursos deste módulo usam labels de governança e FinOps:

   ```yaml
   appgear.io/tier: core
   appgear.io/suite: core
   appgear.io/topology: B
   appgear.io/workspace-id: global
   appgear.io/tenant-id: global
   ```

4. A configuração do **Coraza** é 100% GitOps-safe:

   * **sem** dependência de `.env` local no Kustomize/Argo CD;
   * o **upstream para o Kong** é um DNS interno **fixo** da Topologia B:
     `http://core-kong.appgear-core.svc.cluster.local:8000`.

---

## Por que

* Atende ao **Contrato v0** e aos roteiros de:

  * **Auditoria v0**:

    * G05 – Cadeia de borda implementada (Traefik → Coraza → Kong → Istio);
    * G06 – mTLS STRICT na malha;
    * M00-3 – Labels de FinOps (`tenant-id`) corretas.
  * **Interoperabilidade v0**:

    * Impede caminhos alternativos fora da cadeia oficial;
    * Padroniza o fluxo de tráfego para todos os módulos.

* Garante modelo **Zero-Trust**:

  * Ninguém publica serviço diretamente em Traefik;
  * Nenhum serviço de negócio é exposto como `LoadBalancer/NodePort`;
  * Todo acesso passa por WAF (Coraza) e API Gateway (Kong).

* Resolve o **BUG GITOPS**:

  * Não existe mais `configMapGenerator envs: [.env]` no Kustomize;
  * Todos os ConfigMaps são manifestos YAML comitados, sem depender de arquivos locais não versionados.

* Evita dívida técnica futura:

  * Upstream do Coraza **não depende de `.env`**;
  * Imagens pinadas (sem `:latest`).

---

## Pré-requisitos

1. **Governança**

   * `0 - Contrato v0`, `2 - Auditoria v0` e `3 - Interoperabilidade v0` aprovados.
   * Regras do Módulo 00 em vigor:

     * Padrões de labels `appgear.io/*`;
     * Proibição de comitar `.env` nos repositórios GitOps;
     * Uso de `.env` apenas como fonte de verdade para CI/CD (não para render Kustomize dentro do Argo CD).

2. **Módulos anteriores**

   * **M00** – Convenções, `.env` central, estrutura de repositórios, nomes de clusters, domínios.
   * **M01** – Bootstrap GitOps + Argo CD (App-of-Apps) apontando para `apps/core/*`.

3. **Repositório GitOps**

   Repositório (ex.: `appgear-infra-core` ou `webapp-ia-gitops-core`) com ao menos:

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
   * Namespaces:

     * `istio-system`, `appgear-core`, `security`, `backstage`, `observability`;
   * Argo CD acompanhando `clusters/ag-br-core-<env>/apps-core.yaml`.

5. **.env central (M00)**

   Continua existindo (para domínios, ambiente etc.), mas **não** é usada diretamente pelo Kustomize no Argo CD. Exemplo:

   ```env
   APPGEAR_ENV=dev
   APPGEAR_BASE_DOMAIN=appgear.local
   APPGEAR_CORE_FQDN=core.${APPGEAR_ENV}.${APPGEAR_BASE_DOMAIN}
   APPGEAR_TENANT_ID_GLOBAL=global
   ```

   O **DNS interno do Kong** (Service `core-kong`) é considerado **constante da Topologia B**:

   ```text
   http://core-kong.appgear-core.svc.cluster.local:8000
   ```

---

## Como fazer (comandos)

> Todos os manifests abaixo são comitados em Git e aplicados via Argo CD.
> Não usar `kubectl apply` direto em produção.

---

### 3.1 Istio – Service Mesh com mTLS STRICT (apps/core/istio)

#### 3.1.1 Namespace e Kustomization

```bash
cd appgear-infra-core   # ou webapp-ia-gitops-core

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
EOF
```

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

#### 3.1.2 IstioOperator (controle + ingress interno)

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
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

#### 3.1.3 PeerAuthentication global STRICT

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
spec:
  mtls:
    mode: STRICT
EOF
```

#### 3.1.4 Commit

```bash
git add apps/core/istio
git commit -m "mod2: Istio com mTLS STRICT e labels tenant-id global"
git push origin main
```

---

### 3.2 Traefik – Ingress Controller da Borda (apps/core/traefik)

Traefik atua como **borda única**:

* Recebe tráfego HTTP/S externo;
* Termina TLS;
* Encaminha **sempre** para o WAF (`core-coraza`).

#### 3.2.1 Kustomization

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

#### 3.2.2 Deployment do Traefik

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
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

#### 3.2.3 Service público do Traefik

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
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

#### 3.2.4 IngressRoute único → Coraza

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
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

> Em `stg`/`prod`, o host deve ser adaptado via overlay (e.g. `core.stg.appgear.cloud`, `core.appgear.cloud`), mas isso é feito no nível de kustomize/overlays, **não** via `.env` acessado pelo Argo CD.

Commit:

```bash
git add apps/core/traefik
git commit -m "mod2: Traefik como borda única encaminhando para Coraza"
git push origin main
```

---

### 3.3 Coraza – WAF com upstream fixo para Kong (apps/core/security/coraza)

#### 3.3.1 Kustomization

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

> Observação: **não há** `configMapGenerator envs: [".env"]` aqui. Tudo é manifesto YAML comitado, compatível com Argo CD.

#### 3.3.2 ConfigMap de configuração WAF (incluindo upstream fixo)

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
data:
  waf-config.yaml: |
    # Configuração simplificada do Coraza como reverse-proxy WAF.
    # O upstream do Kong é uma constante da Topologia B:
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

> Aqui está o ponto central do retrofit:
>
> * O upstream **não** vem de `.env`;
> * Está definido **explicitamente** no ConfigMap YAML, alinhado com o contrato da Topologia B;
> * Argo CD/Kustomize não depende de arquivo `.env` para renderizar.

#### 3.3.3 Deployment do Coraza (imagem pinada)

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
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

#### 3.3.4 Service do Coraza

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
    appgear.io/module: "mod2-mesh-edge-istio-traefik-coraza"
spec:
  selector:
    app.kubernetes.io/name: core-coraza
  ports:
    - name: http
      port: 8080
      targetPort: 8080
EOF
```

Commit:

```bash
git add apps/core/security
git commit -m "mod2: Coraza WAF com upstream fixo para Kong e sem dependência de .env no Kustomize"
git push origin main
```

---

## Como verificar

### 4.1 Istio – mTLS STRICT

```bash
kubectl get ns istio-system
kubectl get pods -n istio-system
kubectl get istiooperator -n istio-system
kubectl get peerauthentication -n istio-system
kubectl get peerauthentication default -n istio-system -o yaml
```

* Esperado:

  * `mtls.mode: STRICT` em `PeerAuthentication default`.

### 4.2 Traefik – borda única

```bash
kubectl get deploy,svc -n appgear-core | grep core-traefik
kubectl get ingressroute -n appgear-core
```

* Esperado:

  * Deployment `core-traefik` READY;
  * Service `core-traefik` `LoadBalancer` (ou `NodePort`, se for o caso);
  * Apenas **um** `IngressRoute`: `core-edge`, apontando para `core-coraza.security.svc:8080`.

### 4.3 Coraza – Configuração GitOps-safe

```bash
kubectl get deploy,svc,configmap -n security | grep core-coraza
```

* Esperado:

  * Deployment `core-coraza` READY;
  * Service `core-coraza` porta 8080;
  * ConfigMap `core-coraza-config` presente.

Verificar upstream fixo:

```bash
kubectl get configmap core-coraza-config -n security -o jsonpath='{.data.waf-config\.yaml}'
```

* Esperado:

  * Conteúdo contendo `upstream: "http://core-kong.appgear-core.svc.cluster.local:8000"`.

Verificar imagem pinada:

```bash
kubectl get deploy core-coraza -n security -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

* Esperado:

  * `ghcr.io/corazawaf/coraza-proxy:v1.0.0` (ou tag fixa equivalente).

### 4.4 Labels `tenant-id` (FinOps/Governança)

Testar em alguns recursos:

```bash
kubectl get ns istio-system -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get deploy core-traefik -n appgear-core -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get svc core-traefik -n appgear-core -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get deploy core-coraza -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
kubectl get configmap core-coraza-config -n security -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}{"\n"}'
```

* Esperado: todos retornando `global`.

### 4.5 Teste fim-a-fim

Com DNS configurado:

```bash
curl -k https://core.dev.appgear.local/healthz -v
```

* Esperado:

  * A requisição passa por:

    * Traefik (`core-traefik`);
    * Coraza (`core-coraza`);
    * Kong (`core-kong`);
  * Logs em todos esses componentes.

---

## Erros comuns

1. **Reintroduzir `.env` no Kustomize (BUG GITOPS)**

   * Sintoma: Argo CD falha ao renderizar Kustomize (`.env` não encontrado).
   * Correção:

     * Garantir que NENHUM `kustomization.yaml` use `envs: [".env"]`.
     * Manter `core-coraza-config` como YAML estático.

2. **Criar Ingress/IngressRoute direto para serviços de negócio**

   * Sintoma: novo host/rota bypassando Coraza/Kong.
   * Correção:

     * Remover Ingress/IngressRoute;
     * Expor via rotas do Kong, que sempre estão por trás de `core-edge → core-coraza`.

3. **Alterar upstream do Coraza sem atualizar DNS interno do Kong**

   * Sintoma: 502 ao passar pelo WAF.
   * Correção:

     * Manter o upstream padrão:
       `http://core-kong.appgear-core.svc.cluster.local:8000`.

4. **Ausência de `appgear.io/tenant-id` em algum manifesto**

   * Sintoma: falha na auditoria M00-3 (custos de rede sem alocação).
   * Correção:

     * Adicionar `appgear.io/tenant-id: global` em todos os recursos do módulo.

5. **mTLS alterado para PERMISSIVE**

   * Sintoma: PeerAuthentication modificado.
   * Correção:

     * Restaurar `peerauthentication-global-strict.yaml` conforme este módulo.

---

## Onde salvar

* Repositório: `appgear-contracts`
* Arquivo: `desenvolvimento/1 - Desenvolvimento v0.md`
* Ação:

  * Substituir integralmente a seção do:

    ```md
    ### Módulo 2 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)
    ```

    por este conteúdo v0.2 (pós-retrofit do BUG GITOPS).

Com isso, o **Módulo 02** fica:

* ✅ Arquiteturalmente correto (cadeia Traefik → Coraza → Kong → Istio).
* ✅ Seguro (mTLS STRICT, WAF obrigatório, sem bypass).
* ✅ Governança/FinOps (labels com `tenant-id`).
* ✅ GitOps-safe (nenhuma dependência de `.env` local no Argo CD).
