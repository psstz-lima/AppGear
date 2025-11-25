# Módulo 16 – Conectividade Híbrida (VPN, Túneis, Acesso Remoto)

Versão: v0.2

### Atualizações v0.2

- Conectividade híbrida Tailscale (Operator/Compose) com segredos no Vault e limites rotulados para FinOps.


### Premissas padrão (v0.2)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Padroniza VPN e túneis entre a AppGear e redes privadas de clientes/legados.
Utiliza Tailscale (Operator no K8s e serviço em Docker) para expor/redirecionar subnets e serviços (como o API Server) de forma segura, auditável e com limites de recursos.

---

## O que é

O **Módulo 16 – Conectividade Híbrida** define a camada de **VPN / túneis mesh / acesso remoto seguro** da AppGear.

Ele é composto por quatro blocos principais:

1. **Tailscale Kubernetes Operator (Topologia B – K8s)**

   * Instalado no namespace `connectivity`.
   * Gerencia:

     * **Connectors** (Subnet Router) para acessar redes privadas externas (bancos legados, datacenters, etc.).
     * **ProxyGroups** para expor serviços internos (principalmente o **API Server do cluster**) via VPN.

2. **Vault + ExternalSecrets (M05)**

   * Armazena e injeta, com rotação automática:

     * `CLIENT_ID` e `CLIENT_SECRET` do OAuth Client Tailscale usado pelo Operator.
     * Opcionalmente `auth_key` para cenários de demo/Topologia A.

3. **FinOps e Governança de Recursos**

   * Todos os recursos de conectividade recebem:

     * `appgear.io/tenant-id: global` (custos de VPN atribuídos à infraestrutura global).
   * Limites de CPU/memória:

     * No **Deployment do Operator**.
     * Nos **pods de proxy**, via `ProxyClass`.

4. **Topologia A (Docker)**

   * Serviço `vpn-gateway` em `docker-compose.yml` rodando `tailscale/tailscale`.
   * Expõe a rede Docker/host para o tailnet, permitindo:

     * Demos remotas do ambiente local.
     * Acesso a bancos/serviços legados locais sem abrir portas públicas.

---

## Por que

1. **Conectar cluster na nuvem a infra on-premise sem expor portas de entrada**

* Túneis outbound (cluster/host → Tailscale), respeitando firewalls existentes.
* Permite que workloads da AppGear alcancem bancos e sistemas legados em redes privadas.

2. **Reduzir superfície de ataque de componentes críticos**

* O **API Server** passa a ser acessível principalmente via Proxy Tailscale (ProxyGroup), apenas para usuários/grupos autorizados.
* UIs administrativas podem, opcionalmente, ficar atrás da VPN, reduzindo pressão sobre a borda HTTP (M02/M05).

3. **FinOps para tráfego de VPN**

* Custos de egress e tráfego de VPN podem ser associados a:

  * `appgear.io/tenant-id: global` (infra plataforma).
* `resources.requests/limits` protegem o cluster de:

  * consumo excessivo por túneis saturados.

4. **Alinhamento com Segurança (M05) e Identidade/SSO (M06)**

* Segredos OAuth são mantidos exclusivamente no **Vault**, com injeção via **ExternalSecrets**, evitando credenciais fixas em manifests.
* Grupos de acesso (SSO) no Tailscale/IdP seguem o mesmo IdP da AppGear (Keycloak/IdP corporativo), mantendo coerência de RBAC.

---

## Pré-requisitos

### Organizacionais

* Tailnet Tailscale criado e integrado ao IdP corporativo (Keycloak/Google/Microsoft) definido no M06.
* Usuário Admin da tailnet com permissão para:

  * Criar OAuth Client (CLIENT_ID / CLIENT_SECRET).
  * Definir ACLs e TagOwners.
  * Aprovar rotas de Subnet Router.

### Técnicos – Topologia B (Kubernetes)

* Cluster AppGear core (`ag-<regiao>-core-<env>`) com módulos M00–M15 aplicados, incluindo:

  * Argo CD (M01).
  * Vault + ExternalSecrets (M05).
  * Istio + Traefik + Coraza/Kong (M02).
  * Observabilidade (Prometheus, Grafana, Loki, etc.) (M03).
* Informações de rede:

  * `POD_CIDR` (ex.: `10.42.0.0/16`).
  * `SERVICE_CIDR` (ex.: `10.43.0.0/16`).
  * `LEGACY_DB_CIDR` (ex.: `10.10.0.0/16`) – rede do banco legado ou sistema externo.

### Técnicos – Topologia A (Docker)

* Host Ubuntu LTS com Docker / docker-compose.
* Estrutura básica em `/opt/appgear/`:

  * `.env` central.
  * `docker-compose.yml` com serviços de demo da AppGear.

---

## Como fazer (comandos)

### 1. Variáveis do `.env` central (referência e Topologia A)

No host (Topologia A):

```bash
cd /opt/appgear

cat >> .env << 'EOF'
# --- Tailscale / Conectividade Híbrida ---
TAILSCALE_TAILNET=empresa-tailnet-name

# Credenciais do OAuth Client do operador (referência local; no cluster vêm do Vault)
TAILSCALE_OAUTH_CLIENT_ID=tsclient-xxxxxxxx
TAILSCALE_OAUTH_CLIENT_SECRET=tssecret-xxxxxxxx

# Auth key efêmera para vpn-gateway (Topologia A / demo)
TAILSCALE_AUTH_KEY=tskey-auth-xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# CIDRs de rede
POD_CIDR=10.42.0.0/16
SERVICE_CIDR=10.43.0.0/16
LEGACY_DB_CIDR=10.10.0.0/16
EOF
```

Enviar credenciais para o Vault (M05):

```bash
vault kv put kv/appgear/connectivity/tailscale \
  client_id="$TAILSCALE_OAUTH_CLIENT_ID" \
  client_secret="$TAILSCALE_OAUTH_CLIENT_SECRET" \
  auth_key="$TAILSCALE_AUTH_KEY"
```

> No cluster, **sempre** usar ExternalSecrets apontando para `kv/appgear/connectivity/tailscale`. Nenhum Secret estático com `CLIENT_ID` / `CLIENT_SECRET` deve ser criado manualmente.

---

### 2. Estrutura GitOps – `appgear-gitops-core`

No repositório GitOps Core:

```bash
cd appgear-gitops-core
mkdir -p apps/core/connectivity/connectors
```

`apps/core/connectivity/kustomization.yaml`:

```bash
cat > apps/core/connectivity/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: connectivity

resources:
  - namespace.yaml
  - tailscale-operator.yaml
  - auth-secret-placeholder.yaml
  - proxyclass-k8s-default.yaml
  - connectors/legacy-subnet-connector.yaml
  - connectors/k8s-api-proxy.yaml
EOF
```

---

### 3. Namespace `connectivity` com FinOps

`apps/core/connectivity/namespace.yaml`:

```bash
cat > apps/core/connectivity/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: connectivity
  labels:
    app.kubernetes.io/name: connectivity
    app.kubernetes.io/part-of: appgear
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tier: core
    appgear.io/tenant-id: global
EOF
```

> A label `appgear.io/tenant-id: global` garante rastreio de custos de VPN associados à infraestrutura global.

---

### 4. ExternalSecret – Segredos OAuth (Vault → K8s)

`apps/core/connectivity/auth-secret-placeholder.yaml`:

```bash
cat > apps/core/connectivity/auth-secret-placeholder.yaml << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: tailscale-operator-oauth
  namespace: connectivity
  labels:
    app.kubernetes.io/name: tailscale-operator-oauth
    app.kubernetes.io/part-of: appgear
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: vault-appgear-kv
    kind: ClusterSecretStore
  target:
    name: tailscale-operator-oauth
    creationPolicy: Owner
  data:
    - secretKey: CLIENT_ID
      remoteRef:
        key: kv/appgear/connectivity/tailscale
        property: client_id
    - secretKey: CLIENT_SECRET
      remoteRef:
        key: kv/appgear/connectivity/tailscale
        property: client_secret
EOF
```

---

### 5. Deployment do Tailscale Operator (FinOps + Resources)

`apps/core/connectivity/tailscale-operator.yaml`:

```bash
cat > apps/core/connectivity/tailscale-operator.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tailscale-operator
  namespace: connectivity
  labels:
    app.kubernetes.io/name: tailscale-operator
    app.kubernetes.io/part-of: appgear
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tier: core
    appgear.io/tenant-id: global
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tailscale-operator
  namespace: connectivity
  labels:
    app.kubernetes.io/name: tailscale-operator
    app.kubernetes.io/part-of: appgear
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: tailscale-operator
  template:
    metadata:
      labels:
        app.kubernetes.io/name: tailscale-operator
        app.kubernetes.io/part-of: appgear
        appgear.io/module: "mod16-connectivity-hybrid"
        appgear.io/tier: core
        appgear.io/tenant-id: global
    spec:
      serviceAccountName: tailscale-operator
      containers:
        - name: operator
          image: tailscale/k8s-operator:stable
          imagePullPolicy: IfNotPresent
          env:
            - name: CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: tailscale-operator-oauth
                  key: CLIENT_ID
            - name: CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: tailscale-operator-oauth
                  key: CLIENT_SECRET
            # Habilita o Proxy do API Server em modo autenticado
            - name: APISERVER_PROXY
              value: "auth"
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
EOF
```

---

### 6. ProxyClass – Limites para Pods de Proxy

`apps/core/connectivity/proxyclass-k8s-default.yaml`:

```bash
cat > apps/core/connectivity/proxyclass-k8s-default.yaml << 'EOF'
apiVersion: tailscale.com/v1alpha1
kind: ProxyClass
metadata:
  name: tailscale-proxy-default
  labels:
    app.kubernetes.io/name: tailscale-proxy-default
    app.kubernetes.io/part-of: appgear
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  # Template base aplicado aos pods de proxy (ProxyGroup)
  template:
    metadata:
      labels:
        appgear.io/module: "mod16-connectivity-hybrid"
        appgear.io/tier: core
        appgear.io/tenant-id: global
    spec:
      containers:
        - name: proxy
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
EOF
```

---

### 7. Connector – Subnet Router para Rede Legada

`apps/core/connectivity/connectors/legacy-subnet-connector.yaml`:

```bash
cat > apps/core/connectivity/connectors/legacy-subnet-connector.yaml << 'EOF'
apiVersion: tailscale.com/v1alpha1
kind: Connector
metadata:
  name: legacy-subnet-connector
  labels:
    app.kubernetes.io/name: legacy-subnet-connector
    app.kubernetes.io/part-of: appgear
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  hostname: ag-core-legacy-subnet
  # Tag usada nas ACLs da Tailnet; tagOwners deve incluir o operador
  tags:
    - "tag:appgear-cluster"
  subnetRouter:
    # Rede do banco legado on-premise (ajustar para o CIDR real)
    advertiseRoutes:
      - "10.10.0.0/16"
EOF
```

> `Connector` é cluster-scoped, por isso não há campo `namespace`.

---

### 8. ProxyGroup – API Server via VPN (com ProxyClass)

`apps/core/connectivity/connectors/k8s-api-proxy.yaml`:

```bash
cat > apps/core/connectivity/connectors/k8s-api-proxy.yaml << 'EOF'
apiVersion: tailscale.com/v1alpha1
kind: ProxyGroup
metadata:
  name: ag-core-apiserver
  labels:
    app.kubernetes.io/name: ag-core-apiserver
    app.kubernetes.io/part-of: appgear
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tier: core
    appgear.io/tenant-id: global
spec:
  type: kube-apiserver
  replicas: 2
  tags:
    - "tag:k8s"
  # Aplica a ProxyClass com limites de recursos
  classRef:
    name: tailscale-proxy-default
  kubeAPIServer:
    mode: auth
EOF
```

---

### 9. Application Argo CD – `core-connectivity`

Em `clusters/ag-<regiao>-core-<env>/apps-core.yaml`:

```bash
cat >> clusters/ag-br-core-dev/apps-core.yaml << 'EOF'
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-connectivity
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/module: "mod16-connectivity-hybrid"
    appgear.io/tenant-id: global
spec:
  project: default
  source:
    repoURL: git@github.com:appgear/appgear-gitops-core.git
    targetRevision: main
    path: apps/core/connectivity
  destination:
    server: https://kubernetes.default.svc
    namespace: connectivity
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
EOF
```

Sincronizar:

```bash
argocd app sync core-connectivity
```

---

### 10. Topologia A – Serviço `vpn-gateway` no `docker-compose.yml`

No host de demo:

```bash
cd /opt/appgear

cat >> docker-compose.yml << 'EOF'

  vpn-gateway:
    image: tailscale/tailscale:latest
    container_name: vpn-gateway
    hostname: vpn-gateway
    restart: unless-stopped
    environment:
      - TS_AUTHKEY=${TAILSCALE_AUTH_KEY}
      - TS_ROUTES=172.20.0.0/16      # Rede docker/host a ser exposta ao tailnet
      - TS_TAILNET=${TAILSCALE_TAILNET}
    volumes:
      - /var/lib/tailscale:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - NET_RAW
    network_mode: "host"
EOF
```

Subir:

```bash
docker compose up -d vpn-gateway
```

> Topologia A é apenas para desenvolvimento/demo. Produção e ambientes Enterprise devem usar exclusivamente a Topologia B (Kubernetes + Operator).

---

## Como verificar

### 1. Operador e ExternalSecret

```bash
kubectl get ns connectivity

kubectl get deploy -n connectivity tailscale-operator
kubectl get pods -n connectivity -l app.kubernetes.io/name=tailscale-operator

kubectl get externalsecret -n connectivity
kubectl describe externalsecret -n connectivity tailscale-operator-oauth

kubectl get secret -n connectivity tailscale-operator-oauth -o yaml
```

Esperado:

* Namespace `connectivity` presente.
* Deployment `tailscale-operator` com pods `Running`.
* ExternalSecret com `status` pronto e Secret com chaves `CLIENT_ID` / `CLIENT_SECRET`.

### 2. Connector e rotas

```bash
kubectl get connector
kubectl describe connector legacy-subnet-connector
```

* `status.conditions` indicando `Ready = True`.

No painel Tailscale:

* Rota `10.10.0.0/16` deve aparecer anunciada e aprovada.

Teste a partir de um pod:

```bash
kubectl run netshoot --rm -it \
  --image=nicolaka/netshoot \
  --command -- bash

# dentro do pod:
ping -c3 10.10.0.20      # IP de teste da rede legada
nc -vz 10.10.0.20 5432   # porta do banco legado, por exemplo
```

### 3. ProxyClass e ProxyGroup

```bash
kubectl get proxyclass
kubectl describe proxyclass tailscale-proxy-default

kubectl get proxygroup
kubectl describe proxygroup ag-core-apiserver
```

* ProxyClass existe com `resources` em `spec.template.spec.containers[proxy].resources`.
* ProxyGroup aponta `classRef.name: tailscale-proxy-default`.

No notebook do dev (com Tailscale instalado):

```bash
tailscale status | grep ag-core-apiserver

# Exemplo de uso (contexto via kubeconfig gerado pelo ProxyGroup)
kubectl --context=https://ag-core-apiserver.tailnet-xyz.ts.net get nodes
```

### 4. Labels FinOps

```bash
kubectl get deploy -n connectivity tailscale-operator -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}'

kubectl get proxygroup ag-core-apiserver -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}'

kubectl get connector legacy-subnet-connector -o jsonpath='{.metadata.labels.appgear\.io/tenant-id}'
```

* Esperado: `global` em todos.

### 5. Topologia A – `vpn-gateway`

```bash
docker ps | grep vpn-gateway
docker logs vpn-gateway --tail=50
```

No laptop (no mesmo tailnet):

```bash
tailscale status | grep vpn-gateway
ping -c3 <ip-do-host>
```

* Testar acesso a algum serviço exposto na Topologia A (ex.: `http://<ip-do-host>:8055`).

---

## Erros comuns

1. **Criar Secret estático em vez de ExternalSecret**

* Sintoma:

  * Secret `tailscale-operator-oauth` criado manualmente, sem vinculação ao Vault.
* Correção:

  * Manter apenas o `ExternalSecret` apontando para `kv/appgear/connectivity/tailscale`.
  * Remover Secret manual e deixar external-secrets sincronizar.

2. **Ausência de `appgear.io/tenant-id: global`**

* Sintoma:

  * Falta de rastreio de custos de VPN em OpenCost/Lago.
* Correção:

  * Revisar `namespace.yaml`, `tailscale-operator.yaml`, `proxyclass-k8s-default.yaml`, `legacy-subnet-connector.yaml`, `k8s-api-proxy.yaml` e `apps-core.yaml`.

3. **CRDs do Operator não aplicados**

* Sintoma:

  * Erros “no matches for kind `ProxyClass` / `ProxyGroup` / `Connector`”.
* Correção:

  * Aplicar previamente os CRDs oficiais do Tailscale Operator na camada de infra (Módulo de bootstrap K8s).

4. **ProxyClass sem `resources`**

* Sintoma:

  * Pods de proxy sem `resources` em `kubectl describe pod`.
* Correção:

  * Ajustar `proxyclass-k8s-default.yaml` e garantir que `classRef.name` em `ProxyGroup` está correto.

5. **Rotas do Connector não aprovadas**

* Sintoma:

  * Ping/timeouts para IPs da rede legada, apesar de `Connector` estar `Ready`.
* Correção:

  * Aprovar rota no painel Tailscale ou configurar auto-approval conforme política de segurança.

6. **ACLs do API Server incompletas na Tailnet**

* Sintoma:

  * Desenvolvedores não conseguem `kubectl` via ProxyGroup.
* Correção:

  * Ajustar policy do tailnet para permitir que grupos `group:k8s-admins` / `group:k8s-readers` acessem `tag:k8s` na porta 443.

7. **Problemas de rede na Topologia A (Docker)**

* Sintoma:

  * Logs indicam erro em `/dev/net/tun` ou permissões insuficientes.
* Correção:

  * Garantir `cap_add: [NET_ADMIN, NET_RAW]` e volume `/dev/net/tun` conforme o compose.

---

## Onde salvar

1. **GitOps Core (Topologia B – Kubernetes)**

* Repositório: `appgear-gitops-core`.
* Estrutura:

```text
apps/core/connectivity/
  kustomization.yaml
  namespace.yaml
  tailscale-operator.yaml
  auth-secret-placeholder.yaml
  proxyclass-k8s-default.yaml
  connectors/
    legacy-subnet-connector.yaml
    k8s-api-proxy.yaml

clusters/ag-<regiao>-core-<env>/
  apps-core.yaml    # Application core-connectivity
```

2. **Vault (M05)**

* Path: `kv/appgear/connectivity/tailscale`

  * `client_id`
  * `client_secret`
  * `auth_key` (quando necessário para Topologia A/demo).

3. **Host Topologia A (Docker)**

* Diretórios/arquivos:

```text
/opt/appgear/.env                 # inclui variáveis Tailscale
/opt/appgear/docker-compose.yml   # serviço vpn-gateway
/opt/appgear/logs/                # logs gerais (se usados)
```

4. **Contrato / Documentação**

* Repositório: `appgear-contracts`.
* Arquivo:

  * `Módulo 16 – Conectividade Híbrida (VPN, Túneis e Acesso Remoto) v0.1.md`.
* Referência em:

  * `1 - Desenvolvimento v0.md`, seção correspondente ao Módulo 16.

---

## Dependências entre os módulos

A posição do **Módulo 16 – Conectividade Híbrida** na arquitetura AppGear é:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * Pré-requisito direto.
  * Define:

    * forma canônica (`*.md`);
    * nomenclaturas de módulos (`core-*`, `addon-*`, `mod16-*`);
    * labels `appgear.io/*` (incluindo `appgear.io/tenant-id`) usadas em todos os manifests deste módulo.

* **Módulo 01 – GitOps e Argo CD (App-of-Apps)**

  * Pré-requisito direto.
  * Fornece:

    * Argo CD como orquestrador GitOps;
    * App-of-Apps para registrar o `Application core-connectivity` que sincroniza este módulo.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * Pré-requisito funcional.
  * Fornece:

    * Istio (mTLS STRICT) para tráfego interno entre Operator, pods, serviços core;
    * Borda HTTP para casos em que UIs administrativas ainda precisem ser expostas externamente (combinadas ou não com acesso via VPN).

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * Dependência mútua.
  * M03:

    * coleta métricas e logs do Operator Tailscale e pods de proxy;
    * calcula custos de tráfego de rede/CPU/memória com base nas labels `appgear.io/tenant-id`.
  * M16:

    * garante labels e `resources` nos recursos de conectividade, permitindo visibilidade clara de custos de VPN e egress.

* **Módulo 04 – Armazenamento e Bancos Core**

  * Dependência indireta.
  * Fornece:

    * storage para logs e estados persistentes que podem ser acessados via túneis;
    * bancos que podem residir em redes alcançadas através do `Connector` (bancos legados).

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * Pré-requisito direto.
  * Fornece:

    * Vault + ExternalSecrets para manter segredos Tailscale (`client_id`, `client_secret`, `auth_key`);
    * OPA pode validar manifests de conectividade conforme políticas de segurança;
    * Falco monitora comportamentos suspeitos nos pods do Operator e proxies;
    * OpenFGA gerencia permissões no plano de controle (quem pode alterar/criar Connectors, ProxyGroups, etc.).

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * Pré-requisito funcional.
  * Fornece:

    * IdP central, reaproveitado pelo tailnet Tailscale para SSO;
    * grupos de usuários (ex.: `k8s-admins`, `k8s-readers`) usados em ACLs Tailscale para acesso via ProxyGroup ao API Server.

* **Módulo 07 – Portal Backstage e Integrações Core**

  * Consumidor indireto.
  * Pode:

    * exibir status de conectividade (por meio de plugins/observabilidade);
    * acionar fluxos N8n (M14) para, por exemplo, provisionar conectores adicionais como parte de automações.

* **Módulo 08 – Serviços Core (LiteLLM, Flowise, N8n, Directus, Appsmith, etc.)**

  * Consumidores indiretos.
  * Serviços Core podem:

    * acessar bancos/sistemas legados via túnel (Connector);
    * expor endpoints administrativos acessíveis apenas via tailnet.

* **Módulos 09, 10, 11, 12 – Suítes Factory, Brain, Operations, Guardian**

  * Consumidores indiretos.
  * Podem:

    * usar conectividade híbrida para integração com ERPs legados, dispositivos em redes privadas, sistemas de segurança externos;
    * expor endpoints sensíveis apenas via tailnet, reduzindo exposição em borda pública.

* **Módulo 13 – Workspaces, vCluster e modelo por cliente**

  * Dependência funcional.
  * Workspaces/vClusters podem:

    * depender de conectividade híbrida para acesso a sistemas do cliente;
    * ser acessados via VPN (ProxyGroups) para operações de suporte, sem expor diretamente endpoints de vClusters.

* **Módulo 14 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD)**

  * Consumidor indireto.
  * Pipelines AI-First podem:

    * conectar-se a repositórios, ferramentas e bancos localizados em redes privadas via VPN;
    * executar testes E2E que validem integrações com sistemas legados acessíveis pelos Connectors.

* **Módulo 15 – Continuidade de Negócios (DR & Backup Global)**

  * Dependência indireta.
  * DR pode:

    * usar conectividade híbrida para sincronizar backups com storage externo em redes privadas;
    * restaurar ambientes em cenários de desastre em que a conectividade com datacenters do cliente é via VPN.

* **Módulo 16 – Conectividade Híbrida (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M05, M06** principalmente.
  * Entrega:

    * a camada padronizada de VPN, túneis e acesso remoto seguro para toda a plataforma AppGear.

Fluxo resumido de dependência:

**M00 → M01 → M02 → M03 → (M04) → M05 → M06 → (M07–M12, M13–M15) → M16**

Sem o **Módulo 16**, a AppGear teria borda HTTP/malha de serviço bem definidas, mas careceria de uma solução centralizada e governada de **conectividade híbrida**, dificultando integrações com legados on-premise, acesso remoto seguro ao cluster e redução da exposição de componentes críticos em redes públicas.
