Vou assumir que este diagnóstico é o gatilho para o \*\*retrofit\*\* do módulo, como fizemos com os demais. Abaixo está o \*\*Módulo 14 v0.1 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD)\*\* já corrigido, em \*\*Markdown\*\*, alinhado ao M00 v0.1 e ao M13 (ApplicationSets).



Você pode salvar este conteúdo como:



`Módulo 14 v0.1.md`

(no repositório de contratos / desenvolvimento).



---



\# Módulo 14 v0.1 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD)



> Retrofit do Módulo 14 v0 (antes em `.py`).

> Correções principais:

>

> \* Conversão total para \*\*Markdown\*\* (G15 / Forma Canônica).

> \* Alinhamento com \*\*ApplicationSets\*\* do M13 (G04 / Escalabilidade).

> \* Inclusão de \*\*labels FinOps (tenant-id)\*\* em pods efêmeros de pipeline (M00-3 / FinOps).

> \* Definição de \*\*resources\*\* para steps de Workflow (M00-3 / Resources).

> \* Explicitação da integração \*\*N8n ↔ Vault (M05)\*\* para credencial Git (Segurança).



---



\## 1. O que é



Este módulo define tecnicamente os \*\*Pipelines de Geração AI-First\*\* da plataforma, responsável por transformar decisões de negócio (desenhadas com IA e N8n) em \*\*deploy GitOps Nível 3\*\* sobre vClusters por workspace.



Fluxo canônico:



\*\*N8n (AI-First Generator) → Git (webapp-ia-gitops-workspaces) → Argo Events → Argo Workflows → Argo CD → vCluster (M13)\*\*



Pontos-chave:



\* O \*\*N8n não aplica nada no cluster\*\* e \*\*não toca o repositório core\*\* (`webapp-ia-gitops-core`).



&nbsp; \* Ele \*\*apenas escreve/commita\*\* na árvore do repositório `webapp-ia-gitops-workspaces` (uma pasta `ws-<workspace\_id>`).

\* O \*\*M13\*\* (Workspaces/vCluster) define um \*\*ApplicationSet\*\* que lê dinamicamente as pastas de workspaces no repo `webapp-ia-gitops-workspaces`.



&nbsp; \* O M14 garante que a estrutura gerada pelo N8n seja \*\*compatível\*\* com esse ApplicationSet.

\* Os pipelines de Argo Workflows:



&nbsp; \* Validam políticas via \*\*OPA\*\* (M05);

&nbsp; \* Podem acionar testes E2E;

&nbsp; \* Integram com Chaos/Security (Guardian – M12);

&nbsp; \* São \*\*rotulados com appgear.io/tenant-id\*\* e demais metadados para FinOps.



---



\## 2. Por que



1\. \*\*GitOps Nível 3 do Contrato\*\*



\* O contrato define que o \*\*AI-First Generator\*\* deve:



&nbsp; \* gerar manifests e artefatos em \*\*Git\*\*;

&nbsp; \* delegar toda aplicação ao fluxo Argo (Events → Workflows → CD);

&nbsp; \* não usar `kubectl apply` direto nem manipular clusters fora do GitOps.



2\. \*\*Escalabilidade via ApplicationSets (M13)\*\*



\* O M13 adotou \*\*ApplicationSets\*\* para descobrir workspaces por \*\*pasta\*\* no repositório de workspaces.

\* O M14 deve:



&nbsp; \* \*\*não gerar\*\* `apps-workspaces.yaml` no repo core (isso é obsoleto);

&nbsp; \* garantir apenas que o \*\*layout de pastas\*\* `workspaces/ws-<workspace\_id>/...` seja consistente com o ApplicationSet.



3\. \*\*FinOps e Governança de CI/CD\*\*



\* Pipelines de CI/CD consomem CPU/RAM significativos.

\* Sem labels `appgear.io/tenant-id` e `appgear.io/workspace-id`, o custo dos pipelines fica invisível.

\* Este módulo:



&nbsp; \* garante que \*\*pods de Argo Workflows\*\* sejam rotulados com o tenant e workspace corretos;

&nbsp; \* define \*\*requests/limits\*\* padrão para steps, evitando saturar o cluster.



4\. \*\*Segurança e Segredos (M05)\*\*



\* O N8n precisa de credenciais para:



&nbsp; \* acessar o Git (`ssh\_private\_key`);

&nbsp; \* eventualmente acessar outros serviços.

\* Essas credenciais:



&nbsp; \* são mantidas no \*\*Vault\*\* (SSoT de segredos);

&nbsp; \* são obtidas dinamicamente pelo N8n (não chaves estáticas no deployment).



5\. \*\*Interoperabilidade entre Módulos\*\*



\* \*\*Consome M08\*\*: N8n roda como serviço core; este módulo define \*\*os fluxos (JSON)\*\* que rodam nesse motor.

\* \*\*Consome M05\*\*: usa OPA (políticas) e Vault (segredos).

\* \*\*Consome M13\*\*: gera a estrutura de workspace que o ApplicationSet lê.

\* \*\*Consome M12\*\*: permite acionar Chaos/Security como parte do pipeline.



---



\## 3. Pré-requisitos



\### 3.1 Conceituais



\* \*\*Contrato v0\*\* aceito (AI-First Ecosystem Generator, GitOps Nível 3, Suítes, vCluster).

\* Módulos prévios definidos:



&nbsp; \* M00 v0.1 – Convenções, labels, FinOps, formatos (Markdown).

&nbsp; \* M01 – Bootstrap GitOps/Argo CD (App-of-Apps).

&nbsp; \* M02 – Borda e Malha (Traefik, Coraza, Kong, Istio).

&nbsp; \* M03 – Observabilidade/FinOps.

&nbsp; \* M04 – Armazenamento e Bancos.

&nbsp; \* M05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA).

&nbsp; \* M06 – Identidade e SSO.

&nbsp; \* M07 – Portal/Backstage.

&nbsp; \* M08 – Serviços Core (inclui N8n).

&nbsp; \* M09–M12 – Suítes (Factory, Brain, Operations, Guardian).

&nbsp; \* M13 – Workspaces, vCluster, ApplicationSet.



\### 3.2 Infraestrutura (Topologia B – K8s)



\* Cluster padrão `ag-<regiao>-core-<env>` com:



&nbsp; \* \*\*Argo CD\*\* (namespace `argocd`).

&nbsp; \* \*\*Argo Workflows\*\* e \*\*Argo Events\*\* instalados (podem ser instalados via GitOps neste módulo).

&nbsp; \* \*\*N8n\*\* em funcionamento (M08).

&nbsp; \* \*\*Vault\*\* e \*\*OPA\*\* (M05) configurados.

&nbsp; \* \*\*ApplicationSet de Workspaces\*\* (M13) já definido no repo core



&nbsp;   \* Assumimos que o ApplicationSet observa \*\*subpastas de `workspaces/`\*\* no repo `webapp-ia-gitops-workspaces`.

&nbsp;   \* Assumimos convenção: `workspaces/ws-<workspace\_id>/k8s/vcluster/...`.

&nbsp;     (Se M13 usar outro layout, este módulo deve ser ajustado para refletir a convenção exata.)



\### 3.3 Repositórios Git



\* `webapp-ia-gitops-core` (Infra Core + App-of-Apps).

\* `webapp-ia-gitops-suites` (Suítes Factory/Brain/Operations/Guardian).

\* `webapp-ia-gitops-workspaces` (Workspaces/vCluster por cliente/workspace).



> Regra de ouro deste módulo:

> \*\*N8n só escreve no `webapp-ia-gitops-workspaces`.\*\*

> `webapp-ia-gitops-core` e `webapp-ia-gitops-suites` são editados apenas por equipe de plataforma / automação infra, nunca pelo N8n.



\### 3.4 Ferramentas



\* CLI: `git`, `kubectl`, `kustomize`, `argocd`.

\* Acesso ao provedor Git com chaves de deploy configuradas no Vault.



---



\## 4. Como fazer (comandos)



\### 4.1 Estrutura do repositório `webapp-ia-gitops-workspaces`



> Se já existir, apenas valide a estrutura. Caso contrário, inicialize conforme abaixo.



```bash

mkdir -p ~/workspace/webapp-ia-gitops-workspaces

cd ~/workspace/webapp-ia-gitops-workspaces

git init

```



Crie diretórios base:



```bash

mkdir -p workspaces/.templates

mkdir -p clusters/ag-br-core-dev

```



`clusters/ag-br-core-dev/kustomization.yaml`:



```bash

cat > clusters/ag-br-core-dev/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - ../../workspaces

EOF

```



Template de estrutura de workspace (para referência, usado pelo fluxo N8n):



```bash

cat > workspaces/.templates/workspace-structure.yaml << 'EOF'

structure:

&nbsp; workspace:

&nbsp;   id: "ws-<workspace\_id>"

&nbsp; paths:

&nbsp;   k8s\_vcluster: "workspaces/ws-<workspace\_id>/k8s/vcluster"

&nbsp;   sql: "workspaces/ws-<workspace\_id>/sql"

&nbsp;   docs: "workspaces/ws-<workspace\_id>/docs"

EOF

```



Commit inicial:



```bash

git add .

git commit -m "mod14: estrutura base workspaces (v0.1)"

git remote add origin git@github.com:appgear/webapp-ia-gitops-workspaces.git

git push -u origin main

```



> Observação: o \*\*ApplicationSet do M13\*\* deve estar configurado no repo core para observar `workspaces/` deste repo.

> O M14 \*\*não cria\*\* esse ApplicationSet; apenas respeita o layout de pastas.



---



\### 4.2 WorkflowTemplate com FinOps e Resources



No repo `webapp-ia-gitops-core`, crie os templates de pipeline.



```bash

cd ~/workspace/webapp-ia-gitops-core

mkdir -p apps/core/gitops/pipeline-templates

```



`apps/core/gitops/pipeline-templates/kustomization.yaml`:



```bash

cat > apps/core/gitops/pipeline-templates/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - workflowtemplate-ai-first.yaml

EOF

```



`apps/core/gitops/pipeline-templates/workflowtemplate-ai-first.yaml`:



```bash

cat > apps/core/gitops/pipeline-templates/workflowtemplate-ai-first.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: WorkflowTemplate

metadata:

&nbsp; name: appgear-ai-first-pipeline

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   app.kubernetes.io/name: appgear-ai-first-pipeline

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod14-ai-first-pipelines"

spec:

&nbsp; entrypoint: pipeline

&nbsp; podMetadata:

&nbsp;   labels:

&nbsp;     app.kubernetes.io/name: appgear-ai-first-pipeline

&nbsp;     appgear.io/tier: core

&nbsp;     appgear.io/suite: core

&nbsp;     appgear.io/topology: B

&nbsp;     # labels dinâmicas para FinOps (por execução)

&nbsp;     appgear.io/tenant-id: "{{workflow.parameters.tenant\_id}}"

&nbsp;     appgear.io/workspace-id: "{{workflow.parameters.workspace\_id}}"

&nbsp; arguments:

&nbsp;   parameters:

&nbsp;     - name: tenant\_id

&nbsp;     - name: workspace\_id

&nbsp;     - name: repo\_url

&nbsp;     - name: git\_revision

&nbsp; templates:

&nbsp;   - name: pipeline

&nbsp;     dag:

&nbsp;       tasks:

&nbsp;         - name: clone-repo

&nbsp;           template: git-clone

&nbsp;         - name: opa-validate

&nbsp;           dependencies: \[clone-repo]

&nbsp;           template: opa-validate

&nbsp;         - name: e2e-tests

&nbsp;           dependencies: \[opa-validate]

&nbsp;           template: e2e-tests

&nbsp;         - name: chaos-check

&nbsp;           dependencies: \[e2e-tests]

&nbsp;           template: chaos-check



&nbsp;   - name: git-clone

&nbsp;     inputs:

&nbsp;       parameters:

&nbsp;         - name: tenant\_id

&nbsp;           value: "{{workflow.parameters.tenant\_id}}"

&nbsp;         - name: workspace\_id

&nbsp;           value: "{{workflow.parameters.workspace\_id}}"

&nbsp;         - name: repo\_url

&nbsp;           value: "{{workflow.parameters.repo\_url}}"

&nbsp;         - name: git\_revision

&nbsp;           value: "{{workflow.parameters.git\_revision}}"

&nbsp;     container:

&nbsp;       image: alpine/git:2.45.2

&nbsp;       command: \["/bin/sh","-c"]

&nbsp;       args:

&nbsp;         - |

&nbsp;           set -e

&nbsp;           mkdir -p /workdir

&nbsp;           cd /workdir

&nbsp;           git clone "{{inputs.parameters.repo\_url}}" repo

&nbsp;           cd repo

&nbsp;           git checkout "{{inputs.parameters.git\_revision}}"



&nbsp;           # Gera manifest agregado da pasta do workspace

&nbsp;           TARGET\_DIR="workspaces/ws-{{inputs.parameters.workspace\_id}}/k8s/vcluster"

&nbsp;           if \[ ! -d "$TARGET\_DIR" ]; then

&nbsp;             echo "Diretório de vcluster não encontrado: $TARGET\_DIR"

&nbsp;             exit 1

&nbsp;           fi

&nbsp;           cd "$TARGET\_DIR"

&nbsp;           kustomize build . > /tmp/manifest.yaml

&nbsp;       volumeMounts:

&nbsp;         - name: workdir

&nbsp;           mountPath: /workdir

&nbsp;       resources:

&nbsp;         requests:

&nbsp;           cpu: "100m"

&nbsp;           memory: "128Mi"

&nbsp;         limits:

&nbsp;           cpu: "500m"

&nbsp;           memory: "512Mi"

&nbsp;     outputs:

&nbsp;       parameters:

&nbsp;         - name: manifest

&nbsp;           valueFrom:

&nbsp;             path: /tmp/manifest.yaml



&nbsp;   - name: opa-validate

&nbsp;     inputs:

&nbsp;       parameters:

&nbsp;         - name: manifest

&nbsp;           value: "{{tasks.clone-repo.outputs.parameters.manifest}}"

&nbsp;     container:

&nbsp;       image: curlimages/curl:8.7.1

&nbsp;       command: \["/bin/sh","-c"]

&nbsp;       args:

&nbsp;         - |

&nbsp;           echo "Validando manifesto no OPA..."

&nbsp;           echo "${MANIFEST}" | jq '.' >/tmp/manifest.json || {

&nbsp;             echo "Manifesto inválido para JSON";

&nbsp;             exit 1;

&nbsp;           }

&nbsp;           curl -s -X POST \\

&nbsp;             -H "Content-Type: application/json" \\

&nbsp;             --data @/tmp/manifest.json \\

&nbsp;             http://core-opa.security.svc.cluster.local:8181/v1/data/appgear/security/deny \\

&nbsp;             | jq -e '.result | length == 0' \\

&nbsp;             || { echo "Políticas OPA violadas"; exit 1; }

&nbsp;       env:

&nbsp;         - name: MANIFEST

&nbsp;           value: "{{inputs.parameters.manifest}}"

&nbsp;       resources:

&nbsp;         requests:

&nbsp;           cpu: "100m"

&nbsp;           memory: "128Mi"

&nbsp;         limits:

&nbsp;           cpu: "500m"

&nbsp;           memory: "512Mi"



&nbsp;   - name: e2e-tests

&nbsp;     inputs:

&nbsp;       parameters:

&nbsp;         - name: workspace\_id

&nbsp;           value: "{{workflow.parameters.workspace\_id}}"

&nbsp;     container:

&nbsp;       image: cypress/included:13.8.1

&nbsp;       command: \["/bin/sh","-c"]

&nbsp;       args:

&nbsp;         - |

&nbsp;           echo "Executando testes E2E para workspace {{inputs.parameters.workspace\_id}}"

&nbsp;           # Aqui assumimos que o repositório já foi clonado em /workdir/repo

&nbsp;           if \[ -d "/workdir/repo/tests/e2e" ]; then

&nbsp;             cd /workdir/repo

&nbsp;             npx cypress run --spec "tests/e2e/\*\*/\*.cy.ts"

&nbsp;           else

&nbsp;             echo "Nenhum teste E2E encontrado, seguindo..."

&nbsp;           fi

&nbsp;       volumeMounts:

&nbsp;         - name: workdir

&nbsp;           mountPath: /workdir

&nbsp;       resources:

&nbsp;         requests:

&nbsp;           cpu: "500m"

&nbsp;           memory: "512Mi"

&nbsp;         limits:

&nbsp;           cpu: "2"

&nbsp;           memory: "2Gi"



&nbsp;   - name: chaos-check

&nbsp;     inputs:

&nbsp;       parameters:

&nbsp;         - name: tenant\_id

&nbsp;           value: "{{workflow.parameters.tenant\_id}}"

&nbsp;         - name: workspace\_id

&nbsp;           value: "{{workflow.parameters.workspace\_id}}"

&nbsp;     container:

&nbsp;       image: bitnami/kubectl:1.30

&nbsp;       command: \["/bin/sh","-c"]

&nbsp;       args:

&nbsp;         - |

&nbsp;           echo "Verificando ChaosEngine para tenant={{inputs.parameters.tenant\_id}}, ws={{inputs.parameters.workspace\_id}}"

&nbsp;           kubectl -n guardian get chaosengine \\

&nbsp;             -l appgear.io/tenant-id={{inputs.parameters.tenant\_id}},appgear.io/workspace-id={{inputs.parameters.workspace\_id}} || \\

&nbsp;             echo "Nenhum ChaosEngine configurado para este workspace"

&nbsp;       resources:

&nbsp;         requests:

&nbsp;           cpu: "50m"

&nbsp;           memory: "64Mi"

&nbsp;         limits:

&nbsp;           cpu: "200m"

&nbsp;           memory: "256Mi"

&nbsp;     volumes:

&nbsp;       - name: workdir

&nbsp;         emptyDir: {}

EOF

```



Inclua o diretório em algum `kustomization.yaml` existente (por exemplo `apps/core/gitops/kustomization.yaml`):



```bash

mkdir -p apps/core/gitops

cat > apps/core/gitops/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - pipeline-templates

EOF

```



Commit:



```bash

git add apps/core/gitops

git commit -m "mod14 v0.1: WorkflowTemplate AI-First com FinOps + resources"

git push origin main

```



---



\### 4.3 Argo Events – Webhook AI-First



Crie os manifests de EventSource e Sensor (no mesmo repo core):



```bash

mkdir -p apps/core/gitops/argo-events

```



`apps/core/gitops/argo-events/kustomization.yaml`:



```bash

cat > apps/core/gitops/argo-events/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - eventsource-ai-first.yaml

&nbsp; - sensor-ai-first.yaml

EOF

```



`apps/core/gitops/argo-events/eventsource-ai-first.yaml`:



```bash

cat > apps/core/gitops/argo-events/eventsource-ai-first.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: EventSource

metadata:

&nbsp; name: ai-first-git-webhook

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod14-ai-first-pipelines"

spec:

&nbsp; service:

&nbsp;   ports:

&nbsp;     - port: 12000

&nbsp;       targetPort: 12000

&nbsp; webhook:

&nbsp;   ai-first:

&nbsp;     port: "12000"

&nbsp;     endpoint: /events/ai-first

&nbsp;     method: POST

&nbsp;     insecure: false

EOF

```



`apps/core/gitops/argo-events/sensor-ai-first.yaml`:



```bash

cat > apps/core/gitops/argo-events/sensor-ai-first.yaml << 'EOF'

apiVersion: argoproj.io/v1alpha1

kind: Sensor

metadata:

&nbsp; name: ai-first-git-sensor

&nbsp; namespace: argocd

&nbsp; labels:

&nbsp;   appgear.io/tier: core

&nbsp;   appgear.io/suite: core

&nbsp;   appgear.io/topology: B

&nbsp;   appgear.io/workspace-id: global

&nbsp;   appgear.io/tenant-id: global

&nbsp; annotations:

&nbsp;   appgear.io/contract-version: "v0.1"

&nbsp;   appgear.io/module: "mod14-ai-first-pipelines"

spec:

&nbsp; template:

&nbsp;   serviceAccountName: argocd-application-controller

&nbsp; dependencies:

&nbsp;   - name: ai-first-webhook-dep

&nbsp;     eventSourceName: ai-first-git-webhook

&nbsp;     eventName: ai-first

&nbsp; triggers:

&nbsp;   - template:

&nbsp;       name: ai-first-pipeline-trigger

&nbsp;       argoWorkflow:

&nbsp;         operation: submit

&nbsp;         source:

&nbsp;           resource:

&nbsp;             apiVersion: argoproj.io/v1alpha1

&nbsp;             kind: Workflow

&nbsp;             metadata:

&nbsp;               generateName: ai-first-pipeline-

&nbsp;               namespace: argocd

&nbsp;             spec:

&nbsp;               workflowTemplateRef:

&nbsp;                 name: appgear-ai-first-pipeline

&nbsp;               arguments:

&nbsp;                 parameters:

&nbsp;                   - name: tenant\_id

&nbsp;                     value: ""

&nbsp;                   - name: workspace\_id

&nbsp;                     value: ""

&nbsp;                   - name: repo\_url

&nbsp;                     value: ""

&nbsp;                   - name: git\_revision

&nbsp;                     value: ""

&nbsp;         parameters:

&nbsp;           - src:

&nbsp;               dependencyName: ai-first-webhook-dep

&nbsp;               dataKey: body.tenant\_id

&nbsp;             dest: spec.arguments.parameters.0.value

&nbsp;           - src:

&nbsp;               dependencyName: ai-first-webhook-dep

&nbsp;               dataKey: body.workspace\_id

&nbsp;             dest: spec.arguments.parameters.1.value

&nbsp;           - src:

&nbsp;               dependencyName: ai-first-webhook-dep

&nbsp;               dataKey: body.repo\_url

&nbsp;             dest: spec.arguments.parameters.2.value

&nbsp;           - src:

&nbsp;               dependencyName: ai-first-webhook-dep

&nbsp;               dataKey: body.git\_revision

&nbsp;             dest: spec.arguments.parameters.3.value

EOF

```



Adicione `argo-events` ao `apps/core/gitops/kustomization.yaml`:



```bash

cat > apps/core/gitops/kustomization.yaml << 'EOF'

apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization



resources:

&nbsp; - pipeline-templates

&nbsp; - argo-events

EOF

```



Commit:



```bash

git add apps/core/gitops

git commit -m "mod14 v0.1: Argo Events webhook AI-First com tenant/workspace"

git push origin main

```



> Este webhook será chamado exclusivamente pelo N8n, após o commit no repo `webapp-ia-gitops-workspaces`.



---



\### 4.4 Integração N8n ↔ Vault ↔ Git (Segurança)



\#### 4.4.1 Criar segredo no Vault (M05)



No Vault (via CLI ou UI), crie o caminho, por exemplo:



`secret/appgear/git/ai-first`



com chave:



\* `ssh\_private\_key`: conteúdo da chave privada usada para acesso `git@github.com:appgear/webapp-ia-gitops-workspaces.git`.



Exemplo CLI (hashicorp vault):



```bash

vault kv put secret/appgear/git/ai-first ssh\_private\_key="@/caminho/para/id\_rsa\_ai\_first"

```



\#### 4.4.2 Variáveis de ambiente do N8n



No deployment do N8n (M08), inclua:



\* via Vault Agent Injector ou outra estratégia adotada no M05. Em nível de documentação, considere:



```yaml

env:

&nbsp; - name: VAULT\_ADDR

&nbsp;   value: https://vault.security.svc.cluster.local:8200

&nbsp; - name: VAULT\_ROLE

&nbsp;   value: appgear-n8n

&nbsp; - name: VAULT\_SECRET\_GIT\_AI\_FIRST

&nbsp;   value: secret/appgear/git/ai-first

&nbsp; - name: AI\_FIRST\_WORKSPACES\_REPO\_SSH

&nbsp;   value: git@github.com:appgear/webapp-ia-gitops-workspaces.git

&nbsp; - name: AI\_FIRST\_WORKSPACES\_BRANCH

&nbsp;   value: main

&nbsp; - name: AI\_FIRST\_ARGO\_EVENTS\_URL

&nbsp;   value: https://argo-events.dev.appgear.local/events/ai-first

```



\#### 4.4.3 Fluxo N8n – Obter chave do Vault



No fluxo N8n (AI-First Generator), inclua:



1\. \*\*Node HTTP Request → Vault (Get Token / Login)\*\*



&nbsp;  \* Usa `VAULT\_ROLE` para obter token (se usar JWT/Kubernetes Auth).



2\. \*\*Node HTTP Request → Vault (Get Secret)\*\*



&nbsp;  \* GET `v1/secret/data/appgear/git/ai-first`.

&nbsp;  \* Extrai `ssh\_private\_key` do JSON.



3\. \*\*Node Function (JavaScript/TypeScript)\*\*



&nbsp;  \* Escreve o conteúdo da chave em arquivo temporário no container N8n (por exemplo `/home/node/.ssh/id\_rsa\_ai\_first`), ajustando permissões.



> Desta forma, a chave \*\*não fica estática\*\* no deployment do N8n.

> Toda vez que o fluxo roda, a chave é obtida do Vault em tempo de execução.



---



\### 4.5 Fluxo N8n – AI-First Generator (alto nível)



Fluxo lógico (o JSON export oficial do N8n deve ser versionado em repo próprio):



1\. \*\*Trigger – Webhook Portal/Backstage\*\*



&nbsp;  \* URL: `/ai-first/generate`.

&nbsp;  \* Recebe:



&nbsp;    \* `tenant\_id`

&nbsp;    \* `workspace\_id`

&nbsp;    \* requisitos de negócio (suítes, tipos de app, integrações, etc.).



2\. \*\*Node – IA (Flowise / LiteLLM)\*\*



&nbsp;  \* Gera plano de arquitetura para o workspace:



&nbsp;    \* quais Suítes ativar;

&nbsp;    \* quais serviços core (Directus, Appsmith, N8n adicionais, etc.);

&nbsp;    \* que estruturas de dados criar.



3\. \*\*Node – Function (Geração de arquivos)\*\*



&nbsp;  \* Usa template `workspace-structure.yaml`.

&nbsp;  \* Preenche:



&nbsp;    \* `workspaces/ws-<workspace\_id>/k8s/vcluster/...` com manifests K8s (Deployment, Service, etc.);

&nbsp;    \* `workspaces/ws-<workspace\_id>/sql/\*.sql` (se houver);

&nbsp;    \* `workspaces/ws-<workspace\_id>/docs/README.md`.



4\. \*\*Node – Obter chave Git do Vault\*\* (seção 4.4).



5\. \*\*Node – Execute Command (Git)\*\*



&nbsp;  \* Clona `webapp-ia-gitops-workspaces` usando `AI\_FIRST\_WORKSPACES\_REPO\_SSH`.

&nbsp;  \* Copia/atualiza a pasta do workspace.

&nbsp;  \* Executa `git add`, `git commit` e `git push`.



Exemplo de script:



```bash

\#!/bin/sh

set -e

REPO="${AI\_FIRST\_WORKSPACES\_REPO\_SSH}"

BRANCH="${AI\_FIRST\_WORKSPACES\_BRANCH}"

WS\_ID="$1"



mkdir -p /tmp/ai-first

cd /tmp/ai-first



if \[ ! -d repo ]; then

&nbsp; git clone "$REPO" repo

fi



cd repo

git checkout "$BRANCH"



mkdir -p "workspaces/ws-${WS\_ID}/k8s/vcluster"

mkdir -p "workspaces/ws-${WS\_ID}/sql"

mkdir -p "workspaces/ws-${WS\_ID}/docs"



cp -R /tmp/ai-first/generated/manifests/\* "workspaces/ws-${WS\_ID}/k8s/vcluster/" || true

cp -R /tmp/ai-first/generated/sql/\* "workspaces/ws-${WS\_ID}/sql/" || true

cp -R /tmp/ai-first/generated/docs/\* "workspaces/ws-${WS\_ID}/docs/" || true



git add "workspaces/ws-${WS\_ID}"

git commit -m "ai-first: atualiza ecosistema do workspace ${WS\_ID}" || echo "Nada para commitar"

git push origin "$BRANCH"



\# Captura o último commit

git rev-parse HEAD > /tmp/ai-first\_last\_commit

```



6\. \*\*Node – HTTP Request → Argo Events Webhook\*\*



\* URL: `${AI\_FIRST\_ARGO\_EVENTS\_URL}`

\* Método: `POST`

\* Body:



```json

{

&nbsp; "tenant\_id": "t-123",

&nbsp; "workspace\_id": "ws-123",

&nbsp; "repo\_url": "git@github.com:appgear/webapp-ia-gitops-workspaces.git",

&nbsp; "git\_revision": "{{conteúdo de /tmp/ai-first\_last\_commit}}"

}

```



> \*\*N8n nunca escreve em `webapp-ia-gitops-core`.\*\*

> Eventuais ajustes em ApplicationSet, Argo CD, etc., são responsabilidade da equipe de plataforma (M01/M13).



---



\### 4.6 Topologia A (Demo) – Opcional



Para demonstrações sem K8s, você pode:



\* Rodar `N8n + Git local` via `docker-compose`;

\* Simular o Webhook do Argo Events com um serviço dummy.



Exemplo mínimo:



```bash

mkdir -p /opt/webapp-ia/ai-first

cd /opt/webapp-ia/ai-first

```



`docker-compose.ai-first.yml`:



```bash

cat > docker-compose.ai-first.yml << 'EOF'

version: "3.9"



services:

&nbsp; traefik:

&nbsp;   image: traefik:v2.11

&nbsp;   command:

&nbsp;     - "--providers.docker=true"

&nbsp;     - "--entrypoints.web.address=:80"

&nbsp;   ports:

&nbsp;     - "80:80"

&nbsp;   volumes:

&nbsp;     - /var/run/docker.sock:/var/run/docker.sock



&nbsp; n8n:

&nbsp;   image: n8nio/n8n:latest

&nbsp;   environment:

&nbsp;     - N8N\_HOST=localhost

&nbsp;     - N8N\_PORT=5678

&nbsp;     - N8N\_PROTOCOL=http

&nbsp;     - AI\_FIRST\_WORKSPACES\_REPO\_SSH=${AI\_FIRST\_WORKSPACES\_REPO\_SSH}

&nbsp;     - AI\_FIRST\_WORKSPACES\_BRANCH=${AI\_FIRST\_WORKSPACES\_BRANCH}

&nbsp;   volumes:

&nbsp;     - ./data/n8n:/home/node/.n8n

&nbsp;   labels:

&nbsp;     - "traefik.enable=true"

&nbsp;     - "traefik.http.routers.n8n.rule=PathPrefix(`/n8n`)"

&nbsp;     - "traefik.http.services.n8n.loadbalancer.server.port=5678"

EOF

```



Subir:



```bash

docker compose -f docker-compose.ai-first.yml up -d

```



> Nesta topologia, você pode inspecionar apenas a parte \*\*N8n → Git\*\*.

> O fluxo Argo é simulado ou omitido.



---



\## 5. Como verificar



1\. \*\*WorkflowTemplate presente e com labels FinOps\*\*



```bash

kubectl get workflowtemplate appgear-ai-first-pipeline -n argocd -o yaml

```



Verifique se:



\* existe `spec.podMetadata.labels.appgear.io/tenant-id`;

\* existe `spec.podMetadata.labels.appgear.io/workspace-id`;

\* containers têm `resources.requests` e `resources.limits`.



2\. \*\*EventSource e Sensor ativos\*\*



```bash

kubectl get eventsource -n argocd

kubectl get sensor -n argocd

```



Você deve ver:



\* `ai-first-git-webhook`

\* `ai-first-git-sensor`



3\. \*\*Execução de teste end-to-end\*\*



\* Dispare o fluxo N8n para um `tenant\_id` e `workspace\_id` de teste.

\* Confirme no repo:



```bash

cd ~/workspace/webapp-ia-gitops-workspaces

git pull

ls workspaces/ws-<workspace\_id>

```



\* Confirme workflows:



```bash

kubectl get wf -n argocd

argo list -n argocd

```



Pegue o nome do workflow e veja labels/pods:



```bash

argo get <nome-do-workflow> -n argocd

kubectl get pods -n argocd -l appgear.io/workspace-id=ws-<workspace\_id>

kubectl get pods -n argocd -l appgear.io/tenant-id=t-<tenant\_id>

```



4\. \*\*Verificar que N8n não toca o repo core\*\*



\* Em `webapp-ia-gitops-core`, veja o log:



```bash

cd ~/workspace/webapp-ia-gitops-core

git log --oneline | head

```



\* Não deve haver commits automáticos de N8n para arquivos como `apps-workspaces.yaml`.

\* Qualquer alteração em core deve vir de pipeline de infra, não do AI-First.



5\. \*\*FinOps / Observabilidade\*\*



\* Em Grafana (M03), crie/veja dashboard que filtre:



&nbsp; \* `namespace=argocd`;

&nbsp; \* `labels.appgear\_io\_tenant\_id`;

&nbsp; \* `labels.appgear\_io\_workspace\_id`.

\* Confirme que a CPU/RAM de pipelines estão contabilizadas por tenant/workspace.



---



\## 6. Erros comuns



1\. \*\*N8n alterando o repositório core\*\*



\* Sintoma:



&nbsp; \* Commits automáticos no `webapp-ia-gitops-core` (ex.: modificando ApplicationSet, apps-core, etc.).

\* Correção:



&nbsp; \* Remover qualquer passo no fluxo N8n que clone/commit no repo core.

&nbsp; \* Garantir que o N8n só conhece `webapp-ia-gitops-workspaces`.



2\. \*\*ApplicationSet do M13 não enxergando o workspace\*\*



\* Sintoma:



&nbsp; \* Pasta `workspaces/ws-123` existe, mas nenhum Application é criado para o workspace.

\* Causas prováveis:



&nbsp; \* Padrão de pasta no M13 diferente de `workspaces/ws-<workspace\_id>`;

&nbsp; \* Falta de commit/push da pasta.

\* Correção:



&nbsp; \* Ajustar convenção de path no N8n ou no ApplicationSet (M13) para coincidirem.



3\. \*\*Pods de pipeline sem labels de tenant/workspace\*\*



\* Sintoma:



&nbsp; \* `kubectl get pods -n argocd --show-labels` não mostra `appgear.io/tenant-id` e `appgear.io/workspace-id`.

\* Correção:



&nbsp; \* Confirmar `podMetadata.labels` no WorkflowTemplate;

&nbsp; \* Confirmar que o Sensor preenche `tenant\_id` e `workspace\_id` nos parameters;

&nbsp; \* Garantir que o webhook do N8n envia esses campos no body.



4\. \*\*Workflows consumindo recursos demais\*\*



\* Sintoma:



&nbsp; \* Cluster com alto consumo de CPU/RAM durante pipelines; pods sem limites.

\* Correção:



&nbsp; \* Revisar `resources.requests/limits` nos templates (especialmente `e2e-tests`);

&nbsp; \* Adicionar quotas em namespace `argocd` se necessário.



5\. \*\*Falha no OPA por endpoint ou payload\*\*



\* Sintoma:



&nbsp; \* Step `opa-validate` falha com erro de conexão ou de parse.

\* Correção:



&nbsp; \* Verificar se o serviço OPA e caminho (`/v1/data/appgear/security/deny`) coincidem com M05;

&nbsp; \* Confirmar que `MANIFEST` está em formato esperado (YAML→JSON).



6\. \*\*Uso de chave SSH estática em N8n\*\*



\* Sintoma:



&nbsp; \* Chave de Git embutida diretamente no deployment, configmap ou no fluxo N8n.

\* Correção:



&nbsp; \* Remover chave estática;

&nbsp; \* Reconfigurar fluxo para obter `ssh\_private\_key` do Vault (M05);

&nbsp; \* Rotacionar a chave comprometida.



---



\## 7. Onde salvar



1\. \*\*Contrato / Desenvolvimento\*\*



\* Repositório: `appgear-contracts` (ou equivalente).

\* Arquivo:

&nbsp; `1 - Desenvolvimento v0.md` ou `Módulo 14 v0.1.md`, conforme organização.

\* Seção:

&nbsp; `### Módulo 14 v0.1 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD)`



2\. \*\*Repositório GitOps Core\*\*



\* Repositório: `webapp-ia-gitops-core`

\* Estrutura:



```text

apps/core/gitops/

&nbsp; kustomization.yaml        # inclui pipeline-templates e argo-events

&nbsp; pipeline-templates/

&nbsp;   kustomization.yaml

&nbsp;   workflowtemplate-ai-first.yaml

&nbsp; argo-events/

&nbsp;   kustomization.yaml

&nbsp;   eventsource-ai-first.yaml

&nbsp;   sensor-ai-first.yaml

```



3\. \*\*Repositório GitOps Workspaces\*\*



\* Repositório: `webapp-ia-gitops-workspaces`

\* Estrutura:



```text

clusters/ag-br-core-dev/

&nbsp; kustomization.yaml



workspaces/

&nbsp; .templates/

&nbsp;   workspace-structure.yaml

&nbsp; ws-<workspace\_id>/

&nbsp;   k8s/

&nbsp;     vcluster/

&nbsp;       kustomization.yaml

&nbsp;       # manifests gerados pelo N8n

&nbsp;   sql/

&nbsp;     0001-init.sql

&nbsp;   docs/

&nbsp;     README.md

```



4\. \*\*Fluxos N8n\*\*



\* Repositório sugerido: `appgear-n8n-flows` ou similar.

\* Estrutura:



```text

flows/

&nbsp; ai-first/

&nbsp;   ai-first-generate-workspace.json   # export do fluxo N8n

```



---



Com este retrofit, o \*\*Módulo 14 v0.1\*\* fica:



\* Em \*\*Markdown\*\* e no padrão de seções do M00 v0.1.

\* Alinhado ao \*\*ApplicationSet\*\* do M13 (N8n não toca repo core).

\* Com \*\*FinOps\*\* adequado (labels de tenant/workspace nos pods do pipeline).

\* Com \*\*resources\*\* definidos para steps críticos.

\* Com \*\*integração explícita com Vault\*\* para o segredo de Git.



