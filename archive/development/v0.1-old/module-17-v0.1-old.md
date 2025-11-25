# Módulo 17 – Políticas Operacionais e Resiliência

Versão: v0.1

### Premissas padrão (v0.1)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Define como tudo “liga e se mantém de pé”: ordem de boot (Sync Waves), initContainers de espera por dependências, auto-reload de config (Stakater Reloader) e alertas de dependências críticas (PrometheusRule).
Garante que a plataforma se comporte bem em boot, rotação de segredos e falhas de infraestrutura, reduzindo CrashLoopBackOff e incidentes difíceis de diagnosticar.

---

## O que é

O **Módulo 17 – Políticas Operacionais e Resiliência** define como a AppGear orquestra o **comportamento operacional** da plataforma na **Topologia B (Kubernetes)**, padronizando:

* **Ordem de boot** dos componentes via **Sync Waves do Argo CD**.
* **Espera por dependências** (bancos, serviços core) via **Init Containers**.
* **Auto-healing de configuração** com **Stakater Reloader** (reinicio automático de pods quando Secrets/ConfigMaps mudam).
* **Alertas de dependências críticas** via **PrometheusRule** (Prometheus Operator).

Foca em:

* Boot inicial do cluster.
* Recuperação após falhas de infraestrutura.
* Rotação de segredos/certificados.
* Detecção precoce de indisponibilidade de componentes Core (Postgres, Keycloak, etc.).

---

## Por que

### 1. Evitar CrashLoopBackOff em boot

Sem uma ordem de subida clara e sem espera por dependências:

* Serviços sobem antes de seus bancos/core:

  * Ex.: **Keycloak** sobe antes de **core-postgres** → falhas de conexão → `CrashLoopBackOff`.
  * Ex.: **Backstage** sobe antes de **Keycloak** → falhas de SSO/Bootstrap.
* Com Sync Waves:

  * Storage e bancos sobem primeiro.
  * Identidade/segurança sobem sobre infra estável.
  * Portais/Suítes sobem por último.

### 2. Automatizar Day 2 (rotação de segredos/certificados)

* Segredos geridos por Vault (M05) mudam periodicamente.
* Sem automação, cada rotação exigiria restart manual de pods.
* **Stakater Reloader**:

  * Observa mudanças em Secrets/ConfigMaps.
  * Trigga **rolling updates** automáticos em Deployments anotados.

### 3. Aumentar resiliência a atrasos de infraestrutura

* Em atrasos de Ceph, nós de K8s ou rede, bancos podem demorar a ficar prontos.
* Init Containers:

  * Deixam o pod em estado `Init` até a dependência responder.
  * Evitam loops de falha e CrashLoopBackOff desnecessários.

### 4. Visibilidade de dependências críticas

* Sem alertas claros, queda de **core-postgres** aparece como:

  * Erros espalhados (Keycloak, Backstage, Flowise, Directus, etc.).
* Com **PrometheusRule**:

  * Um alerta “Core Postgres Down” indica causa raiz.
  * Alertmanager (M03) notifica SRE/DevOps em Slack, e-mail, etc.

### 5. Padronizar comportamento operacional entre os módulos

Este módulo garante que **M01–M16**:

* Respeitem a mesma ordem de boot.
* Usem o mesmo padrão de espera por dependências.
* Reajam de forma homogênea a mudanças de Secrets/ConfigMaps.
* Exponham estados críticos como alertas observáveis com labels FinOps (`appgear.io/*`).

---

## Pré-requisitos

### Documentação

* `0 - Contrato v0.md` – contrato de arquitetura da AppGear. 
* `1 - Desenvolvimento v0.md` contendo a descrição dos módulos M00–M16.

### Módulos prévios (Topologia B – Kubernetes)

No cluster `ag-<regiao>-core-<env>`:

* **M00 – Fundamentos / Topologia**

  * Topologia B (Kubernetes) definida e adotada.
* **M01 – GitOps (Argo CD, AppSets)**

  * Argo CD instalado como App-of-Apps.
  * Applications Core/Suítes versionadas em Git.
* **M02 – Borda e Cadeia de Proteção**

  * Traefik, Coraza, Kong, Istio operacionais.
* **M03 – Observabilidade e FinOps**

  * Prometheus Operator (CRDs `PrometheusRule`, `ServiceMonitor`).
  * Prometheus, Loki, Grafana provisionados.
* **M04 – Armazenamento e Bancos Core**

  * Ceph configurado.
  * StatefulSets: `core-postgres`, `core-redis`, `core-qdrant`, `core-redpanda`.
* **M05 – Segurança e Segredos**

  * Vault como SSoT de segredos.
  * Padrão de injeção (Vault Agent / ExternalSecrets) aplicado.
* **M06 – Identidade e SSO**

  * `core-keycloak` implantado via Argo CD.
* **M07–M12**

  * Backstage, Flowise, N8n, Directus, Appsmith, Metabase e Suítes (Factory, Brain, Operations, Guardian) declaradas como Applications, ainda que em v0.

### Ferramentas

* Acesso ao cluster (kubeconfig).
* `kubectl`, `kustomize`, `argocd`, `git`.
* Acesso de escrita em:

  * `appgear-gitops-core` (infra/core).
  * `appgear-gitops-suites` (suítes/apps).
  * `appgear-contracts` (documentação).

---

## Como fazer (comandos)

### Módulo 17.1 – Definir a Ordem de Subida (Sync Waves – Argo CD)

#### O que é

Padroniza as **Sync Waves** das Applications do Argo CD, garantindo que componentes críticos subam na ordem correta.

#### Mapa de waves AppGear v0

* **Wave -10** – Namespaces, CRDs, quotas.
* **Wave -5** – Storage / CSI (Ceph, drivers).
* **Wave -4** – Segurança/Segredos (Vault, Cert-Manager).
* **Wave -3** – Bancos Core (`core-postgres`, `core-redis`, `core-qdrant`, `core-redpanda`).
* **Wave -2** – Identidade/Autorização (`core-keycloak`, OPA, OpenFGA).
* **Wave -1** – Borda e Infra de Aplicação (Traefik, Coraza, Kong, Istio, LiteLLM).
* **Wave 0** – Portais/Suítes/Apps (Backstage, Flowise, N8n, Directus, Appsmith, Metabase, Suítes).

#### Como fazer (comandos)

No repositório Core:

```bash
cd appgear-gitops-core
```

Exemplo de **Application** para Keycloak (wave -2):

```yaml
# apps/core/identity/core-keycloak-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-keycloak
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io/topology: B
    appgear.io/module: "mod06-identity-sso"
    appgear.io/tenant-id: global
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
    appgear.io/contract-version: "v0.1"
spec:
  project: appgear-core
  source:
    repoURL: https://git.example.com/appgear-gitops-core.git
    targetRevision: main
    path: apps/core/identity/keycloak
  destination:
    server: https://kubernetes.default.svc
    namespace: identity
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Aplicar o mesmo padrão:

* `core-ceph` – `sync-wave: "-5"`.
* `core-vault` – `sync-wave: "-4"`.
* `core-postgres`, `core-redis`, `core-qdrant`, `core-redpanda` – `sync-wave: "-3"`.
* `core-opa`, `core-openfga` – `sync-wave: "-2"`.
* `core-istio`, `core-traefik`, `core-coraza`, `core-kong`, `core-litelm` – `sync-wave: "-1"`.

Para Suítes (no repo de suítes):

```bash
cd appgear-gitops-suites
# Em cada Application das suítes
```

Exemplo de Application de Backstage (wave 0):

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

---

### Módulo 17.2 – Init Containers de Espera por Dependências

#### O que é

Padrão de **Init Containers** que aguardam bancos/serviços Core antes dos containers principais subirem.

#### Padrão

* Imagem leve (`busybox`, `alpine`).
* Script simples `until nc -z host port`.
* `resources.limits` sempre configurados (FinOps).

#### Como fazer (comandos)

Exemplo: **Keycloak aguardando Postgres**:

```yaml
# apps/core/identity/keycloak/deployment.yaml (trecho relevante)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-keycloak
  namespace: identity
  labels:
    app.kubernetes.io/name: core-keycloak
    appgear.io/tier: core
    appgear.io/topology: B
    appgear.io/module: "mod06-identity-sso"
    appgear.io/tenant-id: global
spec:
  template:
    metadata:
      labels:
        app.kubernetes.io/name: core-keycloak
        appgear.io/tier: core
        appgear.io/topology: B
        appgear.io/module: "mod06-identity-sso"
        appgear.io/tenant-id: global
    spec:
      initContainers:
        - name: wait-for-postgres
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              until nc -z core-postgres.appgear-core.svc.cluster.local 5432; do
                echo "Aguardando Postgres core-postgres:5432...";
                sleep 2;
              done
          resources:
            limits:
              cpu: "50m"
              memory: "32Mi"
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:latest
          # (... restante inalterado ...)
```

Repetir o padrão (ajustando host/porta) em:

* **Directus** → `core-postgres.appgear-core.svc.cluster.local:5432`.
* **Flowise** → Postgres/Redis/Qdrant, conforme config.
* **Backstage** → Postgres, e opcionalmente checagens adicionais.
* Serviços de Suítes que dependam de bancos/serviços Core.

Opcional: usar patches Kustomize reutilizáveis (`patchesStrategicMerge`) para não duplicar YAML.

---

### Módulo 17.3 – Instalar e Configurar Stakater Reloader

#### O que é

Instala o **Stakater Reloader** via Argo CD, para restart automático de Deployments quando Secrets/ConfigMaps mudam.

#### Como fazer (comandos)

No Core:

```bash
cd appgear-gitops-core
mkdir -p apps/core/reloader
```

`apps/core/reloader/application-reloader.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: core-reloader
  namespace: argocd
  labels:
    app.kubernetes.io/name: core-reloader
    app.kubernetes.io/part-of: appgear
    appgear.io/tier: core
    appgear.io.topology: B
    appgear.io.module: "mod17-ops-resilience"
    appgear.io.tenant-id: global
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
    appgear.io.contract-version: "v0.1"
spec:
  project: appgear-core
  source:
    repoURL: https://stakater.github.io/stakater-charts
    chart: reloader
    targetRevision: 1.0.0          # ajustar para versão validada
    helm:
      values: |
        reloader:
          reloadStrategy: annotations
  destination:
    server: https://kubernetes.default.svc
    namespace: reloader
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

`apps/core/reloader/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - application-reloader.yaml
```

Incluir `apps/core/reloader` no App-of-Apps (`clusters/ag-<regiao>-core-<env>/apps-core.yaml`) como mais um Application.

#### Anotar Deployments para auto-reload

Adicionar em cada Deployment que depende de Secrets/ConfigMaps rotativos:

```yaml
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
```

Exemplo (Keycloak):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-keycloak
  namespace: identity
  annotations:
    reloader.stakater.com/auto: "true"
  labels:
    app.kubernetes.io/name: core-keycloak
    appgear.io/tier: core
    appgear.io.topology: B
    appgear.io.module: "mod06-identity-sso"
    appgear.io.tenant-id: global
```

Aplicar em:

* Keycloak, Argo CD (se segredos rotativos), Istio ingress/egress com certificados, Backstage, Flowise, N8n, Directus, Appsmith, Metabase, serviços de Suítes, etc.

---

### Módulo 17.4 – PrometheusRule de Dependências Críticas

#### O que é

Regras de alerta para **dependências Core** (ex.: Postgres), integradas ao Prometheus Operator.

#### Como fazer (comandos)

No Core:

```bash
cd appgear-gitops-core
mkdir -p apps/core/observability/rules
```

`apps/core/observability/rules/dependency-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: critical-dependencies
  namespace: observability
  labels:
    appgear.io/tenant-id: global
    appgear.io/tier: core
    appgear.io.topology: B
    appgear.io.module: "mod17-ops-resilience"
spec:
  groups:
    - name: appgear-core
      rules:
        - alert: CriticalDependencyDown
          expr: kube_statefulset_status_replicas_ready{statefulset="core-postgres"} == 0
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "Postgres Core está indisponível"
            description: "Todos os serviços dependentes (Keycloak, Flowise, Directus, Backstage, Suítes) serão impactados."
```

Adicionar a regra no Kustomize de observabilidade:

```yaml
# apps/core/observability/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - prometheus-operator.yaml
  - rules/dependency-alerts.yaml
  # outros recursos de observabilidade
```

> Extensões futuras: regras adicionais para Redis, Qdrant, Redpanda, Keycloak, etc.

---

## Como verificar

### 1. Sync Waves e ordem de boot

* Listar Applications no Argo CD:

```bash
argocd app list
```

* Verificar a annotation de waves:

```bash
kubectl -n argocd get applications.argoproj.io core-keycloak -o yaml | grep sync-wave -n
```

* Em um boot (ou simulação), checar:

  * `core-postgres` está `Healthy` antes de `core-keycloak`.
  * Backstage, Flowise, Directus, etc., só são sincronizados após os Core.

### 2. Init Containers em ação

* Simular Postgres down:

```bash
kubectl scale statefulset core-postgres -n appgear-core --replicas=0
```

* Reiniciar Keycloak:

```bash
kubectl rollout restart deploy core-keycloak -n identity
kubectl get pods -n identity
kubectl describe pod <pod-keycloak> -n identity
```

* Esperado:

  * Pod em `Init:0/1` com logs “Aguardando Postgres…”.
  * Não entrar em `CrashLoopBackOff`.

* Restaurar Postgres:

```bash
kubectl scale statefulset core-postgres -n appgear-core --replicas=1
```

* Verificar que Keycloak passa para `Running`.

### 3. Reloader

* Identificar Secret usado por Deployment anotado com `reloader.stakater.com/auto: "true"`.

* Alterar Secret (simulação de rotação):

```bash
kubectl edit secret core-keycloak-db-credentials -n identity
```

* Observar rollout:

```bash
kubectl get rs -n identity | grep core-keycloak
kubectl get pods -n identity -w
```

* Esperado:

  * Novo ReplicaSet criado.
  * Pods antigos finalizados, novos subindo (rolling update).

### 4. PrometheusRule e alertas

* Ver PrometheusRule:

```bash
kubectl get prometheusrule -n observability critical-dependencies -o yaml
```

* Simular indisponibilidade do Postgres (como em 2).

* No Prometheus/Alertmanager:

  * Verificar alerta `CriticalDependencyDown` ativo após ~2 minutos.
  * Confirmar entrega de notificações nos canais configurados (Slack, e-mail).

---

## Erros comuns

1. **Sync Waves ausentes ou incorretas**

* Sintoma:

  * Serviços sobem antes das bases Core, gerando erros em cascata.
* Correção:

  * Revisar `argocd.argoproj.io/sync-wave` em todas Applications Core e Suítes conforme mapa (-10 a 0).

2. **Host/porta errados nos Init Containers**

* Sintoma:

  * Init Container preso indefinidamente em “Aguardando…”.
* Correção:

  * Validar FQDN (`svc.namespace.svc.cluster.local`) e porta do serviço.

3. **Init Containers sem `resources.limits`**

* Sintoma:

  * Violação de políticas de recursos / instabilidade em stress.
* Correção:

  * Sempre definir `limits` (ex.: 50m / 32Mi).

4. **Reloader instalado, mas Deployments sem annotation**

* Sintoma:

  * Rotação de segredos não gera rolling update.
* Correção:

  * Garantir `reloader.stakater.com/auto: "true"` nos Deployments que dependem de Secrets/ConfigMaps rotativos.

5. **PrometheusRule sem labels AppGear**

* Sintoma:

  * Dificuldade em correlacionar alertas com módulo/tenant.
* Correção:

  * Incluir labels `appgear.io/tenant-id`, `appgear.io/tier`, `appgear.io/topology`, `appgear.io/module`.

6. **Uso do módulo na Topologia A (Docker)**

* Sintoma:

  * Tentativa de usar Sync Waves, Reloader, PrometheusRule em ambiente apenas Docker.
* Correção:

  * Este módulo é exclusivo para Topologia B (Kubernetes). Topologia A é apenas para desenvolvimento simples.

7. **Loop infinito de espera (refinamento futuro)**

* v0.1 aceita `until nc -z` sem timeout.
* Para versões futuras:

  * Implementar timeout total para evitar espera infinita em falhas permanentes.

---

## Onde salvar

1. **Documento de módulo**

* Repositório: `appgear-contracts`.
* Arquivo sugerido:

  * `Módulo 17 – Políticas Operacionais e Resiliência v0.1.md`.

2. **Documento unificado de desenvolvimento**

* Arquivo: `1 - Desenvolvimento v0.md`.
* Adicionar seção no índice:

```md
### Módulo 17 – Políticas Operacionais e Resiliência (Orquestração de Boot, Auto-Healing, Dependências e Alertas)
```

3. **Repositórios GitOps**

* `appgear-gitops-core`:

  * Ajuste de Sync Waves nas Applications Core (`apps/core/*`).
  * `apps/core/reloader/` – Application do Reloader.
  * `apps/core/observability/rules/dependency-alerts.yaml` – PrometheusRule.
* `appgear-gitops-suites`:

  * Ajuste de Sync Waves (wave 0) nas Applications das Suítes.
  * Init Containers de espera por dependências conforme necessidade.

---

## Dependências entre os módulos

A posição do **Módulo 17 – Políticas Operacionais e Resiliência** na arquitetura AppGear é:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * Pré-requisito direto.
  * Define:

    * padrão de arquivos (`*.md`);
    * nomenclaturas (clusters, módulos, apps);
    * labels `appgear.io/*` usadas para FinOps e observabilidade em todos os manifests deste módulo.

* **Módulo 01 – GitOps e Argo CD (App-of-Apps)**

  * Pré-requisito direto.
  * Fornece:

    * Argo CD como orquestrador;
    * modelo de Applications/AppProjects;
    * base para uso de **Sync Waves**, que são o principal mecanismo deste módulo.

* **Módulo 02 – Borda e Cadeia de Proteção (Traefik, Coraza, Kong, Istio)**

  * Dependência operacional.
  * Serviços de borda entram em waves específicas (-1), e seu comportamento em boot é governado pelas políticas deste módulo.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Loki, Grafana, OpenCost, Lago)**

  * Dependência mútua.
  * M03:

    * disponibiliza Prometheus Operator e stack de observabilidade para que as PrometheusRules funcionem;
  * M17:

    * define as regras de alerta de dependências críticas;
    * garante labels e padrões de recursos que facilitam FinOps e diagnóstico.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, Redpanda)**

  * Pré-requisito técnico.
  * Fornece:

    * bancos/infra crítica que são o alvo das políticas de ordem de boot e dos Init Containers;
    * principal foco das PrometheusRules de dependências críticas.

* **Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)**

  * Dependência operacional.
  * Segredos/certificados rotativos vindos de Vault são o principal motivador de uso do Reloader.
  * M17 garante que mudanças de segredos sejam absorvidas automaticamente pelos serviços.

* **Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)**

  * Consumidor direto.
  * `core-keycloak`:

    * depende de Postgres (M04);
    * é protegido por Init Container de espera;
    * é sensível a rotação de segredos (Reloader);
    * aparece como dependência crítica em futuros alertas.

* **Módulos 07–12 – Portal Backstage e Suítes (Factory, Brain, Operations, Guardian, Apps Core)**

  * Consumidores diretos.
  * Portais e Suítes:

    * entram na wave 0 (boot após Core);
    * usam Init Containers para aguardar bancos/core;
    * são reiniciados automaticamente ao rotacionar ConfigMaps/Secrets.

* **Módulo 13 – Workspaces, vCluster e modelo por cliente**

  * Dependência indireta.
  * Workspaces/vClusters:

    * podem seguir padrões de boot/espera equivalentes dentro de cada vCluster;
    * dependem de Core estável, cuja resiliência é reforçada por M17.

* **Módulo 14 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD)**

  * Consumidor indireto.
  * Pipelines:

    * dependem de componentes Core e Suítes estáveis;
    * podem usar alertas de dependência para orquestrar respostas automáticas a falhas.

* **Módulo 15 – Continuidade de Negócios (DR & Backup Global)**

  * Dependência complementar.
  * M15 cuida de **DR/Backup**;
  * M17 cuida de **boot/resiliência operacional**:

    * após restore de backups, a ordem de boot e espera por dependências é fundamental.

* **Módulo 16 – Conectividade Híbrida (VPN, Túneis, Acesso Remoto)**

  * Consumidor indireto.
  * Componentes de conectividade também podem adotar Init Containers / Sync Waves para subir após infraestrutura básica.

* **Módulo 17 – Políticas Operacionais e Resiliência (este módulo)**

  * Depende principalmente de:

    * **M00, M01, M03, M04, M05, M06**;
  * Entrega:

    * a camada transversal de **orquestração de boot, auto-healing de config e alertas de dependência**, que aumenta a robustez da AppGear em produção.

Fluxo simplificado:

**M00 → M01 → (M02–M06) → M03/M04 → (M07–M16) → M17**

Sem o **Módulo 17**, a AppGear teria todos os componentes Core e Suítes, mas com boot desordenado, pouca automação na rotação de segredos e baixa visibilidade de dependências críticas, aumentando a probabilidade de incidentes difíceis de diagnosticar e resolver.
