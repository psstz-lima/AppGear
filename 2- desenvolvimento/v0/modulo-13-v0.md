Segue o \*\*Módulo 13 – Workspaces, vCluster e modelo por cliente (v0.1 retrofit)\*\* já corrigindo os problemas apontados no diagnóstico:



\* formato em Markdown,

\* uso de \*\*ApplicationSet\*\* (e não Applications manuais por cliente),

\* inclusão de \*\*resources\*\* no vCluster,

\* template de \*\*NetworkPolicy\*\* de isolamento entre workspaces,

\* manutenção dos labels de FinOps (`tenant-id`, `workspace-id`).



---



\## 1. O que é



O \*\*Módulo 13\*\* define como a plataforma AppGear trata:



1\. \*\*Workspace\*\*



&nbsp;  \* Unidade lógica de trabalho por cliente/produto.

&nbsp;  \* Identificada por `workspace\_id` (ex.: `acme-erp`).

&nbsp;  \* Associada a um `tenant\_id` (ex.: `acme`).



2\. \*\*vCluster por workspace\*\*



&nbsp;  \* Cada `workspace\_id` possui um \*\*vCluster dedicado\*\* (hard multi-tenancy lógico):



&nbsp;    \* Nome: `vcl-ws-<workspace\_id>` (ex.: `vcl-ws-acme-erp`).

&nbsp;    \* Rodando em um namespace do cluster físico: `vcluster-ws-<workspace\_id>`.



3\. \*\*Registro GitOps de Workspaces\*\*



&nbsp;  \* Repositório Git dedicado: `webapp-ia-gitops-workspaces`.

&nbsp;  \* Estrutura `workspaces/<workspace\_id>/` com arquivos declarativos do workspace (vCluster, quotas, NetworkPolicies, metadata).



4\. \*\*Orquestração via ApplicationSet (workspaces-appset)\*\*



&nbsp;  \* Um único \*\*ApplicationSet\*\* no `webapp-ia-gitops-core` lê o repositório `webapp-ia-gitops-workspaces` e cria automaticamente os \*\*Applications de cada workspace\*\*, sem edição manual do Core.

&nbsp;  \* Cada novo diretório em `workspaces/` → novo workspace provisionado.



5\. \*\*Isolamento, Quotas e FinOps\*\*



&nbsp;  \* Cada workspace:



&nbsp;    \* Tem \*\*Namespace\*\*, \*\*ResourceQuota\*\*, \*\*LimitRange\*\* e \*\*NetworkPolicy\*\* próprios.

&nbsp;    \* Todos os recursos do vCluster recebem labels:



&nbsp;      \* `appgear.io/tenant-id`

&nbsp;      \* `appgear.io/workspace-id`

&nbsp;      \* além de `tier`, `suite`, `topology`, `contract-version`, `module`.



---



\## 2. Por que



1\. \*\*Escalabilidade GitOps (correção do diagnóstico)\*\*



&nbsp;  \* v0 (NOK): para cada cliente era criado manualmente um arquivo `workspace-acme-erp-apps.yaml` dentro de `webapp-ia-gitops-core`.

&nbsp;  \* v0.1 (OK): um único `ApplicationSet` (`workspaces-appset`) gera \*\*automaticamente\*\* os Applications de workspaces a partir do repositório `webapp-ia-gitops-workspaces`.

&nbsp;  \* Resultado:



&nbsp;    \* Novo workspace = novo diretório em `webapp-ia-gitops-workspaces`, sem mexer no Core.



2\. \*\*Hard Multi-tenancy com vCluster\*\*



&nbsp;  \* Cada workspace tem um \*\*vCluster isolado\*\*, reduzindo risco de vazamento de configurações e RBAC entre clientes.

&nbsp;  \* Serviços pesados das Suítes (Factory, Brain, Operations, Guardian) podem ser multi-tenant lógico, mas sempre ancorados a `tenant\_id` e `workspace\_id`.



3\. \*\*FinOps e Observabilidade (M00/M03)\*\*



&nbsp;  \* Todos os componentes do vCluster e dos workspaces recebem labels padronizados.

&nbsp;  \* OpenCost, Lago, Backstage, Grafana e OpenMetadata conseguem:



&nbsp;    \* Agrupar custos por `tenant\_id`, `workspace\_id` e por Suíte.



4\. \*\*Segurança (NetworkPolicies e mTLS)\*\*



&nbsp;  \* vClusters compartilham a rede do host; sem NetworkPolicies, pods de workspaces diferentes podem se falar.

&nbsp;  \* O módulo define uma \*\*NetworkPolicy “deny-all entre workspaces”\*\* com exceções apenas para namespaces Core (Istio, Segurança, Observabilidade).



5\. \*\*Interoperabilidade com outros módulos\*\*



&nbsp;  \* \*\*M01 – Bootstrap GitOps:\*\*



&nbsp;    \* M13 consome o padrão de \*\*ApplicationSets\*\* e não cria Applications “manuais” por workspace.

&nbsp;  \* \*\*M06 – Identidade/SSO:\*\*



&nbsp;    \* Tokens OIDC trazem `workspace\_ids`; o backend de Workspaces usa isso para mapear vCluster/namespace.

&nbsp;  \* \*\*M07 – Backstage:\*\*



&nbsp;    \* O plugin de Workspaces comita em `webapp-ia-gitops-workspaces`, não em `webapp-ia-gitops-core`.

&nbsp;  \* \*\*M09/M10/M11/M12 – Suítes:\*\*



&nbsp;    \* Templates das Suítes são instanciados dentro dos vClusters por workspace, sempre com `tenant-id` e `workspace-id`.



---



\## 3. Pré-requisitos



\### 3.1 Documentais



\* `0 - Contrato v0.md` aceito como fonte de verdade.

\* `1 - Desenvolvimento v0.md` em uso (este módulo será incluído nele).

\* `2 - Auditoria v0.md` e `3 - Interoperabilidade v0.md` disponíveis para consulta.



\### 3.2 Módulos já definidos (Core)



\* M0 – Convenções, Repositórios e Nomenclatura.

\* M1 – Bootstrap GitOps e Argo CD (App-of-Apps).

\* M2 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong).

\* M3 – Observabilidade e FinOps.

\* M4 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, Redpanda).

\* M5 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA).

\* M6 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC).

\* M7–M12 – Suítes e Portal, ao menos em estado “implantável”.



\### 3.3 Infraestrutura (Topologia B – Kubernetes)



\* Cluster físico: `ag-<regiao>-core-<env>` com:



&nbsp; \* Argo CD operacional (M01).

&nbsp; \* Istio em modo mTLS STRICT (M02).

&nbsp; \* Storage Ceph pronto (M04).

&nbsp; \* Vault, OpenFGA, OPA, Falco (M05).

&nbsp; \* Observabilidade (Prometheus, Grafana, Loki, OpenCost, Lago) (M03).



\### 3.4 Repositórios Git



\* `appgear-contracts`

\* `webapp-ia-gitops-core`

\* `webapp-ia-gitops-suites`

\* `appgear-backstage`

\* `appgear-workspace-template` (template base por workspace)

\* \*\*Novo:\*\* `webapp-ia-gitops-workspaces` (registro GitOps de workspaces).



\### 3.5 Ferramentas



\* CLI: `git`, `kubectl`, `helm`, `kustomize`, `argocd`, `yq`.

\* Acesso de escrita aos repositórios acima.



---



\## 4. Como fazer (comandos)



\### 4.1 Criar o repositório de registro de workspaces



No host de desenvolvimento:



```bash

mkdir -p ~/git/webapp-ia-gitops-workspaces

cd ~/git/webapp-ia-gitops-workspaces



git init

git remote add origin git@github.com:appgear/webapp-ia-gitops-workspaces.git



cat > README.md << 'EOF'

\# webapp-ia-gitops-workspaces



Repositório GitOps de registro de Workspaces da AppGear.

Cada diretório em `workspaces/<workspace\_id>/` representa um workspace

e contém os manifests de vCluster, quotas, network policies e metadata.

EOF



mkdir -p workspaces

```



Commit inicial:



```bash

git add .

git commit -m "chore: init workspaces GitOps registry"

git push -u origin main

```



---



\### 4.2 Criar o primeiro workspace (exemplo: `acme-erp`)



\#### 4.2.1 Estrutura de diretórios



```bash

cd ~/git/webapp-ia-gitops-workspaces



mkdir -p workspaces/acme-erp

cd workspaces/acme-erp

```



Estrutura alvo:



```text

workspaces/acme-erp/

&nbsp; kustomization.yaml

&nbsp; namespace-host.yaml

&nbsp; workspace-configmap.yaml

&nbsp; resourcequota.yaml

&nbsp; limitrange.yaml

&nbsp; networkpolicy-deny-cross-workspaces.yaml

&nbsp; pvc-vcluster.yaml

&nbsp; deployment-vcluster.yaml

```



\#### 4.2.2 Kustomization do workspace



```bash

cat > kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



namespace: vcluster-ws-acme-erp



resources:

&nbsp; - namespace-host.yaml

&nbsp; - workspace-configmap.yaml

&nbsp; - resourcequota.yaml

&nbsp; - limitrange.yaml

&nbsp; - networkpolicy-deny-cross-workspaces.yaml

&nbsp; - pvc-vcluster.yaml

&nbsp; - deployment-vcluster.yaml

EOF

```



\#### 4.2.3 Namespace host para o vCluster



```bash

cat > namespace-host.yaml << 'EOF'

apiVersion: v1

kind: Namespace

metadata:

&nbsp; name: vcluster-ws-acme-erp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: vcl-ws-acme-erp

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: workspace

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: acme-erp

&nbsp;   appgear.io/tenant-id: acme

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

EOF

```



\#### 4.2.4 Metadata do workspace (ConfigMap)



```bash

cat > workspace-configmap.yaml << 'EOF'

apiVersion: v1

kind: ConfigMap

metadata:

&nbsp; name: ws-acme-erp-metadata

&nbsp; namespace: vcluster-ws-acme-erp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: ws-acme-erp-metadata

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: workspace

&nbsp;   appgear.io/suite: workspace

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: acme-erp

&nbsp;   appgear.io/tenant-id: acme

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

data:

&nbsp; tenant\_id: "acme"

&nbsp; workspace\_id: "acme-erp"

&nbsp; display\_name: "Workspace ACME ERP"

&nbsp; environment: "dev"

EOF

```



\#### 4.2.5 ResourceQuota e LimitRange do namespace host



```bash

cat > resourcequota.yaml << 'EOF'

apiVersion: v1

kind: ResourceQuota

metadata:

&nbsp; name: vcluster-ws-acme-erp-quota

&nbsp; namespace: vcluster-ws-acme-erp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: vcluster-ws-acme-erp

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: workspace

&nbsp;   appgear.io/suite: workspace

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: acme-erp

&nbsp;   appgear.io/tenant-id: acme

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

spec:

&nbsp; hard:

&nbsp;   requests.cpu: "500m"

&nbsp;   limits.cpu: "2"

&nbsp;   requests.memory: "1Gi"

&nbsp;   limits.memory: "4Gi"

&nbsp;   requests.storage: "20Gi"

&nbsp;   pods: "20"

EOF

```



```bash

cat > limitrange.yaml << 'EOF'

apiVersion: v1

kind: LimitRange

metadata:

&nbsp; name: vcluster-ws-acme-erp-limits

&nbsp; namespace: vcluster-ws-acme-erp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: vcluster-ws-acme-erp

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: workspace

&nbsp;   appgear.io/suite: workspace

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: acme-erp

&nbsp;   appgear.io/tenant-id: acme

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

spec:

&nbsp; limits:

&nbsp;   - type: Container

&nbsp;     default:

&nbsp;       cpu: "500m"

&nbsp;       memory: "512Mi"

&nbsp;     defaultRequest:

&nbsp;       cpu: "100m"

&nbsp;       memory: "256Mi"

EOF

```



\#### 4.2.6 PVC do vCluster (10Gi)



```bash

cat > pvc-vcluster.yaml << 'EOF'

apiVersion: v1

kind: PersistentVolumeClaim

metadata:

&nbsp; name: vcluster-ws-acme-erp-data

&nbsp; namespace: vcluster-ws-acme-erp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: vcl-ws-acme-erp

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: workspace

&nbsp;   appgear.io/suite: workspace

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: acme-erp

&nbsp;   appgear.io/tenant-id: acme

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

spec:

&nbsp; accessModes:

&nbsp;   - ReadWriteOnce

&nbsp; storageClassName: ceph-block

&nbsp; resources:

&nbsp;   requests:

&nbsp;     storage: 10Gi

EOF

```



\#### 4.2.7 Deployment do vCluster com resources explícitos



> Observação: este é um shape mínimo compatível com o diagnóstico – o cluster real pode usar o chart oficial do vCluster, mas aqui garantimos que os pods do plano de controle tenham `requests/limits` definidos.



```bash

cat > deployment-vcluster.yaml << 'EOF'

apiVersion: apps/v1

kind: Deployment

metadata:

&nbsp; name: vcl-ws-acme-erp

&nbsp; namespace: vcluster-ws-acme-erp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: vcl-ws-acme-erp

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: workspace

&nbsp;   appgear.io/suite: workspace

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: acme-erp

&nbsp;   appgear.io/tenant-id: acme

&nbsp; annotations:

&nbsp;   sidecar.istio.io/inject: "true"

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

spec:

&nbsp; replicas: 1

&nbsp; selector:

&nbsp;   matchLabels:

&nbsp;     app.kubernetes.io/name: vcl-ws-acme-erp

&nbsp; template:

&nbsp;   metadata:

&nbsp;     labels:

&nbsp;       app.kubernetes.io/name: vcl-ws-acme-erp

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: workspace

&nbsp;       appgear.io/suite: workspace

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: acme-erp

&nbsp;       appgear.io/tenant-id: acme

&nbsp;     annotations:

&nbsp;       sidecar.istio.io/inject: "true"

&nbsp;   spec:

&nbsp;     containers:

&nbsp;       - name: vcluster-server

&nbsp;         image: loftsh/vcluster:latest

&nbsp;         args:

&nbsp;           - "--name=vcl-ws-acme-erp"

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "200m"

&nbsp;             memory: "512Mi"

&nbsp;           limits:

&nbsp;             cpu: "1"

&nbsp;             memory: "1Gi"

&nbsp;         volumeMounts:

&nbsp;           - name: data

&nbsp;             mountPath: /data

&nbsp;       - name: vcluster-syncer

&nbsp;         image: loftsh/vcluster-syncer:latest

&nbsp;         resources:

&nbsp;           requests:

&nbsp;             cpu: "100m"

&nbsp;             memory: "256Mi"

&nbsp;           limits:

&nbsp;             cpu: "500m"

&nbsp;             memory: "512Mi"

&nbsp;     volumes:

&nbsp;       - name: data

&nbsp;         persistentVolumeClaim:

&nbsp;           claimName: vcluster-ws-acme-erp-data

EOF

```



> Se optar por usar o \*\*Helm Chart oficial do vCluster\*\*, estes mesmos resources devem ser refletidos em `values-vcluster.yaml` (campos `server.resources` e `syncer.resources`) e o Deployment acima pode ser substituído pelo chart renderizado via Argo CD.



\#### 4.2.8 NetworkPolicy – “Deny All Ingress from other Workspaces”



```bash

cat > networkpolicy-deny-cross-workspaces.yaml << 'EOF'

apiVersion: networking.k8s.io/v1

kind: NetworkPolicy

metadata:

&nbsp; name: ws-acme-erp-deny-cross-workspaces

&nbsp; namespace: vcluster-ws-acme-erp

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: vcl-ws-acme-erp

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: workspace

&nbsp;   appgear.io/suite: workspace

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: acme-erp

&nbsp;   appgear.io/tenant-id: acme

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

spec:

&nbsp; podSelector: {}

&nbsp; policyTypes:

&nbsp;   - Ingress

&nbsp;   - Egress

&nbsp; ingress:

&nbsp;   - from:

&nbsp;       # Permite tráfego dentro do próprio namespace

&nbsp;       - podSelector: {}

&nbsp;       # Permite tráfego de namespaces Core (istio, segurança, observabilidade)

&nbsp;       - namespaceSelector:

&nbsp;           matchExpressions:

&nbsp;             - key: appgear.io/tier

&nbsp;               operator: In

&nbsp;               values: \["core"]

&nbsp; egress:

&nbsp;   - {}

EOF

```



> Para outros workspaces, basta substituir `acme-erp` e `acme` por `<workspace\_id>` e `<tenant\_id>`.



\#### 4.2.9 Commit do workspace ACME ERP



```bash

cd ~/git/webapp-ia-gitops-workspaces

git add workspaces/acme-erp

git commit -m "feat(workspaces): add vcluster and policies for workspace acme-erp"

git push

```



---



\### 4.3 Criar AppProject `appgear-workspaces` no Core (Argo CD)



No repositório `webapp-ia-gitops-core`:



```bash

cd ~/git/webapp-ia-gitops-core



mkdir -p apps/core/workspaces

```



```bash

cat > apps/core/workspaces/argocd-project-workspaces.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: AppProject

metadata:

&nbsp; name: appgear-workspaces

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: appgear-workspaces

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

spec:

&nbsp; description: "Projeto Argo CD para gerenciamento GitOps de workspaces/vClusters"

&nbsp; sourceRepos:

&nbsp;   - git@github.com:appgear/webapp-ia-gitops-workspaces.git

&nbsp; destinations:

&nbsp;   - server: https://kubernetes.default.svc

&nbsp;     namespace: "\*"

&nbsp; clusterResourceWhitelist:

&nbsp;   - group: "\*"

&nbsp;     kind: "\*"

&nbsp; namespaceResourceWhitelist:

&nbsp;   - group: "\*"

&nbsp;     kind: "\*"

EOF

```



Commit:



```bash

git add apps/core/workspaces/argocd-project-workspaces.yaml

git commit -m "feat(core): add appgear-workspaces AppProject"

git push

```



Aplicar no cluster (bootstrap via kubectl; depois Argo assume):



```bash

kubectl apply -f apps/core/workspaces/argocd-project-workspaces.yaml -n argocd

```



---



\### 4.4 Criar ApplicationSet `workspaces-appset`



Ainda em `webapp-ia-gitops-core`:



```bash

cat > apps/core/workspaces/workspaces-appset.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: ApplicationSet

metadata:

&nbsp; name: workspaces-appset

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: workspaces-appset

&nbsp;   app.kubernetes.io/part-of: appgear

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0"

&nbsp;   appgear.io/module: "mod13-workspaces-vcluster"

spec:

&nbsp; generators:

&nbsp;   - git:

&nbsp;       repoURL: git@github.com:appgear/webapp-ia-gitops-workspaces.git

&nbsp;       revision: main

&nbsp;       directories:

&nbsp;         - path: workspaces/\*

&nbsp; template:

&nbsp;   metadata:

&nbsp;     name: ws-{{path.basename}}

&nbsp;     labels:

&nbsp;       app.kubernetes.io/part-of: appgear

&nbsp;       appgear.io/tier: workspace

&nbsp;       appgear.io/suite: workspace

&nbsp;       appgear.io/topology: B

&nbsp;       appgear.io/workspace-id: "{{path.basename}}"

&nbsp;       appgear.io/tenant-id: "unknown" # definido dentro do workspace-configmap

&nbsp;       appgear.io/contract-version: "v0"

&nbsp;       appgear.io/module: "mod13-workspaces-vcluster"

&nbsp;   spec:

&nbsp;     project: appgear-workspaces

&nbsp;     source:

&nbsp;       repoURL: git@github.com:appgear/webapp-ia-gitops-workspaces.git

&nbsp;       targetRevision: main

&nbsp;       path: "{{path}}"

&nbsp;     destination:

&nbsp;       server: https://kubernetes.default.svc

&nbsp;       namespace: vcluster-ws-{{path.basename}}

&nbsp;     syncPolicy:

&nbsp;       automated:

&nbsp;         prune: true

&nbsp;         selfHeal: true

&nbsp;       syncOptions:

&nbsp;         - CreateNamespace=true

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



A partir deste ponto, \*\*qualquer novo diretório\*\* em `webapp-ia-gitops-workspaces/workspaces/<workspace\_id>` será descoberto automaticamente e terá um `Application ws-<workspace\_id>` criado pelo Argo CD.



---



\### 4.5 Fluxo para criar um novo workspace (geral)



1\. No repositório `webapp-ia-gitops-workspaces`:



&nbsp;  \* Copiar o template de `workspaces/acme-erp` para `workspaces/<novo-workspace\_id>`.

&nbsp;  \* Ajustar:



&nbsp;    \* `workspace-id` e `tenant-id` nos labels.

&nbsp;    \* Nomes (`vcluster-ws-<workspace\_id>`, `vcl-ws-<workspace\_id>`).

&nbsp;    \* Quotas/localidade se necessário.



2\. `git add`, `git commit`, `git push`.



3\. O `workspaces-appset` detecta o diretório novo e cria automaticamente:



&nbsp;  \* `Application ws-<workspace\_id>` no Argo CD.

&nbsp;  \* O Argo aplica os manifests do workspace (Namespace, vCluster, quotas, NetworkPolicies).



4\. O Portal Backstage (M07) deve expor um fluxo que:



&nbsp;  \* Recebe `tenant\_id`, `workspace\_id`, `display\_name`.

&nbsp;  \* Scaffolder copia o template do `appgear-workspace-template` para `webapp-ia-gitops-workspaces/workspaces/<workspace\_id>`.

&nbsp;  \* Faz commit \& push (automatizando o passo 1).



---



\## 5. Como verificar



\### 5.1 Verificar o ApplicationSet



```bash

kubectl get applicationsets.argoproj.io -n argocd | grep workspaces-appset

```



Esperado:



\* `workspaces-appset` presente e `kubectl describe` sem erros de sincronização com o repositório.



```bash

kubectl describe applicationset workspaces-appset -n argocd | grep -i error -A3 -B3 || echo "Sem erros aparentes"

```



\### 5.2 Verificar Applications gerados por workspace



```bash

argocd app list | grep ws-

```



Esperado (para o exemplo `acme-erp`):



\* Um app `ws-acme-erp` com status `Synced` e `Healthy`.



Detalhe:



```bash

argocd app get ws-acme-erp

```



\### 5.3 Verificar recursos no cluster físico



Namespaces:



```bash

kubectl get ns | grep vcluster-ws-

```



PVC, Deployment e NetworkPolicy:



```bash

kubectl get pvc,deploy,networkpolicy -n vcluster-ws-acme-erp

```



Esperado:



\* `pvc/vcluster-ws-acme-erp-data`

\* `deployment.apps/vcl-ws-acme-erp`

\* `networkpolicy.networking.k8s.io/ws-acme-erp-deny-cross-workspaces`



\### 5.4 Verificar labels para FinOps



```bash

kubectl get deploy vcl-ws-acme-erp -n vcluster-ws-acme-erp -o jsonpath='{.metadata.labels}' | jq .

```



Esperado:



\* Campos `appgear.io/tenant-id: acme` e `appgear.io/workspace-id: acme-erp`.



\### 5.5 Verificar NetworkPolicy de isolamento



Testar de outro namespace de workspace (ex.: `vcluster-ws-outro-ws`):



```bash

kubectl run test-client \\

&nbsp; --rm -it \\

&nbsp; --restart=Never \\

&nbsp; --image=alpine \\

&nbsp; -n vcluster-ws-outro-ws \\

&nbsp; -- /bin/sh -c "apk add --no-cache curl \&\& curl -m 5 http://vcl-ws-acme-erp.vcluster-ws-acme-erp.svc.cluster.local:443 || echo 'bloqueado'"

```



Esperado:



\* Timeout ou erro de conexão (tráfego bloqueado pela NetworkPolicy), exceto se o namespace tiver labels de Core.



\### 5.6 Verificar uso do vCluster (opcional, se CLI instalada)



```bash

vcluster connect vcl-ws-acme-erp -n vcluster-ws-acme-erp -- kubectl get ns

```



Esperado dentro do vCluster:



\* Namespaces internos do workspace (ex.: `ws-acme-erp-core`, `ws-acme-erp-factory`, etc.), conforme contrato e módulos de Suítes.



---



\## 6. Erros comuns



1\. \*\*Esquecer de criar o diretório do workspace no GitOps\*\*



&nbsp;  \* Sintoma: Backstage mostra workspace, mas Argo CD não cria app `ws-<workspace\_id>`.

&nbsp;  \* Correção: garantir que o Scaffolder ou o fluxo manual criem `workspaces/<workspace\_id>/` com `kustomization.yaml` válido.



2\. \*\*Falha no ApplicationSet (erro de acesso ao repositório)\*\*



&nbsp;  \* Sintoma: `ApplicationSet` reporta erro “unable to fetch git repo”.

&nbsp;  \* Causas:



&nbsp;    \* `repoURL` do ApplicationSet incorreto.

&nbsp;    \* SSH key não configurada no Argo CD.

&nbsp;  \* Correção:



&nbsp;    \* Ajustar `repoURL` e secret de credenciais no Argo.



3\. \*\*Ausência de `appgear.io/tenant-id` ou `workspace-id` em manifests\*\*



&nbsp;  \* Sintoma: relatórios de OpenCost/Lago não mostram custos por workspace.

&nbsp;  \* Correção: revisar `namespace-host.yaml`, `deployment-vcluster.yaml`, `resourcequota.yaml`, `networkpolicy\*.yaml` e garantir labels obrigatórios.



4\. \*\*vCluster sem resources definidos (mesmo erro do diagnóstico v0)\*\*



&nbsp;  \* Sintoma: em ambiente com muitos workspaces, o cluster físico sofre por overcommit de CPU/memória do vCluster.

&nbsp;  \* Correção:



&nbsp;    \* Ajustar blocos `resources.requests` e `resources.limits` em `deployment-vcluster.yaml` (ou no `values-vcluster.yaml` do chart).



5\. \*\*NetworkPolicy muito permissiva ou ausente\*\*



&nbsp;  \* Sintoma: um pod de outro workspace consegue acessar serviços de `vcluster-ws-<workspace\_id>`.

&nbsp;  \* Correção:



&nbsp;    \* Validar `networkpolicy-deny-cross-workspaces.yaml` para cada workspace.

&nbsp;    \* Garantir que apenas namespaces Core (`appgear.io/tier=core`) possam se comunicar entre workspaces.



6\. \*\*Destinação errada no ApplicationSet\*\*



&nbsp;  \* Sintoma: Argo CD cria recursos do workspace no namespace `default` ou `appgear-core`.

&nbsp;  \* Correção:



&nbsp;    \* Checar campo `destination.namespace` no `workspaces-appset.yaml` (deve usar `vcluster-ws-{{path.basename}}`).



7\. \*\*Misturar manifests de workspace no `webapp-ia-gitops-core`\*\*



&nbsp;  \* Sintoma: diretórios `apps/workspaces` dentro de `webapp-ia-gitops-core` começam a conter configurações específicas de cliente.

&nbsp;  \* Correção:



&nbsp;    \* M13 v0.1 define que \*\*todo\*\* conteúdo de workspace mora em `webapp-ia-gitops-workspaces`; o Core apenas referencia via ApplicationSet.



---



\## 7. Onde salvar



1\. \*\*Documento de desenvolvimento (contratos)\*\*



&nbsp;  \* Incluir todo este texto em:



&nbsp;    \* `appgear-contracts/1 - Desenvolvimento v0.md`

&nbsp;    \* Seção: \*\*“Módulo 13 – Workspaces, vCluster e modelo por cliente (v0.1)”\*\*.



2\. \*\*Repositórios GitOps\*\*



&nbsp;  \* `webapp-ia-gitops-core`



&nbsp;    \* `apps/core/workspaces/argocd-project-workspaces.yaml`

&nbsp;    \* `apps/core/workspaces/workspaces-appset.yaml`

&nbsp;    \* Opcionalmente referenciados em algum `apps/core/kustomization.yaml` ou `clusters/ag-<regiao>-core-<env>/apps-core.yaml`, conforme padrão do Módulo 01.



&nbsp;  \* `webapp-ia-gitops-workspaces`



&nbsp;    \* `README.md`

&nbsp;    \* `workspaces/acme-erp/\*` (e demais workspaces) conforme descrito.



3\. \*\*Integrações futuras\*\*



&nbsp;  \* M07 (Backstage):



&nbsp;    \* O Scaffolder deve usar `appgear-workspace-template` para gerar o conteúdo de `workspaces/<workspace\_id>/`.

&nbsp;  \* M14 (Pipelines AI-First):



&nbsp;    \* Pipelines de provisionamento de clientes devem operar exclusivamente via edit/commit no `webapp-ia-gitops-workspaces`, nunca aplicando manifests diretamente via `kubectl`.



Com isso, o \*\*Módulo 13 v0.1\*\* fica alinhado ao contrato, ao Módulo 01 (uso de ApplicationSet), corrige o problema de resources dos vClusters e adiciona o template de NetworkPolicy de isolamento entre workspaces.



