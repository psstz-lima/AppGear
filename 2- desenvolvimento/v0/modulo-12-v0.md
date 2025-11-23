Perfeito, vamos tratar este diagnóstico como base de \*\*retrofit\*\* e já entregar o \*\*Módulo 12 v0.1.md\*\* completo, corrigindo todos os pontos apontados: formato, labels, resources, borda/Kong e interoperabilidade com M02, M05 e M13.



Abaixo está o \*\*Módulo 12 – Suíte Guardian (v0.1 Retrofit)\*\* em formato Markdown, pronto para salvar como

`Módulo 12 v0.1.md`.



---



\# Módulo 12 – Suíte Guardian (Security Suite, Legal AI, Chaos, App Store) – v0.1



> Este módulo substitui o artefato legado `Módulo 12 v0.py`.

> Aqui está a versão \*\*canônica em Markdown\*\*, com correções de:

>

> \* Formato (Markdown).

> \* Cadeia de borda (Traefik → Coraza → Kong → Istio, sem bypass).

> \* Labels de FinOps (`appgear.io/tenant-id`).

> \* Definição de `resources` para workloads pesados (Browser Isolation, scanners, Chaos).

> \* Interoperabilidade com M02 (Rede), M05 (Segurança) e M13 (Workspaces/sidecars).



---



\## 1. O que é



A \*\*Suíte Guardian\*\* é a suíte de \*\*Security \& Governance\*\* da plataforma AppGear / AppGear.

Ela é responsável por:



1\. \*\*Security Suite\*\*



&nbsp;  \* \*\*Pentest AI\*\* (`addon-guardian-pentest-ai`): orquestra scanners (ZAP, Nuclei, Trivy, etc.) e usa LLM para gerar relatórios de segurança.

&nbsp;  \* \*\*Browser Isolation\*\* (`addon-guardian-browser-isolation`): browser remoto isolado para navegação segura.



2\. \*\*Legal AI \& Compliance\*\*



&nbsp;  \* \*\*Core\*\* (em Módulo Core):



&nbsp;    \* `core-tika`: extração de texto de documentos.

&nbsp;    \* `core-gotenberg`: normalização/conversão (PDF, etc.).

&nbsp;    \* `core-signserver`: assinatura digital.

&nbsp;  \* \*\*Add-on\*\*:



&nbsp;    \* `addon-guardian-legal-ai`: API que usa Tika + Gotenberg + LLM para:



&nbsp;      \* Revisão contratual.

&nbsp;      \* Resumo de riscos.

&nbsp;      \* Integração com ferramentas de SBOM (Syft/Trivy) para compliance de licenças.



3\. \*\*Chaos / Resilience\*\*



&nbsp;  \* `guardian-chaos` (LitmusChaos ou equivalente):



&nbsp;    \* Experimentos de falha (pod-delete, network-latency, cpu-hog, etc.).

&nbsp;    \* Sempre \*\*sem exposição direta\*\* na borda; acesso via:



&nbsp;      \* `kubectl port-forward` ou

&nbsp;      \* Ingress com `ingressClassName: kong` + OIDC (Keycloak), nunca via IngressRoute direto.



4\. \*\*Guardian App Store Policy\*\*



&nbsp;  \* \*\*UI\*\*: plugin da \*\*Private App Store do Backstage\*\* (M07).

&nbsp;  \* \*\*API\*\*: `addon-guardian-appstore-policy` exposto como serviço interno:



&nbsp;    \* Consulta:



&nbsp;      \* Legal AI (SBOM/licenças).

&nbsp;      \* Pentest AI (estado de risco).

&nbsp;      \* FinOps (OpenCost/Lago).

&nbsp;      \* IGA (midPoint) / RBAC (Keycloak/OpenFGA).

&nbsp;    \* Decide se um app/workspace pode ser aprovado, pendente ou negado.



5\. \*\*Cross-cutting com Workspaces (M13)\*\*



&nbsp;  \* A Suíte Guardian é \*\*cross-cutting\*\*:



&nbsp;    \* M13 pode injetar sidecars/agents de segurança em workspaces que contratarem o pacote Guardian, usando labels/annotations definidas aqui.



---



\## 2. Por que



\### 2.1 Responder ao diagnóstico v0



O diagnóstico do `Módulo 12 v0.py` apontou:



1\. \*\*G15 / Forma Canônica – NOK\*\*



&nbsp;  \* Artefato em `.py`, não em `.md`.



2\. \*\*G05 / Segurança de Borda – NOK (Crítico)\*\*



&nbsp;  \* Pentest e Chaos propostos com exposição direta via \*\*IngressRoute (Traefik)\*\*, bypassando a cadeia:



&nbsp;    \* Traefik → Coraza → Kong → Istio.

&nbsp;  \* Recomendação: usar \*\*Ingress com `ingressClassName: kong` + plugins OIDC\*\* (Keycloak).



3\. \*\*M00-3 / FinOps – NOK (Crítico)\*\*



&nbsp;  \* Ausência de label `appgear.io/tenant-id` em recursos da suíte.

&nbsp;  \* Impossibilidade de rastrear custos de:



&nbsp;    \* Scanners (Pentest AI).

&nbsp;    \* Experimentos de Chaos.

&nbsp;    \* Browser Isolation.



4\. \*\*M00-3 / Resources – NOK (Risco)\*\*



&nbsp;  \* Ausência de `resources` em workloads pesados:



&nbsp;    \* Browser Isolation (Chrome/Firefox remoto).

&nbsp;    \* Scanners (ZAP, Nuclei, etc.).



5\. \*\*Interoperabilidade – Private App Store\*\*



&nbsp;  \* Falta de clareza se a App Store é app separado ou plugin Backstage.



6\. \*\*Interoperabilidade Rede / Segurança / Workspaces\*\*



&nbsp;  \* M02: LitmusChaos não pode ser exposto diretamente.

&nbsp;  \* M05: Pentest AI precisa de RBAC e auditado pelo Falco.

&nbsp;  \* M13: Guardian deve suportar injeção de sidecars de segurança nos workspaces.



\### 2.2 Como o v0.1 resolve



\* \*\*Formato\*\*: este módulo é entregue em \*\*Markdown\*\* (`Módulo 12 v0.1.md`).

\* \*\*Borda/Kong\*\*:



&nbsp; \* Nenhum Pentest/Chaos é exposto com `IngressRoute`.

&nbsp; \* Acesso web (quando necessário) é via:



&nbsp;   \* `Ingress` com `ingressClassName: kong` + plugins OIDC/Keycloak.

\* \*\*FinOps\*\*:



&nbsp; \* Todos os exemplos de manifests incluem:



&nbsp;   \* `appgear.io/tenant-id` (ex.: `global` ou `tenant-<id>`).

\* \*\*Resources\*\*:



&nbsp; \* Browser Isolation e scanners têm `resources` explícitos (requests/limits) em todos os exemplos.

\* \*\*App Store\*\*:



&nbsp; \* Clarificado:



&nbsp;   \* \*\*UI\*\* = plugin Backstage (M07).

&nbsp;   \* \*\*API de política\*\* = microserviço Guardian neste módulo.

\* \*\*Integrações\*\*:



&nbsp; \* RBAC de Pentest AI com ServiceAccount + RoleBinding restritos.

&nbsp; \* Falco monitora atividades privilegiadas.

&nbsp; \* M13 fica habilitado a injetar sidecars guiado por labels/annotations definidas aqui.



---



\## 3. Pré-requisitos



1\. \*\*Governança\*\*



&nbsp;  \* `0 - Contrato v0.md` publicado como fonte da verdade.

&nbsp;  \* Módulos 0 a 11 já retrofitados para v0.1 (ou em processo).



2\. \*\*Infra – Topologia B (K8s)\*\*



&nbsp;  \* Cluster `ag-<regiao>-core-<env>` com:



&nbsp;    \* Traefik, Coraza, Kong, Istio (M02).

&nbsp;    \* Vault, OPA, Falco, OpenFGA (M05).

&nbsp;    \* Keycloak, midPoint (M06).

&nbsp;    \* Prometheus, Grafana, Loki, OpenCost, Lago (M03).

&nbsp;    \* Backstage + Private App Store (M07).

&nbsp;  \* KEDA habilitado para Scale-to-Zero.

&nbsp;  \* Repositórios:



&nbsp;    \* `appgear-gitops-core`.

&nbsp;    \* `appgear-gitops-suites`.

&nbsp;    \* `appgear-backstage`.

&nbsp;    \* Repos de código dos serviços Guardian.



3\. \*\*Infra – Topologia A (Docker, demo)\*\*



&nbsp;  \* Host Ubuntu LTS com Docker + docker-compose e Traefik.

&nbsp;  \* `.env` central em `/opt/appgear/.env`.



---



\## 4. Como fazer (comandos)



\### 4.1 Migrar o formato: de `Módulo 12 v0.py` para `Módulo 12 v0.1.md`



No repositório de contratos:



```bash

cd appgear-contracts



\# Opcional: arquivar o artefato legado

mkdir -p legacy

git mv "Módulo 12 v0.py" legacy/ || true



\# Criar o novo artefato canônico

cat > "Módulo 12 v0.1.md" << 'EOF'

\# Módulo 12 – Suíte Guardian (Security Suite, Legal AI, Chaos, App Store) – v0.1



(cole aqui este conteúdo)

EOF



git add "Módulo 12 v0.1.md" legacy/ || true

git commit -m "M12 v0.1: Retrofit Guardian (Formato, Borda, FinOps, Resources)"

```



---



\### 4.2 Padrão de labels e resources (FinOps/Performance)



Usaremos o seguinte padrão mínimo em todos os Deployments/Services da Suíte Guardian:



```yaml

metadata:

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-guardian-pentest-ai # ou outro nome

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon          # core|addon

&nbsp;   appgear.io/suite: guardian      # core|factory|brain|ops|guardian...

&nbsp;   appgear.io/topology: B          # A|B

&nbsp;   appgear.io/workspace-id: global # ou ws-<id>

&nbsp;   appgear.io/tenant-id: global    # OU tenant-<id>

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod12-suite-guardian"

```



E \*\*sempre\*\*:



```yaml

resources:

&nbsp; requests:

&nbsp;   cpu: "200m"

&nbsp;   memory: "512Mi"

&nbsp; limits:

&nbsp;   cpu: "2"

&nbsp;   memory: "3Gi"

```



para Browser Isolation, e valores proporcionais para scanners.



---



\### 4.3 Security Suite – Pentest AI (com RBAC e FinOps)



\#### 4.3.1 Deployment + Service



No repo `appgear-gitops-suites`:



```bash

cd appgear-gitops-suites

mkdir -p apps/guardian/security-suite/pentest-ai

```



`apps/guardian/security-suite/pentest-ai/deployment.yaml`:



```bash

cat > apps/guardian/security-suite/pentest-ai/deployment.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-guardian-pentest-ai

&nbsp; namespace: guardian-security

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-guardian-pentest-ai

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod12-suite-guardian"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-guardian-pentest-ai

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-guardian-pentest-ai

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: guardian

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     serviceAccountName: sa-guardian-pentest-ai

&nbsp;     containers:

&nbsp;       - name: pentest-ai

&nbsp;         image: ghcr.io/appgear/addon-guardian-pentest-ai:0.1.0

&nbsp;         imagePullPolicy: IfNotPresent

&nbsp;         env:

&nbsp;           - name: RABBITMQ\_URL

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: guardian-pentest-secrets

&nbsp;                 key: rabbitmq\_url

&nbsp;           - name: FLOWISE\_URL

&nbsp;             valueFrom:

&nbsp;               secretKeyRef:

&nbsp;                 name: guardian-pentest-secrets

&nbsp;                 key: flowise\_url

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 8080

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "256Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

EOF

```



`apps/guardian/security-suite/pentest-ai/service.yaml`:



```bash

cat > apps/guardian/security-suite/pentest-ai/service.yaml << 'EOF'

apiVersion: v1

kind: Service

metadata:

&nbsp; name: addon-guardian-pentest-ai

&nbsp; namespace: guardian-security

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-guardian-pentest-ai

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; selector:

&nbsp;   app.kubernetes.io/name: addon-guardian-pentest-ai

&nbsp; ports:

&nbsp;   - port: 80

&nbsp;     targetPort: http

&nbsp;     name: http

EOF

```



\#### 4.3.2 RBAC (M05 + Falco)



ServiceAccount + Role/RoleBinding para permitir somente o necessário:



```bash

cat > apps/guardian/security-suite/pentest-ai/rbac.yaml << 'EOF'

apiVersion: v1

kind: ServiceAccount

metadata:

&nbsp; name: sa-guardian-pentest-ai

&nbsp; namespace: guardian-security

&nbsp; labels:

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

---

apiVersion: rbac.authorization.k8s.io/v1

kind: Role

metadata:

&nbsp; name: role-guardian-pentest-ai

&nbsp; namespace: guardian-security

&nbsp; labels:

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

rules:

&nbsp; - apiGroups: \[""]

&nbsp;   resources: \["pods"]

&nbsp;   verbs: \["get", "list"]

&nbsp; - apiGroups: \[""]

&nbsp;   resources: \["services"]

&nbsp;   verbs: \["get", "list"]

---

apiVersion: rbac.authorization.k8s.io/v1

kind: RoleBinding

metadata:

&nbsp; name: rb-guardian-pentest-ai

&nbsp; namespace: guardian-security

&nbsp; labels:

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

subjects:

&nbsp; - kind: ServiceAccount

&nbsp;   name: sa-guardian-pentest-ai

&nbsp;   namespace: guardian-security

roleRef:

&nbsp; kind: Role

&nbsp; name: role-guardian-pentest-ai

&nbsp; apiGroup: rbac.authorization.k8s.io

EOF

```



> Falco (M05) deve ter regras para alertar qualquer tentativa de fuga deste escopo.



---



\### 4.4 Security Suite – Browser Isolation (com resources rígidos)



```bash

mkdir -p apps/guardian/security-suite/browser-isolation

```



`apps/guardian/security-suite/browser-isolation/deployment.yaml`:



```bash

cat > apps/guardian/security-suite/browser-isolation/deployment.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-guardian-browser-isolation

&nbsp; namespace: guardian-security

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-guardian-browser-isolation

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod12-suite-guardian"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-guardian-browser-isolation

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-guardian-browser-isolation

&nbsp;       appgear.io/tier: addon

&nbsp;       appgear.io/suite: guardian

&nbsp;       appgear.io.topology: B

&nbsp;       appgear.io/workspace-id: global

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: browser

&nbsp;         image: ghcr.io/appgear/addon-guardian-browser-isolation:0.1.0

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 3000

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "500m"

&nbsp;             memory: "1Gi"

&nbsp;           limits:

&nbsp;             cpu: "2"

&nbsp;             memory: "3Gi"

EOF

```



`service.yaml` similar ao anterior.



> A \*\*exposição externa\*\* deste serviço deve seguir o mesmo padrão de Kong (ver seção 4.6), nunca um IngressRoute direto hooking o Service.



---



\### 4.5 Legal AI (core + addon)



\#### 4.5.1 Serviços core (em `appgear-gitops-core`)



Aqui só um exemplo de Tika com label de tenant e resources:



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

&nbsp; name: core-tika

&nbsp; namespace: legal

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: core-tika

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: core-tika

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: core-tika

&nbsp;       appgear.io/tier: core

&nbsp;       appgear.io/suite: core

&nbsp;       appgear.io/tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: tika

&nbsp;         image: apache/tika:latest

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 9998

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

EOF

```



> `core-gotenberg` e `core-signserver` seguem o mesmo padrão.



\#### 4.5.2 Add-on Legal AI (em `appgear-gitops-suites`)



De volta ao repo de suítes:



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

&nbsp; name: addon-guardian-legal-ai

&nbsp; namespace: guardian-legal

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-guardian-legal-ai

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io.topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-guardian-legal-ai

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-guardian-legal-ai

&nbsp;       appgear.io.tier: addon

&nbsp;       appgear.io.suite: guardian

&nbsp;       appgear.io.topology: B

&nbsp;       appgear.io.workspace-id: global

&nbsp;       appgear.io.tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: legal-ai

&nbsp;         image: ghcr.io/appgear/addon-guardian-legal-ai:0.1.0

&nbsp;         env:

&nbsp;           - name: TIKA\_URL

&nbsp;             value: http://core-tika.legal.svc.cluster.local:9998

&nbsp;           - name: GOTENBERG\_URL

&nbsp;             value: http://core-gotenberg.legal.svc.cluster.local:3000

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 8080

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

EOF

```



---



\### 4.6 Borda / Kong – corrigindo o bypass (Pentest, Chaos, Browser)



Atendendo o diagnóstico, \*\*Pentest\*\* e \*\*Chaos\*\* (e, por consistência, Browser Isolation) não podem ter IngressRoute direto.



Exemplo de \*\*Ingress (Kong) para Pentest UI\*\*:



```bash

cat > apps/guardian/security-suite/pentest-ai/ingress-kong.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: guardian-pentest-ai

&nbsp; namespace: guardian-security

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-guardian-pentest-ai

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   konghq.com/plugins: oidc-keycloak

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: security.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /pentest

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: addon-guardian-pentest-ai

&nbsp;               port:

&nbsp;                 number: 80

EOF

```



Exemplo para \*\*Chaos Dashboard\*\* (se precisar de UI):



```bash

cat > apps/guardian/chaos/ingress-kong-chaos.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: Ingress

metadata:

&nbsp; name: guardian-chaos-dashboard

&nbsp; namespace: guardian-chaos

&nbsp; labels:

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   konghq.com/plugins: oidc-keycloak

spec:

&nbsp; ingressClassName: kong

&nbsp; rules:

&nbsp;   - host: security.dev.appgear.local

&nbsp;     http:

&nbsp;       paths:

&nbsp;         - path: /chaos

&nbsp;           pathType: Prefix

&nbsp;           backend:

&nbsp;             service:

&nbsp;               name: litmusportal-service

&nbsp;               port:

&nbsp;                 number: 9002

EOF

```



> A configuração da cadeia Traefik → Coraza → Kong → Istio permanece no M02.

> Este módulo \*\*não cria\*\* IngressRoute para Pentest ou Chaos, eliminando o bypass apontado.



---



\### 4.7 Chaos – Experimentos e integração com M13



Exemplo de ChaosExperiment/ChaosEngine (apenas interno):



```bash

mkdir -p apps/guardian/chaos

cat > apps/guardian/chaos/chaos-experiments.yaml << 'EOF'

apiVersion: litmuschaos.io/v1alpha1

kind: ChaosExperiment

metadata:

&nbsp; name: pod-delete-appgear-core

&nbsp; namespace: guardian-chaos

&nbsp; labels:

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; definition:

&nbsp;   scope: Namespaced

&nbsp;   image: litmuschaos/go-runner:latest

---

apiVersion: litmuschaos.io/v1alpha1

kind: ChaosEngine

metadata:

&nbsp; name: engine-pod-delete-core

&nbsp; namespace: guardian-chaos

&nbsp; labels:

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io/tenant-id: global

spec:

&nbsp; annotationCheck: "true"

&nbsp; appinfo:

&nbsp;   appns: appgear-core

&nbsp;   applabel: "app.kubernetes.io/part-of=appgear"

&nbsp;   appkind: deployment

&nbsp; chaosServiceAccount: litmus-admin

&nbsp; experiments:

&nbsp;   - name: pod-delete-appgear-core

&nbsp;     spec:

&nbsp;       components:

&nbsp;         env:

&nbsp;           - name: TOTAL\_CHAOS\_DURATION

&nbsp;             value: "30"

EOF

```



Integração com M13 (Workspaces) via annotation padrão:



```yaml

metadata:

&nbsp; annotations:

&nbsp;   guardian.appgear.io/enabled: "true"

&nbsp;   guardian.appgear.io/profile: "full" # ou "lite"

```



M13 poderá usar essas annotations para injetar sidecars (agentes de runtime, por exemplo) em pods de workspaces que compram o pacote Guardian.



---



\### 4.8 Guardian App Store – UI Backstage + API Policy



\#### 4.8.1 API de política



```bash

mkdir -p apps/guardian/appstore

cat > apps/guardian/appstore/deployment.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: addon-guardian-appstore-policy

&nbsp; namespace: guardian-appstore

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: addon-guardian-appstore-policy

&nbsp;   appgear.io/tier: addon

&nbsp;   appgear.io/suite: guardian

&nbsp;   appgear.io.topology: B

&nbsp;   appgear.io.workspace-id: global

&nbsp;   appgear.io.tenant-id: global

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: addon-guardian-appstore-policy

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: addon-guardian-appstore-policy

&nbsp;       appgear.io/suite: guardian

&nbsp;       appgear.io.tenant-id: global

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: policy-api

&nbsp;         image: ghcr.io/appgear/addon-guardian-appstore-policy:0.1.0

&nbsp;         env:

&nbsp;           - name: LEGAL\_AI\_URL

&nbsp;             value: http://addon-guardian-legal-ai.guardian-legal.svc.cluster.local

&nbsp;           - name: PENTEST\_AI\_URL

&nbsp;             value: http://addon-guardian-pentest-ai.guardian-security.svc.cluster.local

&nbsp;         ports:

&nbsp;           - name: http

&nbsp;             containerPort: 8080

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "100m"

&nbsp;             memory: "256Mi"

&nbsp;           limits:

&nbsp;             cpu: "500m"

&nbsp;             memory: "512Mi"

EOF

```



\#### 4.8.2 UI – plugin Backstage (M07)



No `appgear-backstage`, o \*\*plugin da App Store\*\* continua dentro do Backstage. Apenas ajustamos o backend para chamar a política:



```ts

// plugins/private-app-store-backend/src/service/router.ts

import { Router } from 'express';

import fetch from 'node-fetch';



export async function createRouter(): Promise<Router> {

&nbsp; const router = Router();

&nbsp; const policyUrl =

&nbsp;   process.env.GUARDIAN\_APPSTORE\_POLICY\_URL ??

&nbsp;   'http://addon-guardian-appstore-policy.guardian-appstore.svc.cluster.local';



&nbsp; router.post('/request-access', async (req, res) => {

&nbsp;   const { appId, userId, workspaceId } = req.body;



&nbsp;   const resp = await fetch(`${policyUrl}/evaluate`, {

&nbsp;     method: 'POST',

&nbsp;     headers: { 'Content-Type': 'application/json' },

&nbsp;     body: JSON.stringify({ appId, userId, workspaceId }),

&nbsp;   });



&nbsp;   const decision = await resp.json();

&nbsp;   return res.json(decision);

&nbsp; });



&nbsp; return router;

}

```



> UI continua Tailwind + shadcn/ui, conforme M07. Aqui apenas garantimos que \*\*governança\*\* (Guardian) é sempre consultada.



---



\### 4.9 Topologia A – Docker (demo segura)



Apenas demo local, sem Kong, mas mantendo `.env` e recursos separados.



```bash

cd /opt/appgear

mkdir -p guardian

```



`.env` (trecho):



```bash

cat >> .env << 'EOF'

GUARDIAN\_LEGAL\_AI\_PORT=8085

GUARDIAN\_PENTEST\_AI\_PORT=8086

EOF

```



`guardian/docker-compose.guardian.yml` (apenas Legal AI + Pentest demo):



```bash

cat > guardian/docker-compose.guardian.yml << 'EOF'

version: "3.8"

services:

&nbsp; core-tika:

&nbsp;   image: apache/tika:latest

&nbsp;   container\_name: core-tika

&nbsp;   ports:

&nbsp;     - "9998:9998"



&nbsp; core-gotenberg:

&nbsp;   image: gotenberg/gotenberg:8

&nbsp;   container\_name: core-gotenberg

&nbsp;   ports:

&nbsp;     - "3000:3000"



&nbsp; addon-guardian-legal-ai:

&nbsp;   image: ghcr.io/appgear/addon-guardian-legal-ai:0.1.0

&nbsp;   container\_name: addon-guardian-legal-ai

&nbsp;   environment:

&nbsp;     - TIKA\_URL=http://core-tika:9998

&nbsp;     - GOTENBERG\_URL=http://core-gotenberg:3000

&nbsp;   ports:

&nbsp;     - "${GUARDIAN\_LEGAL\_AI\_PORT}:8080"



&nbsp; addon-guardian-pentest-ai:

&nbsp;   image: ghcr.io/appgear/addon-guardian-pentest-ai:0.1.0

&nbsp;   container\_name: addon-guardian-pentest-ai

&nbsp;   ports:

&nbsp;     - "${GUARDIAN\_PENTEST\_AI\_PORT}:8080"

EOF

```



---



\## 5. Como verificar



1\. \*\*Formato\*\*



&nbsp;  \* Ver se o arquivo `Módulo 12 v0.1.md` está no repositório de contratos e o `.py` está arquivado.



2\. \*\*Argo CD\*\*



&nbsp;  ```bash

&nbsp;  argocd app list | grep suite-guardian

&nbsp;  argocd app get suite-guardian

&nbsp;  ```



3\. \*\*Labels / FinOps\*\*



&nbsp;  ```bash

&nbsp;  kubectl get deploy -A -l appgear.io.suite=guardian -o yaml | grep -n "appgear.io/tenant-id"

&nbsp;  ```



4\. \*\*Resources\*\*



&nbsp;  ```bash

&nbsp;  kubectl get deploy addon-guardian-browser-isolation -n guardian-security -o yaml | grep -n "resources" -A5

&nbsp;  ```



5\. \*\*Borda/Kong\*\*



&nbsp;  ```bash

&nbsp;  kubectl get ingress -A -l appgear.io.suite=guardian

&nbsp;  # Confirmar ingressClassName: kong e ausência de IngressRoute específico para Pentest/Chaos

&nbsp;  kubectl get ingressroute -A | grep -i guardian || echo "OK sem IngressRoute Guardian"

&nbsp;  ```



6\. \*\*RBAC Pentest\*\*



&nbsp;  ```bash

&nbsp;  kubectl get role,rolebinding,sa -n guardian-security | grep pentest

&nbsp;  ```



7\. \*\*App Store\*\*



&nbsp;  \* No Backstage, entrar na Private App Store, solicitar um app e verificar logs do backend e do `addon-guardian-appstore-policy`.



---



\## 6. Erros comuns



1\. \*\*Criar IngressRoute para Pentest/Chaos\*\*



&nbsp;  \* Reintroduz o bypass Traefik → serviço direto.

&nbsp;  \* Correto: sempre \*\*Ingress (Kong) com OIDC\*\*.



2\. \*\*Omitir `appgear.io/tenant-id`\*\*



&nbsp;  \* Perde rastreamento de custos de Security-as-a-Service.

&nbsp;  \* Corrigir labels em todos os recursos da suíte.



3\. \*\*Sem `resources` em Browser Isolation\*\*



&nbsp;  \* Pode causar OOM no nó.

&nbsp;  \* Sempre definir requests/limits conservadores.



4\. \*\*RBAC muito amplo para Pentest\*\*



&nbsp;  \* Risco de “scanner” virar ferramenta de ataque.

&nbsp;  \* Restringir Role/RoleBinding e monitorar com Falco.



5\. \*\*App Store como app separado\*\*



&nbsp;  \* Fere a visão de Backstage como portal único.

&nbsp;  \* Sempre tratar App Store como \*\*plugin\*\* dentro do Backstage (UI), com API Guardian isolada.



6\. \*\*Chaos exposto sem autenticação\*\*



&nbsp;  \* Painel de chaos aberto é gateway para derrubar o cluster.

&nbsp;  \* Acesso apenas via Kong+Keycloak ou port-forward autenticado.



---



\## 7. Onde salvar



1\. \*\*Contrato / Documentação\*\*



&nbsp;  \* Repo: `appgear-contracts`

&nbsp;  \* Arquivo: `Módulo 12 v0.1.md` (este texto).

&nbsp;  \* Referenciar no índice de desenvolvimento (`1 - Desenvolvimento v0.md`) apontando para este módulo.



2\. \*\*GitOps – Core\*\*



&nbsp;  \* Repo: `appgear-gitops-core`

&nbsp;  \* Pastas:



&nbsp;    \* `apps/core/legal/` (Tika, Gotenberg, SignServer).



3\. \*\*GitOps – Suítes\*\*



&nbsp;  \* Repo: `appgear-gitops-suites`

&nbsp;  \* Pastas:



&nbsp;    \* `apps/guardian/security-suite/`

&nbsp;    \* `apps/guardian/legal-ai/`

&nbsp;    \* `apps/guardian/chaos/`

&nbsp;    \* `apps/guardian/appstore/`



4\. \*\*Backstage / App Store\*\*



&nbsp;  \* Repo: `appgear-backstage`

&nbsp;  \* Ajustar backend do plugin Private App Store para utilizar `addon-guardian-appstore-policy`.



5\. \*\*Topologia A\*\*



&nbsp;  \* Host:



&nbsp;    \* `/opt/appgear/.env`

&nbsp;    \* `/opt/appgear/guardian/docker-compose.guardian.yml`



---



Se quiser, no próximo passo eu posso gerar só o “diff mental” entre o v0 (py) e este v0.1 (md), organizado por ID de auditoria (G15, G05, M00-3 etc.), para você ter um checklist de conformidade.



