Perfeito, vamos tratar este diagnóstico como verdade e fazer o \*\*retrofit completo\*\* do módulo.



Abaixo está o \*\*Módulo 16 – Conectividade Híbrida (VPN, Túneis e Acesso Remoto) – v0.1 (Retrofit)\*\*, já:



\* Em \*\*formato Markdown\*\* (para salvar como `Módulo 16 v0.1.md`);

\* Com \*\*Segurança / Vault / ExternalSecret\*\* explícitos para `CLIENT\_ID` e `CLIENT\_SECRET`;

\* Com \*\*FinOps\*\* (`appgear.io/tenant-id: global`) em todos os manifestos relevantes;

\* Com \*\*resources\*\* definidos:



&nbsp; \* No Deployment do Operador;

&nbsp; \* Em uma \*\*ProxyClass\*\* que controla recursos dos pods de proxy gerados dinamicamente.



---



\# Módulo 16 – Conectividade Híbrida (VPN, Túneis e Acesso Remoto) – v0.1 (Retrofit)



> Módulo 16 do \*\*1 - Desenvolvimento v0\*\*.

> Este retrofit corrige as não conformidades apontadas no diagnóstico:

>

> \* Formato obsoleto (.py → .md)

> \* Ausência de integração explícita com Vault (M05) para segredos OAuth

> \* Falta de labels de FinOps (`appgear.io/tenant-id: global`)

> \* Falta de `resources` para o Operador e para os Proxies (ProxyGroup/ProxyClass)



---



\## 1. O que é



O \*\*Módulo 16 – Conectividade Híbrida\*\* entrega a camada de \*\*VPN/Túneis Mesh\*\* da AppGear, baseada em:



1\. \*\*Tailscale Kubernetes Operator (Topologia B – K8s)\*\*



&nbsp;  \* Instalado no namespace `connectivity`.

&nbsp;  \* Gerencia:



&nbsp;    \* \*\*Connectors\*\* (Subnet Router) para acessar redes privadas externas.

&nbsp;    \* \*\*ProxyGroups\*\* para expor serviços internos (principalmente o \*\*API Server\*\*) via VPN.



2\. \*\*Vault + ExternalSecrets (Módulo 05)\*\*



&nbsp;  \* Armazena e injeta, com rotação:



&nbsp;    \* `CLIENT\_ID` e `CLIENT\_SECRET` do OAuth Client Tailscale do operador.

&nbsp;    \* Opcionalmente `auth\_key` para cenários específicos (demo/Topologia A).



3\. \*\*FinOps e Governança de Recursos\*\*



&nbsp;  \* Todos os recursos de conectividade recebem:



&nbsp;    \* `appgear.io/tenant-id: global` (custo alocado à infraestrutura global).

&nbsp;  \* Limites de CPU/memória:



&nbsp;    \* No \*\*Deployment do Operador\*\*.

&nbsp;    \* Nos \*\*pods de proxy\*\* via `ProxyClass`.



4\. \*\*Topologia A (Docker)\*\*



&nbsp;  \* Serviço `vpn-gateway` no `docker-compose.yml` rodando `tailscale/tailscale`.

&nbsp;  \* Expõe a rede Docker/host para o tailnet, permitindo:



&nbsp;    \* Demos remotas do ambiente local.

&nbsp;    \* Acesso a bancos legados locais sem abrir portas públicas.



---



\## 2. Por que



1\. \*\*Conectar cluster na nuvem ↔ banco legado on-premise sem abrir portas de entrada\*\*



&nbsp;  \* O túnel é \*\*outbound\*\* (cluster/host → Tailscale), respeitando o firewall do cliente.

&nbsp;  \* O cluster passa a alcançar bancos/sistemas antigos em redes privadas.



2\. \*\*Remover IPs públicos de operação (API Server/Argo/CD etc.)\*\*



&nbsp;  \* O \*\*API Server\*\* passa a ser acessível via \*\*ProxyGroup\*\* Tailscale apenas para grupos autorizados.

&nbsp;  \* UIs administrativas podem, opcionalmente, ser movidas para atrás da VPN, reduzindo a exposição da borda (M02/M05).



3\. \*\*Garantir governança (FinOps + Recursos)\*\*



&nbsp;  \* O tráfego de VPN (egress) é rastreável por `appgear.io/tenant-id: global`.

&nbsp;  \* Limites de CPU/memória evitam que um túnel saturado comprometa o nó.



4\. \*\*Alinhar com M05 (Segurança) e M06 (Identidade/SSO)\*\*



&nbsp;  \* Segredos OAuth de alta permissão ficam exclusivamente no Vault, com rotação automática via ExternalSecrets.

&nbsp;  \* Grupos de acesso (SSO) reutilizam o mesmo IdP da AppGear, mantendo coerência no RBAC.



---



\## 3. Pré-requisitos



\### 3.1 Organizacionais



\* Tailnet Tailscale criado e integrado ao IdP corporativo (Keycloak/Google/Microsoft) definido no Módulo 06.

\* Usuário Admin do tailnet para:



&nbsp; \* Criar OAuth Client (CLIENT\_ID / CLIENT\_SECRET).

&nbsp; \* Configurar ACLs e TagOwners.

&nbsp; \* Aprovar rotas de Subnet Router, quando necessário.



\### 3.2 Técnicos – Topologia B (Kubernetes)



\* Cluster AppGear core (M00–M15 aplicados) com:



&nbsp; \* Argo CD (GitOps)

&nbsp; \* Vault + ExternalSecrets

&nbsp; \* Istio + Traefik + Coraza/Kong

&nbsp; \* Observabilidade (Prometheus, Grafana, Loki)



\* Informações de rede:



&nbsp; \* `POD\_CIDR` (ex.: `10.42.0.0/16`)

&nbsp; \* `SERVICE\_CIDR` (ex.: `10.43.0.0/16`)

&nbsp; \* `LEGACY\_DB\_CIDR` (ex.: `10.10.0.0/16`) – rede do banco legado ou sistema externo.



\### 3.3 Técnicos – Topologia A (Docker)



\* Host Ubuntu LTS com Docker / docker-compose.

\* Estrutura básica em `/opt/webapp-ia/`:



&nbsp; \* `.env` central.

&nbsp; \* `docker-compose.yml` com serviços demo AppGear.



---



\## 4. Como fazer (comandos)



\### 4.1 Variáveis do `.env` central (referência e Topologia A)



No host (Topologia A):



```bash

cd /opt/webapp-ia



cat >> .env << 'EOF'

\# --- Tailscale / Conectividade Híbrida ---

TAILSCALE\_TAILNET=empresa-tailnet-name



\# Credenciais do OAuth Client do operador (referência local; no cluster vêm do Vault)

TAILSCALE\_OAUTH\_CLIENT\_ID=tsclient-xxxxxxxx

TAILSCALE\_OAUTH\_CLIENT\_SECRET=tssecret-xxxxxxxx



\# Auth key efêmera para vpn-gateway (Topologia A / demo)

TAILSCALE\_AUTH\_KEY=tskey-auth-xxxxxxxxxxxxxxxxxxxxxxxxxxxx



\# CIDRs de rede

POD\_CIDR=10.42.0.0/16

SERVICE\_CIDR=10.43.0.0/16

LEGACY\_DB\_CIDR=10.10.0.0/16

EOF

```



Enviando para o Vault (M05):



```bash

vault kv put kv/appgear/connectivity/tailscale \\

&nbsp; client\_id="$TAILSCALE\_OAUTH\_CLIENT\_ID" \\

&nbsp; client\_secret="$TAILSCALE\_OAUTH\_CLIENT\_SECRET" \\

&nbsp; auth\_key="$TAILSCALE\_AUTH\_KEY"

```



> No cluster, \*\*sempre\*\* usar ExternalSecrets apontando para `kv/appgear/connectivity/tailscale`. Nenhum Secret estático com CLIENT\_ID / CLIENT\_SECRET deve ser criado manualmente.



---



\### 4.2 Estrutura GitOps – `webapp-ia-gitops-core`



No repositório GitOps:



```bash

cd webapp-ia-gitops-core



mkdir -p apps/core/connectivity/connectors

```



\#### 4.2.1 `apps/core/connectivity/kustomization.yaml`



Inclui todos os recursos do módulo, incluindo a nova \*\*ProxyClass\*\*:



```bash

cat > apps/core/connectivity/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: connectivity



resources:

&nbsp; - namespace.yaml

&nbsp; - tailscale-operator.yaml

&nbsp; - auth-secret-placeholder.yaml

&nbsp; - proxyclass-k8s-default.yaml

&nbsp; - connectors/legacy-subnet-connector.yaml

&nbsp; - connectors/k8s-api-proxy.yaml

EOF

```



---



\### 4.3 Namespace `connectivity`



`apps/core/connectivity/namespace.yaml`:



```bash

cat > apps/core/connectivity/namespace.yaml << 'EOF'

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: connectivity

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: connectivity

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/tenant-id: global

EOF

```



> A label `appgear.io/tenant-id: global` garante rastreio de custos de VPN associados à infraestrutura global.



---



\### 4.4 ExternalSecret – Segredos OAuth (Vault → K8s)



`apps/core/connectivity/auth-secret-placeholder.yaml`:



```bash

cat > apps/core/connectivity/auth-secret-placeholder.yaml << 'EOF'

apiVersion: external-secrets.io/v1beta1

kind: ExternalSecret

metadata:

&nbsp; name: tailscale-operator-oauth

&nbsp; namespace: connectivity

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: tailscale-operator-oauth

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; refreshInterval: 15m

&nbsp; secretStoreRef:

&nbsp;   name: vault-appgear-kv

&nbsp;   kind: ClusterSecretStore

&nbsp; target:

&nbsp;   name: tailscale-operator-oauth

&nbsp;   creationPolicy: Owner

&nbsp; data:

&nbsp;   - secretKey: CLIENT\_ID

&nbsp;     remoteRef:

&nbsp;       key: kv/appgear/connectivity/tailscale

&nbsp;       property: client\_id

&nbsp;   - secretKey: CLIENT\_SECRET

&nbsp;     remoteRef:

&nbsp;       key: kv/appgear/connectivity/tailscale

&nbsp;       property: client\_secret

EOF

```



> Com isso, qualquer rotação de `client\_id` / `client\_secret` no Vault é refletida automaticamente no Secret do cluster.



---



\### 4.5 Deployment do Tailscale Operator (com FinOps + Resources)



`apps/core/connectivity/tailscale-operator.yaml`:



```bash

cat > apps/core/connectivity/tailscale-operator.yaml << 'EOF'

apiVersion: v1

kind: ServiceAccount

metadata:

&nbsp; name: tailscale-operator

&nbsp; namespace: connectivity

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: tailscale-operator

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/tenant-id: global

---

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: tailscale-operator

&nbsp; namespace: connectivity

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: tailscale-operator

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: tailscale-operator

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: tailscale-operator

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;       appgear.io/tier: core

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     serviceAccountName: tailscale-operator

&nbsp;     containers:

&nbsp;       - name: operator

&nbsp;         image: tailscale/k8s-operator:stable

&nbsp;         imagePullPolicy: IfNotPresent

&nbsp;         env:

&nbsp;           - name: CLIENT\_ID

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: tailscale-operator-oauth

&nbsp;                 key: CLIENT\_ID

&nbsp;           - name: CLIENT\_SECRET

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: tailscale-operator-oauth

&nbsp;                 key: CLIENT\_SECRET

&nbsp;           # Habilita o Proxy do API Server em modo autenticado

&nbsp;           - name: APISERVER\_PROXY

&nbsp;             value: "auth"

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "100m"

&nbsp;             memory: "256Mi"

&nbsp;           limits:

&nbsp;             cpu: "500m"

&nbsp;             memory: "512Mi"

EOF

```



> Aqui resolvemos dois pontos:

>

> \* FinOps: `appgear.io/tenant-id: global` em ServiceAccount, Deployment e PodTemplate.

> \* Resources: requests/limits definidos para o próprio operador.



---



\### 4.6 ProxyClass – Limites para Pods de Proxy



Para aplicar limites a todos os \*\*pods de proxy\*\* criados dinamicamente pelo operador, definimos uma \*\*ProxyClass\*\*.



`apps/core/connectivity/proxyclass-k8s-default.yaml`:



```bash

cat > apps/core/connectivity/proxyclass-k8s-default.yaml << 'EOF'

apiVersion: tailscale.com/v1alpha1

kind: ProxyClass

metadata:

&nbsp; name: tailscale-proxy-default

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: tailscale-proxy-default

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; # Template base aplicado aos pods de proxy (ProxyGroup)

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;       appgear.io/tier: core

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: proxy

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "100m"

&nbsp;             memory: "128Mi"

&nbsp;           limits:

&nbsp;             cpu: "500m"

&nbsp;             memory: "512Mi"

EOF

```



> Essa classe é referenciada pelos ProxyGroups para garantir que \*\*todos os proxies\*\* tenham recursos mínimos e máximos definidos.



---



\### 4.7 Connector – Subnet Router para Rede Legada (com FinOps)



`apps/core/connectivity/connectors/legacy-subnet-connector.yaml`:



```bash

cat > apps/core/connectivity/connectors/legacy-subnet-connector.yaml << 'EOF'

apiVersion: tailscale.com/v1alpha1

kind: Connector

metadata:

&nbsp; name: legacy-subnet-connector

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: legacy-subnet-connector

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; hostname: ag-core-legacy-subnet

&nbsp; # Tag usada nas ACLs da Tailnet; tagOwners deve incluir o operador

&nbsp; tags:

&nbsp;   - "tag:appgear-cluster"

&nbsp; subnetRouter:

&nbsp;   # Rede do banco legado on-premise (ajustar para o CIDR real)

&nbsp;   advertiseRoutes:

&nbsp;     - "10.10.0.0/16"

EOF

```



> Importante: `Connector` é \*\*cluster-scoped\*\*, por isso não definimos `namespace`.



---



\### 4.8 ProxyGroup – API Server via VPN (com FinOps + ProxyClass)



`apps/core/connectivity/connectors/k8s-api-proxy.yaml`:



```bash

cat > apps/core/connectivity/connectors/k8s-api-proxy.yaml << 'EOF'

apiVersion: tailscale.com/v1alpha1

kind: ProxyGroup

metadata:

&nbsp; name: ag-core-apiserver

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: ag-core-apiserver

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; type: kube-apiserver

&nbsp; replicas: 2

&nbsp; tags:

&nbsp;   - "tag:k8s"

&nbsp; # Aplica a ProxyClass com limites de recursos

&nbsp; classRef:

&nbsp;   name: tailscale-proxy-default

&nbsp; kubeAPIServer:

&nbsp;   mode: auth

EOF

```



> Aqui corrigimos:

>

> \* FinOps: label `appgear.io/tenant-id: global` diretamente no ProxyGroup.

> \* Resources: vínculo explícito com `ProxyClass` que define recursos para os pods de proxy.



---



\### 4.9 Application Argo CD – `core-connectivity`



Em `clusters/ag-<regiao>-core-<env>/apps-core.yaml`:



```bash

cat >> clusters/ag-br-core-dev/apps-core.yaml << 'EOF'

---

apiVersion: argoproj.io/v1alpha1

kind: Application

metadata:

&nbsp; name: core-connectivity

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/module: "mod16-connectivity-hybrid"

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; project: default

&nbsp; source:

&nbsp;   repoURL: git@github.com:appgear/webapp-ia-gitops-core.git

&nbsp;   targetRevision: main

&nbsp;   path: apps/core/connectivity

&nbsp; destination:

&nbsp;   server: https://kubernetes.default.svc

&nbsp;   namespace: connectivity

&nbsp; syncPolicy:

&nbsp;   automated:

&nbsp;     selfHeal: true

&nbsp;     prune: true

&nbsp;   syncOptions:

&nbsp;     - CreateNamespace=true

EOF

```



Sincronizar:



```bash

argocd app sync core-connectivity

```



---



\### 4.10 Topologia A – Serviço `vpn-gateway` no `docker-compose.yml`



No host de demo:



```bash

cd /opt/webapp-ia



cat >> docker-compose.yml << 'EOF'



&nbsp; vpn-gateway:

&nbsp;   image: tailscale/tailscale:latest

&nbsp;   container\_name: vpn-gateway

&nbsp;   hostname: vpn-gateway

&nbsp;   restart: unless-stopped

&nbsp;   environment:

&nbsp;     - TS\_AUTHKEY=${TAILSCALE\_AUTH\_KEY}

&nbsp;     - TS\_ROUTES=172.20.0.0/16      # Rede docker/host a ser exposta ao tailnet

&nbsp;     - TS\_TAILNET=${TAILSCALE\_TAILNET}

&nbsp;   volumes:

&nbsp;     - /var/lib/tailscale:/var/lib/tailscale

&nbsp;     - /dev/net/tun:/dev/net/tun

&nbsp;   cap\_add:

&nbsp;     - NET\_ADMIN

&nbsp;     - NET\_RAW

&nbsp;   network\_mode: "host"

EOF

```



Subir:



```bash

docker compose up -d vpn-gateway

```



> Aqui continuamos usando uma \*\*auth key efêmera\*\* para demo/local, mas para produção o recomendado é também migrar este padrão para abordagem via OAuth + ACLs mais rígidas.



---



\## 5. Como verificar



\### 5.1 Operador e ExternalSecret



```bash

kubectl get ns connectivity



kubectl get deploy -n connectivity tailscale-operator

kubectl get pods -n connectivity -l app.kubernetes.io/name=tailscale-operator



kubectl get externalsecret -n connectivity

kubectl describe externalsecret -n connectivity tailscale-operator-oauth



kubectl get secret -n connectivity tailscale-operator-oauth -o yaml

```



\* Namespace `connectivity` presente.

\* Deployment `tailscale-operator` com pods `Running`.

\* ExternalSecret com `status` pronto e Secret com `CLIENT\_ID` / `CLIENT\_SECRET`.



\### 5.2 Connector e rotas



```bash

kubectl get connector

kubectl describe connector legacy-subnet-connector

```



\* `status.conditions` deve indicar `Ready = True`.



No painel Tailscale:



\* Ver rota `10.10.0.0/16` anunciada e aprovada.



Teste a partir de um pod:



```bash

kubectl run netshoot --rm -it \\

&nbsp; --image=nicolaka/netshoot \\

&nbsp; --command -- bash



\# dentro do pod:

ping -c3 10.10.0.20      # IP de teste da rede legado

nc -vz 10.10.0.20 5432   # porta do banco legado

```



\### 5.3 ProxyClass e ProxyGroup



```bash

kubectl get proxyclass

kubectl describe proxyclass tailscale-proxy-default



kubectl get proxygroup

kubectl describe proxygroup ag-core-apiserver

```



\* ProxyClass deve existir com resources em `spec.template.spec.containers\[proxy].resources`.

\* ProxyGroup deve indicar classe `tailscale-proxy-default` e URL do API Server via tailnet.



No notebook do dev:



```bash

tailscale status | grep ag-core-apiserver



\# contexto exemplo:

\# (o comando exato depende da integração; aqui é conceitual)

kubectl --context=https://ag-core-apiserver.tailnet-xyz.ts.net get nodes

```



\### 5.4 FinOps – Labels



Checar labels rapidamente:



```bash

kubectl get deploy -n connectivity tailscale-operator -o jsonpath='{.metadata.labels.appgear\\.io/tenant-id}'



kubectl get proxygroup ag-core-apiserver -o jsonpath='{.metadata.labels.appgear\\.io/tenant-id}'



kubectl get connector legacy-subnet-connector -o jsonpath='{.metadata.labels.appgear\\.io/tenant-id}'

```



\* Esperado: `global` em todos.



\### 5.5 Topologia A – vpn-gateway



```bash

docker ps | grep vpn-gateway

docker logs vpn-gateway --tail=50

```



No laptop (tailnet):



```bash

tailscale status | grep vpn-gateway

ping -c3 <ip-do-host>

```



\* Testar acesso a algum serviço exposto na Topologia A (`http://<ip-do-host>:8055` etc.).



---



\## 6. Erros comuns



1\. \*\*Ainda usar Secret estático em vez de ExternalSecret\*\*



&nbsp;  \* Sintoma: Secret `tailscale-operator-oauth` criado manualmente.

&nbsp;  \* Correção: remover Secret estático, manter somente `ExternalSecret` apontando para Vault.



2\. \*\*Ausência de `appgear.io/tenant-id: global`\*\*



&nbsp;  \* Sintoma: manifestos do operador e dos proxies sem a label.

&nbsp;  \* Correção: revisar `namespace.yaml`, `tailscale-operator.yaml`, `proxyclass-k8s-default.yaml`, `legacy-subnet-connector.yaml`, `k8s-api-proxy.yaml` e `apps-core.yaml`.



3\. \*\*CRDs do operador não aplicados\*\*



&nbsp;  \* Sintoma: erro “no matches for kind `ProxyClass` / `ProxyGroup` / `Connector`”.

&nbsp;  \* Correção: aplicar previamente os CRDs oficiais do Tailscale Operator na camada de infra.



4\. \*\*Resources ausentes em ProxyClass\*\*



&nbsp;  \* Sintoma: pods de proxy sem `resources` em `kubectl describe pod`.

&nbsp;  \* Correção: ajustar `proxyclass-k8s-default.yaml` e garantir que `classRef.name` em `ProxyGroup` está correto.



5\. \*\*Rotas do Connector não aprovadas\*\*



&nbsp;  \* Sintoma: `ping` não responde, `connector` aparentemente `Ready`.

&nbsp;  \* Correção: aprovar rota no painel Tailscale ou configurar auto-approvers.



6\. \*\*ACLs do API Server incompletas\*\*



&nbsp;  \* Sintoma: dev não consegue `kubectl` via ProxyGroup.

&nbsp;  \* Correção: revisar policy de tailnet para incluir `group:k8s-admins` / `group:k8s-readers` → `tag:k8s` na porta 443.



7\. \*\*Topologia A sem capacidades de rede corretas\*\*



&nbsp;  \* Sintoma: logs de erro sobre `/dev/net/tun` ou permissões.

&nbsp;  \* Correção: garantir `cap\_add` e volume `/dev/net/tun` conforme compose deste módulo.



---



\## 7. Onde salvar



\* \*\*Repositório GitOps Core (`webapp-ia-gitops-core`)\*\*



&nbsp; \* `apps/core/connectivity/`



&nbsp;   \* `kustomization.yaml`

&nbsp;   \* `namespace.yaml`

&nbsp;   \* `tailscale-operator.yaml`

&nbsp;   \* `auth-secret-placeholder.yaml`

&nbsp;   \* `proxyclass-k8s-default.yaml`

&nbsp;   \* `connectors/legacy-subnet-connector.yaml`

&nbsp;   \* `connectors/k8s-api-proxy.yaml`

&nbsp; \* `clusters/ag-<regiao>-core-<env>/apps-core.yaml`



&nbsp;   \* Application `core-connectivity` com label `appgear.io/tenant-id: global`.



\* \*\*Vault (M05)\*\*



&nbsp; \* Path: `kv/appgear/connectivity/tailscale`



&nbsp;   \* `client\_id`

&nbsp;   \* `client\_secret`

&nbsp;   \* `auth\_key` (quando necessário).



\* \*\*Host Topologia A (Docker)\*\*



&nbsp; \* `/opt/webapp-ia/.env` – variáveis Tailscale.

&nbsp; \* `/opt/webapp-ia/docker-compose.yml` – serviço `vpn-gateway`.



---



Com este conteúdo, o \*\*Módulo 16 – Conectividade Híbrida (VPN, Túneis e Acesso Remoto)\*\* passa a estar em \*\*conformidade\*\* com:



\* G15 / Forma Canônica (Markdown, não .py)

\* Segurança / Segredos OAuth (Vault + ExternalSecrets)

\* M00-3 / FinOps (`appgear.io/tenant-id: global`)

\* M00-3 / Resources (Operator + ProxyClass)



Ou seja: atende aos pontos do diagnóstico e pode ser considerado \*\*retrofit concluído (v0.1)\*\*.



