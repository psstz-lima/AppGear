# Módulo 14 – Pipelines de Geração AI-First

Versão: v0

Orquestra o fluxo “N8n + IA → Git → Argo → vCluster”:
Requisitos de negócio entram no N8n, IA gera manifests/SQL/docs em appgear-gitops-workspaces, Argo Events/Workflows validam (OPA, testes), e Argo CD aplica no workspace/vCluster.

---

## O que é

O **Módulo 14** define os **Pipelines de Geração AI-First** da AppGear: o caminho completo que transforma decisões de negócio (geradas/assistidas por IA no N8n) em **deploy GitOps Nível 3** sobre vClusters por workspace.

Fluxo canônico:

**N8n (AI-First Generator) → Git (`appgear-gitops-workspaces`) → Argo Events → Argo Workflows → Argo CD → vCluster por workspace (M13)**

Elementos principais:

1. **N8n – AI-First Generator**

   * Fluxo N8n recebe:

     * `tenant_id`, `workspace_id` e requisitos de negócio;
   * Usa modelos via Flowise/LiteLLM para desenhar a arquitetura;
   * Gera arquivos (manifests, SQL, docs) para a árvore Git do workspace.

2. **Repositório `appgear-gitops-workspaces`**

   * Registro GitOps de workspaces e vClusters (M13);
   * N8n:

     * apenas clona, altera e comita neste repo;
     * nunca toca `appgear-gitops-core` nem `appgear-gitops-suites`.

3. **Argo Events**

   * Expõe um **webhook AI-First**;
   * Recebe evento do N8n com:

     * `tenant_id`, `workspace_id`, `repo_url`, `git_revision`;
   * Dispara um Workflow de pipeline AI-First via Argo Workflows.

4. **Argo Workflows**

   * WorkflowTemplate `appgear-ai-first-pipeline` com tasks:

     * `git-clone` (gera manifest agregado com `kustomize build`);
     * `opa-validate` (valida com OPA/M05);
     * `e2e-tests` (Cypress, testes E2E opcionais);
     * `chaos-check` (integra com Guardian/M12).
   * **Todos os pods de pipeline são rotulados com `appgear.io/tenant-id` e `appgear.io/workspace-id`** e possuem `resources.requests/limits`.

5. **Argo CD + ApplicationSet (M13)**

   * ApplicationSet de workspaces já existente em `appgear-gitops-core`;
   * Ao ver alterações em `appgear-gitops-workspaces/workspaces/<workspace_id>`, Argo CD reconcilia o vCluster daquele workspace.

---

## Por que

1. **Cumprir GitOps Nível 3 do contrato**

* O contrato AppGear exige:

  * Gerar infraestrutura via Git;
  * Não usar `kubectl apply` direto a partir do N8n;
  * Fluxo: **Git como fonte de verdade**, Argo CD como executor de deploy.

2. **Escalabilidade via ApplicationSets (M13)**

* M13 define que:

  * **Workspaces/vClusters são descobertos por pasta** em `appgear-gitops-workspaces`;
  * ApplicationSet gera dinamicamente os `Applications`.
* M14 garante:

  * N8n **não escreve nada** em `appgear-gitops-core`;
  * N8n **produz exatamente a estrutura** que o ApplicationSet espera.

3. **FinOps para CI/CD**

* Pipelines consomem CPU/RAM relevantes;
* Sem labels `appgear.io/tenant-id` e `appgear.io/workspace-id`, custos de pipeline ficam invisíveis para OpenCost/Lago;
* M14:

  * define labels para workflows e pods;
  * padroniza `resources.requests/limits` para tasks pesadas (ex.: `e2e-tests`).

4. **Segurança e Segredos (M05)**

* N8n precisa de:

  * chave SSH para Git;
  * outras credenciais (tokens, webhooks, etc.).
* Políticas:

  * Segredos no **Vault** (SSoT);
  * N8n busca chave Git em tempo de execução via Vault (não embute chave estática no deployment).

5. **Interoperabilidade entre módulos**

* Consome:

  * **M08**: N8n e Flowise/LiteLLM;
  * **M05**: OPA (validação), Vault (segredos);
  * **M13**: estrutura de workspaces e vClusters;
  * **M12**: Chaos/Security (via `chaos-check`).
* Alimenta:

  * Workspaces (M13) com estruturas Git já prontas para as Suítes (Factory, Brain, Ops, Guardian).

---

## Pré-requisitos

### Conceituais

* Contrato v0 aprovado para:

  * AI-First Ecosystem Generator;
  * GitOps Nível 3;
  * Suítes, Workspaces e vClusters. 

* Módulos prévios:

  * M00 – Convenções, labels, FinOps, formato Markdown;
  * M01 – Bootstrap GitOps/Argo CD (App-of-Apps);
  * M02 – Borda/Malha (Traefik, Coraza, Kong, Istio);
  * M03 – Observabilidade/FinOps;
  * M04 – Armazenamento e Bancos;
  * M05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA);
  * M06 – Identidade e SSO;
  * M07 – Backstage/Portal;
  * M08 – Serviços Core (inclui N8n);
  * M09–M12 – Suítes (Factory, Brain, Ops, Guardian);
  * M13 – Workspaces/vClusters/ApplicationSet.

### Infraestrutura (Topologia B – Kubernetes)

Cluster padrão `ag-<regiao>-core-<env>` com:

* **Argo CD** em `argocd`;
* **Argo Workflows** e **Argo Events** instalados (podem ser implantados via GitOps por este módulo);
* **N8n** funcional (M08);
* **Vault e OPA** configurados (M05);
* **ApplicationSet de Workspaces** (M13) já ativo no `appgear-gitops-core`, observando `appgear-gitops-workspaces`.

### Repositórios

* `appgear-gitops-core` (infra core + App-of-Apps + pipeline templates);
* `appgear-gitops-suites` (suítes Factory/Brain/Ops/Guardian);
* `appgear-gitops-workspaces` (workspaces/vClusters por cliente/workspace);
* Repositório para fluxos N8n (ex.: `appgear-n8n-flows`).

> Regra de ouro: **N8n só escreve em `appgear-gitops-workspaces`**. Core/Suites são alterados apenas pela equipe de plataforma / pipelines infra.

### Ferramentas

* CLI: `git`, `kubectl`, `kustomize`, `argocd`;
* Acesso Git com chave SSH de deploy guardada no Vault.

---

## Como fazer (comandos)

### Módulo 14.1 – Estrutura do repositório `appgear-gitops-workspaces`

#### O que é

Definição da estrutura base do repositório GitOps de workspaces, que será escrita pelo N8n e lida pelos ApplicationSets do M13.

#### Como fazer (comandos)

1. Inicializar repositório:

```bash
mkdir -p ~/git/appgear-gitops-workspaces
cd ~/git/appgear-gitops-workspaces

git init
git remote add origin git@github.com:appgear/appgear-gitops-workspaces.git
```

2. Estrutura base:

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
  - ../../workspaces
EOF
```

Template de estrutura de workspace (referência para N8n):

```bash
cat > workspaces/.templates/workspace-structure.yaml << 'EOF'
structure:
  workspace:
    id: "ws-<workspace_id>"
  paths:
    k8s_vcluster: "workspaces/ws-<workspace_id>/k8s/vcluster"
    sql: "workspaces/ws-<workspace_id>/sql"
    docs: "workspaces/ws-<workspace_id>/docs"
EOF
```

3. Commit inicial:

```bash
git add .
git commit -m "mod14: estrutura base workspaces (v0.1)"
git push -u origin main
```

> O ApplicationSet do M13 deve estar configurado em `appgear-gitops-core` para observar `workspaces/` deste repo.

---

### Módulo 14.2 – WorkflowTemplate AI-First com FinOps e Resources

#### O que é

Um **WorkflowTemplate** Argo Workflows (`appgear-ai-first-pipeline`) que orquestra o pipeline AI-First, com labels FinOps e `resources` definidos em cada step.

#### Como fazer (comandos)

1. Estrutura no `appgear-gitops-core`:

```bash
cd ~/git/appgear-gitops-core
mkdir -p apps/core/gitops/pipeline-templates
```

`apps/core/gitops/pipeline-templates/kustomization.yaml`:

```bash
cat > apps/core/gitops/pipeline-templates/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - workflowtemplate-ai-first.yaml
EOF
```

2. WorkflowTemplate `appgear-ai-first-pipeline`:

```bash
cat > apps/core/gitops/pipeline-templates/workflowtemplate-ai-first.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: appgear-ai-first-pipeline
  namespace: argocd
  labels:
    app.kubernetes.io/name: appgear-ai-first-pipeline
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod14-ai-first-pipelines"
spec:
  entrypoint: pipeline
  podMetadata:
    labels:
      app.kubernetes.io/name: appgear-ai-first-pipeline
      appgear.io/tier: core
      appgear.io/suite: core
      appgear.io/topology: B
      appgear.io/tenant-id: "{{workflow.parameters.tenant_id}}"
      appgear.io/workspace-id: "{{workflow.parameters.workspace_id}}"
  arguments:
    parameters:
      - name: tenant_id
      - name: workspace_id
      - name: repo_url
      - name: git_revision

  templates:
    - name: pipeline
      dag:
        tasks:
          - name: clone-repo
            template: git-clone
          - name: opa-validate
            dependencies: [clone-repo]
            template: opa-validate
          - name: e2e-tests
            dependencies: [opa-validate]
            template: e2e-tests
          - name: chaos-check
            dependencies: [e2e-tests]
            template: chaos-check

    - name: git-clone
      inputs:
        parameters:
          - name: tenant_id
            value: "{{workflow.parameters.tenant_id}}"
          - name: workspace_id
            value: "{{workflow.parameters.workspace_id}}"
          - name: repo_url
            value: "{{workflow.parameters.repo_url}}"
          - name: git_revision
            value: "{{workflow.parameters.git_revision}}"
      container:
        image: alpine/git:2.45.2
        command: ["/bin/sh","-c"]
        args:
          - |
            set -e
            mkdir -p /workdir
            cd /workdir

            git clone "{{inputs.parameters.repo_url}}" repo
            cd repo
            git checkout "{{inputs.parameters.git_revision}}"

            TARGET_DIR="workspaces/ws-{{inputs.parameters.workspace_id}}/k8s/vcluster"
            if [ ! -d "$TARGET_DIR" ]; then
              echo "Diretório de vcluster não encontrado: $TARGET_DIR"
              exit 1
            fi

            cd "$TARGET_DIR"
            kustomize build . > /tmp/manifest.yaml
        volumeMounts:
          - name: workdir
            mountPath: /workdir
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
      outputs:
        parameters:
          - name: manifest
            valueFrom:
              path: /tmp/manifest.yaml

    - name: opa-validate
      inputs:
        parameters:
          - name: manifest
            value: "{{tasks.clone-repo.outputs.parameters.manifest}}"
      container:
        image: curlimages/curl:8.7.1
        command: ["/bin/sh","-c"]
        args:
          - |
            echo "Validando manifesto no OPA..."
            echo "${MANIFEST}" > /tmp/manifest.yaml

            curl -s -X POST \
              -H "Content-Type: application/yaml" \
              --data-binary @/tmp/manifest.yaml \
              http://core-opa.security.svc.cluster.local:8181/v1/data/appgear/security/deny \
              | jq -e '.result | length == 0' \
              || { echo "Políticas OPA violadas"; exit 1; }
        env:
          - name: MANIFEST
            value: "{{inputs.parameters.manifest}}"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

    - name: e2e-tests
      inputs:
        parameters:
          - name: workspace_id
            value: "{{workflow.parameters.workspace_id}}"
      container:
        image: cypress/included:13.8.1
        command: ["/bin/sh","-c"]
        args:
          - |
            echo "Executando testes E2E para workspace {{inputs.parameters.workspace_id}}"

            if [ -d "/workdir/repo/tests/e2e" ]; then
              cd /workdir/repo
              npx cypress run --spec "tests/e2e/**/*.cy.ts"
            else
              echo "Nenhum teste E2E encontrado, seguindo..."
            fi
        volumeMounts:
          - name: workdir
            mountPath: /workdir
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "2"
            memory: "2Gi"

    - name: chaos-check
      inputs:
        parameters:
          - name: tenant_id
            value: "{{workflow.parameters.tenant_id}}"
          - name: workspace_id
            value: "{{workflow.parameters.workspace_id}}"
      container:
        image: bitnami/kubectl:1.30
        command: ["/bin/sh","-c"]
        args:
          - |
            echo "Verificando ChaosEngine para tenant={{inputs.parameters.tenant_id}}, ws={{inputs.parameters.workspace_id}}"
            kubectl -n guardian get chaosengine \
              -l appgear.io/tenant-id={{inputs.parameters.tenant_id}},appgear.io/workspace-id={{inputs.parameters.workspace_id}} \
              || echo "Nenhum ChaosEngine configurado para este workspace"
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
  volumes:
    - name: workdir
      emptyDir: {}
EOF
```

3. Incluir em `apps/core/gitops/kustomization.yaml`:

```bash
mkdir -p apps/core/gitops
cat > apps/core/gitops/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - pipeline-templates
EOF
```

4. Commit:

```bash
git add apps/core/gitops
git commit -m "mod14 v0.1: WorkflowTemplate AI-First com FinOps + resources"
git push origin main
```

---

### Módulo 14.3 – Argo Events (Webhook AI-First)

#### O que é

Definição de **EventSource** e **Sensor** AI-First para Argo Events, que convertem um webhook HTTP em submissão de Workflows AI-First.

#### Como fazer (comandos)

1. Estrutura:

```bash
cd ~/git/appgear-gitops-core
mkdir -p apps/core/gitops/argo-events
```

`apps/core/gitops/argo-events/kustomization.yaml`:

```bash
cat > apps/core/gitops/argo-events/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - eventsource-ai-first.yaml
  - sensor-ai-first.yaml
EOF
```

2. EventSource:

```bash
cat > apps/core/gitops/argo-events/eventsource-ai-first.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: ai-first-git-webhook
  namespace: argocd
  labels:
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod14-ai-first-pipelines"
spec:
  service:
    ports:
      - port: 12000
        targetPort: 12000
  webhook:
    ai-first:
      port: "12000"
      endpoint: /events/ai-first
      method: POST
      insecure: false
EOF
```

3. Sensor:

```bash
cat > apps/core/gitops/argo-events/sensor-ai-first.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: ai-first-git-sensor
  namespace: argocd
  labels:
    appgear.io/tier: core
    appgear.io/suite: core
    appgear.io/topology: B
    appgear.io/workspace-id: global
    appgear.io/tenant-id: global
  annotations:
    appgear.io/contract-version: "v0.1"
    appgear.io/module: "mod14-ai-first-pipelines"
spec:
  template:
    serviceAccountName: argocd-application-controller
  dependencies:
    - name: ai-first-webhook-dep
      eventSourceName: ai-first-git-webhook
      eventName: ai-first
  triggers:
    - template:
        name: ai-first-pipeline-trigger
        argoWorkflow:
          operation: submit
          source:
            resource:
              apiVersion: argoproj.io/v1alpha1
              kind: Workflow
              metadata:
                generateName: ai-first-pipeline-
                namespace: argocd
              spec:
                workflowTemplateRef:
                  name: appgear-ai-first-pipeline
                arguments:
                  parameters:
                    - name: tenant_id
                      value: ""
                    - name: workspace_id
                      value: ""
                    - name: repo_url
                      value: ""
                    - name: git_revision
                      value: ""
          parameters:
            - src:
                dependencyName: ai-first-webhook-dep
                dataKey: body.tenant_id
              dest: spec.arguments.parameters.0.value
            - src:
                dependencyName: ai-first-webhook-dep
                dataKey: body.workspace_id
              dest: spec.arguments.parameters.1.value
            - src:
                dependencyName: ai-first-webhook-dep
                dataKey: body.repo_url
              dest: spec.arguments.parameters.2.value
            - src:
                dependencyName: ai-first-webhook-dep
                dataKey: body.git_revision
              dest: spec.arguments.parameters.3.value
EOF
```

4. Atualizar `apps/core/gitops/kustomization.yaml`:

```bash
cat > apps/core/gitops/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - pipeline-templates
  - argo-events
EOF
```

5. Commit:

```bash
git add apps/core/gitops
git commit -m "mod14 v0.1: Argo Events webhook AI-First com tenant/workspace"
git push origin main
```

> Este webhook será chamado pelo N8n após o commit em `appgear-gitops-workspaces`.

---

### Módulo 14.4 – Integração N8n ↔ Vault ↔ Git

#### O que é

Padrão para o N8n obter credencial Git do Vault e escrever no repositório `appgear-gitops-workspaces` com segurança.

#### Como fazer (comandos)

1. Criar segredo no Vault:

```bash
vault kv put secret/appgear/git/ai-first ssh_private_key=@/caminho/para/id_rsa_ai_first
```

2. Variáveis de ambiente no deployment do N8n (M08):

```yaml
env:
  - name: VAULT_ADDR
    value: https://vault.security.svc.cluster.local:8200
  - name: VAULT_ROLE
    value: appgear-n8n
  - name: VAULT_SECRET_GIT_AI_FIRST
    value: secret/appgear/git/ai-first
  - name: AI_FIRST_WORKSPACES_REPO_SSH
    value: git@github.com:appgear/appgear-gitops-workspaces.git
  - name: AI_FIRST_WORKSPACES_BRANCH
    value: main
  - name: AI_FIRST_ARGO_EVENTS_URL
    value: https://argo-events.dev.appgear.local/events/ai-first
```

3. No fluxo N8n (alto nível):

* Passos:

  1. Node HTTP → Vault (Auth);
  2. Node HTTP → Vault (Get Secret `ssh_private_key`);
  3. Node Function → grava chave em `/home/node/.ssh/id_rsa_ai_first` com permissões corretas;
  4. Node Execute Command → executa script `git` (clone, add, commit, push) sobre `appgear-gitops-workspaces`.

Exemplo de script usado pelo N8n:

```bash
#!/bin/sh
set -e

REPO="${AI_FIRST_WORKSPACES_REPO_SSH}"
BRANCH="${AI_FIRST_WORKSPACES_BRANCH}"
WS_ID="$1"

mkdir -p /tmp/ai-first
cd /tmp/ai-first

if [ ! -d repo ]; then
  git clone "$REPO" repo
fi

cd repo
git checkout "$BRANCH"

mkdir -p "workspaces/ws-${WS_ID}/k8s/vcluster"
mkdir -p "workspaces/ws-${WS_ID}/sql"
mkdir -p "workspaces/ws-${WS_ID}/docs"

cp -R /tmp/ai-first/generated/manifests/* "workspaces/ws-${WS_ID}/k8s/vcluster/" 2>/dev/null || true
cp -R /tmp/ai-first/generated/sql/*       "workspaces/ws-${WS_ID}/sql/"          2>/dev/null || true
cp -R /tmp/ai-first/generated/docs/*      "workspaces/ws-${WS_ID}/docs/"         2>/dev/null || true

git add "workspaces/ws-${WS_ID}"
git commit -m "ai-first: atualiza ecossistema do workspace ${WS_ID}" || echo "Nada para commitar"
git push origin "$BRANCH"

git rev-parse HEAD > /tmp/ai-first_last_commit
```

4. Node HTTP → Argo Events:

* URL: `${AI_FIRST_ARGO_EVENTS_URL}`;
* Body:

```json
{
  "tenant_id": "t-123",
  "workspace_id": "ws-123",
  "repo_url": "git@github.com:appgear/appgear-gitops-workspaces.git",
  "git_revision": "<conteúdo de /tmp/ai-first_last_commit>"
}
```

---

### Módulo 14.5 – Fluxo N8n AI-First Generator (lógico)

#### O que é

O desenho do fluxo N8n que implementa o AI-First Generator; o JSON exportado deve ser versionado em repositório próprio (`appgear-n8n-flows`).

#### Resumo do fluxo

1. **Trigger – Webhook Portal/Backstage**

   * Recebe:

     * `tenant_id`, `workspace_id`;
     * requisitos de negócio (suítes, tipo de app, integrações).

2. **Node – IA (Flowise/LiteLLM)**

   * Gera plano de arquitetura:

     * quais Suítes habilitar;
     * quais serviços (Directus, Appsmith, N8n extra, etc.);
     * estruturas de dados, filas, integrações.

3. **Node – Function (Geração de arquivos)**

   * Usa `workspace-structure.yaml` como referência;
   * Gera arquivos em `/tmp/ai-first/generated/...`:

     * `manifests` (K8s);
     * `sql` (opcional);
     * `docs`.

4. **Node – Vault (pegar chave Git)**

5. **Node – Execute Command (Git)**

   * Roda script anterior, escrevendo em `appgear-gitops-workspaces`.

6. **Node – HTTP Request → Argo Events**

   * Dispara o pipeline AI-First.

---

### Módulo 14.6 – Topologia A (demo, opcional)

#### O que é

Modo de demonstração simples (sem K8s) com N8n + Traefik, para validar apenas a parte **N8n → Git**.

#### Como fazer (comandos)

1. Estrutura:

```bash
mkdir -p /opt/appgear/ai-first
cd /opt/appgear/ai-first
```

2. `docker-compose.ai-first.yml`:

```bash
cat > docker-compose.ai-first.yml << 'EOF'
version: "3.9"

services:
  traefik:
    image: traefik:v2.11
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  n8n:
    image: n8nio/n8n:latest
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - AI_FIRST_WORKSPACES_REPO_SSH=${AI_FIRST_WORKSPACES_REPO_SSH}
      - AI_FIRST_WORKSPACES_BRANCH=${AI_FIRST_WORKSPACES_BRANCH}
    volumes:
      - ./data/n8n:/home/node/.n8n
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=PathPrefix(`/n8n`)"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"
EOF
```

3. Subir:

```bash
docker compose -f docker-compose.ai-first.yml up -d
```

> Topologia A é apenas para desenvolvimento/demo; produção é sempre Topologia B (Kubernetes).

---

## Como verificar

1. **WorkflowTemplate e labels FinOps**

```bash
kubectl get workflowtemplate appgear-ai-first-pipeline -n argocd -o yaml
```

Verificar:

* `spec.podMetadata.labels.appgear.io/tenant-id`;
* `spec.podMetadata.labels.appgear.io/workspace-id`;
* `resources.requests/limits` nos templates.

2. **EventSource e Sensor**

```bash
kubectl get eventsource -n argocd
kubectl get sensor -n argocd
```

Esperado:

* `ai-first-git-webhook`;
* `ai-first-git-sensor` com status saudável.

3. **Execução ponta a ponta de teste**

* Disparar fluxo N8n para `tenant_id` e `workspace_id` de teste;
* Verificar repo de workspaces:

```bash
cd ~/git/appgear-gitops-workspaces
git pull
ls workspaces/ws-<workspace_id>
```

* Ver workflows:

```bash
kubectl get wf -n argocd
argo list -n argocd
```

Pegar workflow e inspecionar labels/pods:

```bash
ARGO_WF=<nome-do-workflow>
argo get "$ARGO_WF" -n argocd
kubectl get pods -n argocd -l appgear.io/workspace-id=<workspace_id>
kubectl get pods -n argocd -l appgear.io/tenant-id=<tenant_id>
```

4. **N8n não tocar `appgear-gitops-core`**

```bash
cd ~/git/appgear-gitops-core
git log --oneline | head
```

* Commit messages de N8n **não** devem aparecer aqui;
* Ajustes de core são só de infra.

5. **FinOps / Observabilidade**

* No Grafana (M03), filtrar:

  * `namespace=argocd`;
  * `labels.appgear_io_tenant_id`;
  * `labels.appgear_io_workspace_id`.
* OpenCost/Lago devem atribuir custo de CPU/RAM de pipelines a cada tenant/workspace.

6. **Vault / Segurança**

* Validar que o fluxo N8n consegue pegar o segredo:

  * Sem expor chave em logs;
  * Sem falhas de autenticação no Vault.

---

## Erros comuns

1. **N8n alterando `appgear-gitops-core`**

* Problema:

  * Fluxo clonando e comitando no repo core (ApplicationSets, etc.).
* Correção:

  * Remover passos no N8n que toquem `appgear-gitops-core`;
  * Manter foco exclusivo em `appgear-gitops-workspaces`.

2. **ApplicationSet do M13 não enxergar workspace**

* Sintoma:

  * Pasta `workspaces/ws-123` existe, mas não aparece `ws-123` no Argo CD.
* Causas:

  * Path esperado pelo ApplicationSet ≠ `workspaces/ws-<workspace_id>`;
  * Falta de commit/push.
* Correção:

  * Ajustar path no N8n ou no ApplicationSet;
  * Garantir push bem-sucedido.

3. **Pods de pipeline sem labels de tenant/workspace**

* Sintoma:

  * `kubectl get pods -n argocd --show-labels` não mostra `appgear.io/tenant-id` ou `appgear.io/workspace-id`.
* Correção:

  * Ver `podMetadata.labels` no WorkflowTemplate;
  * Conferir que Sensor preenche os parâmetros;
  * Confirmar payload correto do webhook N8n.

4. **Workflows consumindo recursos em excesso**

* Sintoma:

  * Alto consumo de CPU/RAM no namespace `argocd`.
* Correção:

  * Ajustar `resources.requests/limits` (especialmente `e2e-tests`);
  * Se necessário, definir `ResourceQuota` em `argocd`.

5. **Falhas na validação OPA**

* Sintoma:

  * Step `opa-validate` falha constantemente.
* Causas:

  * Endpoint OPA ou policy path incorretos;
  * Formato do manifesto não aceito.
* Correção:

  * Alinhar endpoint/policies com M05;
  * Ajustar conversão YAML/JSON conforme política.

6. **Chave SSH estática no deployment N8n**

* Sintoma:

  * Chave Git embutida em env/ConfigMap ou código do fluxo.
* Correção:

  * Migrar chave para Vault;
  * Implementar obtenção dinâmica no fluxo;
  * Rotacionar chave antiga.

7. **Topologia A usada como produção**

* Problema:

  * Demo com Docker usada em cliente real.
* Correção:

  * Topologia A apenas para testes locais;
  * Produção somente em Topologia B.

---

## Onde salvar

1. **Contrato / Desenvolvimento**

* Repositório: `appgear-contracts` (ou equivalente).
* Arquivo:

  * `Módulo 14 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD) v0.1.md`;
* Referenciar em:

  * `1 - Desenvolvimento v0.md`, seção M14.

2. **GitOps Core**

* Repositório: `appgear-gitops-core`;
* Estrutura:

```text
apps/core/gitops/
  kustomization.yaml        # inclui pipeline-templates e argo-events
  pipeline-templates/
    kustomization.yaml
    workflowtemplate-ai-first.yaml
  argo-events/
    kustomization.yaml
    eventsource-ai-first.yaml
    sensor-ai-first.yaml
```

3. **GitOps Workspaces**

* Repositório: `appgear-gitops-workspaces`;
* Estrutura:

```text
clusters/ag-br-core-dev/
  kustomization.yaml

workspaces/
  .templates/
    workspace-structure.yaml
  ws-<workspace_id>/
    k8s/
      vcluster/
        kustomization.yaml
        # manifests gerados pelo N8n
    sql/
      0001-init.sql
    docs/
      README.md
```

4. **Fluxos N8n**

* Repositório sugerido: `appgear-n8n-flows`;
* Estrutura:

```text
flows/
  ai-first/
    ai-first-generate-workspace.json   # export do fluxo N8n
```

5. **Topologia A (demo)**

* Host de desenvolvimento:

```text
/opt/appgear/ai-first/docker-compose.ai-first.yml
/opt/appgear/ai-first/data/n8n/
```

---

## Dependências entre os módulos

A posição do **Módulo 14 – Pipelines de Geração AI-First** na arquitetura da AppGear é:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * Pré-requisito direto.
  * Define:

    * convenções de nomes (`core-*`, `addon-*`);
    * forma canônica (`*.md`);
    * labels `appgear.io/*` (incluindo `tenant-id`, `workspace-id`);
    * práticas de FinOps aplicadas a pods de pipeline.

* **Módulo 01 – GitOps e Argo CD (App-of-Apps)**

  * Pré-requisito direto.
  * Fornece:

    * Argo CD como orquestrador GitOps;
    * padrões de `AppProject`, `Application`, `ApplicationSet` usados pelos pipelines para disparar reconciliações.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * Pré-requisito funcional.
  * Fornece:

    * malha de serviço com mTLS STRICT usada por Argo, N8n e serviços Core;
    * borda segura para webhooks (quando expostos externamente).

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * Dependência mútua.
  * M03:

    * coleta métricas e custos dos pipelines AI-First;
  * M14:

    * garante labels de tenant/workspace nos pods;
    * define resources para steps de workflow, tornando custos previsíveis.

* **Módulo 04 – Armazenamento e Bancos Core**

  * Pré-requisito técnico.
  * Fornece:

    * storage para logs/artefatos gerados por pipelines;
    * bancos/filas que os pipelines podem consumir (ex.: dados de teste, filas de eventos).

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * Pré-requisito direto.
  * Fornece:

    * Vault para segredos de Git e demais credenciais AI-First;
    * OPA para validação de manifests antes de irem para Argo CD;
    * Falco monitorando pods de pipeline;
    * OpenFGA para autorização sobre quem pode acionar pipelines.

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * Pré-requisito funcional.
  * Fornece:

    * identidade dos usuários que disparam o AI-First (via Portal/Backstage);
    * atributos de `tenant_id` e `workspace_id` usados no fluxo N8n e repassados ao pipeline.

* **Módulo 07 – Portal Backstage e Integrações Core**

  * Consumidor direto.
  * Fornece:

    * UI para que usuários definam requisitos de workspace e disparem geração AI-First;
    * integração com N8n (webhook) para iniciar o fluxo.

* **Módulo 08 – Serviços Core (LiteLLM, Flowise, N8n, etc.)**

  * Pré-requisito direto.
  * Fornece:

    * N8n como motor de orquestração AI-First;
    * Flowise/LiteLLM como camadas de IA usadas para projetar o ecossistema.

* **Módulos 09, 10, 11, 12 – Suítes Factory, Brain, Operations, Guardian**

  * Consumidores indiretos.
  * Fornecem:

    * building blocks que o AI-First pode instanciar/configurar em cada workspace;
  * Dependem de M14 para:

    * ter pipelines que criem/ajustem suas configurações por workspace via GitOps.

* **Módulo 13 – Workspaces, vCluster e modelo por cliente**

  * Pré-requisito direto.
  * Fornece:

    * modelo de workspaces/vClusters descobertos via `appgear-gitops-workspaces`;
    * ApplicationSet que aplica manifests gerados pelo AI-First.
  * M14:

    * produz a estrutura que esse ApplicationSet consome.

* **Módulo 14 – Pipelines de Geração AI-First (este módulo)**

  * Depende de:

    * **M00, M01, M02, M03, M04, M05, M06, M07, M08, M13**;
  * Entrega:

    * o mecanismo AI-First que converte requisitos de negócio em mudanças GitOps por workspace, com segurança, FinOps e validação automatizada.

Em fluxo:

**M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → (M09–M12 Suítes) → M13 → M14 → (Pipelines avançados, Billing, PWA multi-workspace, etc.)**

Sem o Módulo 14, a AppGear teria workspaces e vClusters (M13), mas não teria um caminho automatizado, IA-assistido e GitOps-compliant para evoluir esses ambientes a partir de requisitos de produto/negócio.
