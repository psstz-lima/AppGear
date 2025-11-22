Segue o módulo reescrito em **Markdown**, no padrão canônico dos demais módulos, pronto para ser salvo como **`Módulo 17 v0.1.md`** e/ou incorporado em `1 - Desenvolvimento v0.md`.

---

# Módulo 17 – Políticas Operacionais e Resiliência (v0.1)

(Orquestração de Boot, Auto-Healing, Dependências e Alertas)

---

## 1. O que é

Este módulo define as **Políticas Operacionais e de Resiliência** da plataforma AppGear na Topologia B (Kubernetes), padronizando:

* A **ordem de subida (boot)** dos componentes via **Argo CD Sync Waves**.
* A **espera inteligente** por dependências (ex.: banco de dados) via **Init Containers**.
* O **auto-healing de configuração** via **Stakater Reloader** (reinício automático de pods quando segredos/configmaps mudam).
* As **regras de alerta de dependências críticas** via **PrometheusRule** do Prometheus Operator.

Este módulo não introduz novos serviços de negócio, mas **governa o comportamento operacional** dos serviços definidos em M01–M16 durante:

* Boot inicial do cluster.
* Recuperação após falhas de infraestrutura.
* Rotação de segredos e certificados.
* Detecção de indisponibilidade de componentes Core.

---

## 2. Por que

### 2.1 Evitar CrashLoopBackOff em boot

Sem ordem de boot e sem espera adequada por dependências:

* Serviços tentam subir antes de seus bancos ou serviços-Core.
* Exemplo típico:

  * **Keycloak** sobe antes do **core-postgres** → falhas repetidas de conexão → `CrashLoopBackOff`.
  * **Backstage** sobe antes do **Keycloak** → falhas de SSO e de bootstrap.

As **Sync Waves** garantem que:

1. Storage e bancos subam antes.
2. Identidade/segurança apliquem as políticas sobre infraestrutura já estável.
3. Portais e suítes só subam quando a base estiver pronta.

### 2.2 Automatizar Day 2 (rotação de segredos e certificados)

* Senhas, tokens e certificados geridos pelo Vault (M05) mudam periodicamente.
* Sem um mecanismo automatizado, cada rotação exigiria:

  * Atualizar Secret/ConfigMap via GitOps ou injeção.
  * **Reiniciar manualmente** todos os pods afetados.

O **Stakater Reloader** observa mudanças em ConfigMaps/Secrets e dispara **rolling updates** automáticos nos Deployments anotados, padronizando o comportamento de rotação.

### 2.3 Aumentar resiliência a falhas de infraestrutura

* Em caso de atrasos em **Ceph**, nós de Kubernetes ou rede, bancos podem demorar a ficar prontos.
* Init Containers de espera permitem que os serviços:

  * Fiquem em estado `Init` aguardando a dependência de forma controlada.
  * Não entrem em loops de falha sem sentido.

### 2.4 Dar visibilidade de dependências críticas

* Sem alertas explícitos, a queda de **core-postgres** se manifesta como:

  * Erros em Keycloak, Backstage, Flowise, Directus, etc., espalhados.
* Com **PrometheusRule** para dependências críticas:

  * Um alerta único “Core Postgres Down” deixa claro a causa raiz.
  * Integrações com Alertmanager (M03) podem notificar SRE/DevOps por Slack, e-mail, etc.

### 2.5 Padronizar comportamento entre todos os módulos

Este módulo garante que **M01–M16**:

* Respeitem uma ordem de boot coerente.
* Tenham o mesmo padrão de espera por dependências.
* Reajam da mesma forma a mudanças de configuração (Reloader).
* Exponham estados críticos como alertas observáveis, com labels FinOps (tenant-id, tier, módulo).

---

## 3. Pré-requisitos

### 3.1 Documentação

* `0 - Contrato v0.md` – Contrato de Arquitetura AppGear.
* `1 - Desenvolvimento v0.md` – Documento de desenvolvimento contendo M00–M16.

### 3.2 Infraestrutura e módulos anteriores

Na **Topologia B (Kubernetes)**, é esperado:

* **M00 – Fundamentos de Topologia**

  * Definição clara da Topologia B (cluster Kubernetes) em produção.
* **M01 – GitOps (Argo CD, AppSets)**

  * Argo CD instalado e operando como “App-of-Apps”.
  * Applications para Core e Suítes versionados em repositórios Git.
* **M02 – Borda e Cadeia de Proteção**

  * Traefik, Coraza, Kong, Istio implantados (cadeia Traefik → Coraza → Kong → Istio).
* **M03 – Observabilidade e FinOps**

  * Prometheus Operator instalado (CRDs `PrometheusRule`, `ServiceMonitor`).
  * Stack de logs/métricas básica já funcional (Prometheus, Loki, Grafana).
* **M04 – Armazenamento e Bancos Core**

  * Ceph configurado e StorageClasses prontos.
  * StatefulSets core de: `core-postgres`, `core-redis`, `core-qdrant`, `core-redpanda`.
* **M05 – Segurança e Segredos**

  * Vault operando como SSoT de segredos.
  * Estratégia de injeção (Vault Agent/ExternalSecret) já em uso com Kubernetes Secrets.
* **M06 – Identidade e SSO**

  * `core-keycloak` implantado via Argo CD.
* **M07–M12 – Portal & Suítes**

  * Backstage e Suítes (Factory, Brain, Operations, Guardian, Apps Core) declaradas como Applications no GitOps, mesmo que ainda em v0.

### 3.3 Ferramentas

* Acesso ao cluster Kubernetes (kubeconfig).
* `kubectl`, `kustomize`, `argocd`, `git` instalados na estação de operação.
* Permissão de escrita nos repositórios Git:

  * `webapp-ia-gitops-core` (infra/core).
  * `webapp-ia-gitops-suites` (aplicações/suítes).
  * `appgear-contracts` (documentação).

---

## 4. Como fazer (comandos)

> Estrutura do módulo:
>
> 1. Definir **Sync Waves** por Application (Argo CD).
> 2. Implementar **Init Containers** de espera por dependências.
> 3. Instalar e configurar **Stakater Reloader**.
> 4. Criar **PrometheusRule** para dependências críticas.

### 4.1 Definir a Ordem de Subida (Sync Waves – Argo CD)

#### 4.1.1 Mapa de ondas AppGear v0

* **Wave -10** – Namespaces, CRDs, quotas

  * Base de cluster, CRDs de Argo CD, Prometheus Operator, etc.
* **Wave -5** – Storage / CSI

  * Ceph e demais provedores de armazenamento do M04.
* **Wave -4** – Segurança/Segredos

  * Vault, Cert-Manager, políticas de PKI.
* **Wave -3** – Bancos e Dados Core

  * `core-postgres`, `core-redis`, `core-qdrant`, `core-redpanda`.
* **Wave -2** – Identidade e Segurança Aplicacional

  * `core-keycloak`, OPA, OpenFGA, componentes de autorização.
* **Wave -1** – Borda e Infra de Aplicação

  * Traefik, Coraza, Kong, Istio, LiteLLM (gateway de IA).
* **Wave 0** – Portais, Suítes e Apps

  * Backstage, Flowise, N8n, Directus, Appsmith, Metabase, Suítes Factory/Brain/Ops/Guardian.

#### 4.1.2 Ajustar Applications Core com Sync Waves

No repositório GitOps Core:

```bash
cd webapp-ia-gitops-core
```

Exemplo de Application para **Keycloak** (wave -2):

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
    appgear.io/contract-version: "v0"
spec:
  project: appgear-core
  source:
    repoURL: https://git.example.com/webapp-ia-gitops-core.git
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

Aplicar o mesmo padrão para:

* `core-ceph` – `argocd.argoproj.io/sync-wave: "-5"`.
* `core-vault` – `-4`.
* `core-postgres`, `core-redis`, `core-qdrant`, `core-redpanda` – `-3`.
* `core-opa`, `core-openfga` – `-2`.
* `core-istio`, `core-traefik`, `core-coraza`, `core-kong`, `core-litelm` – `-1`.

Nos repositórios de Suítes (`webapp-ia-gitops-suites`), aplicar **wave 0** para Backstage, Flowise, N8n, Directus, Appsmith, Metabase e demais Suítes.

```bash
cd webapp-ia-gitops-suites
# Ajustar annotations argocd.argoproj.io/sync-wave: "0" em cada Application de suíte
```

### 4.2 Implementar Init Containers de Espera por Dependências

#### 4.2.1 Padrão de espera

Para cada serviço dependente de bancos/serviços Core, adicionar Init Container do tipo:

* Imagem leve (`busybox`, `alpine`, etc.).
* Comando `until nc -z <host> <port>`.
* Pequenos limits de recursos, alinhados com FinOps.

> Observação: o uso de `until nc -z` é aceitável para v0.1.
> Um timeout total (para não ficar em loop indefinido em caso de falha permanente) é um **refinamento sugerido para v1**, não obrigatório neste módulo.

#### 4.2.2 Exemplo: Keycloak aguardando Postgres

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
          # (...)
```

#### 4.2.3 Aplicar a outros serviços

Repetir o padrão (ajustando host/porta) em:

* **Directus** → `core-postgres.appgear-core.svc.cluster.local:5432`.
* **Flowise** → Postgres/Redis/Qdrant conforme configuração.
* **Backstage** → Postgres (se aplicável) e, se necessário, checagens adicionais (Keycloak disponível, etc.).
* Serviços das Suítes (Factory, Brain, Operations, Guardian) que dependam diretamente de bancos ou outros componentes Core.

Opcionalmente, criar **patches Kustomize** reutilizáveis, como:

```yaml
# patches/wait-for-postgres.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: PLACEHOLDER
spec:
  template:
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
```

E aplicar via `patchesStrategicMerge` em cada kustomization.

### 4.3 Instalar e Configurar Stakater Reloader

#### 4.3.1 Application do Reloader via Argo CD

No repositório Core:

```bash
cd webapp-ia-gitops-core
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
    appgear.io/topology: B
    appgear.io/module: "mod17-ops-resilience"
    appgear.io/tenant-id: global
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
    appgear.io/contract-version: "v0"
spec:
  project: appgear-core
  source:
    repoURL: https://stakater.github.io/stakater-charts
    chart: reloader
    targetRevision: 1.0.0        # ajustar para versão validada
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

Adicionar o caminho `apps/core/reloader` ao `apps-core.yaml` ou equivalente no “App-of-Apps” Core para que Argo CD passe a gerenciar o Reloader.

#### 4.3.2 Anotar Deployments que devem ser recarregados

Em todo Deployment que depende de Secrets/ConfigMaps rotativos (principalmente via Vault), adicionar:

```yaml
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
```

Exemplo (Keycloak):

```yaml
# trecho em apps/core/identity/keycloak/deployment.yaml
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
    appgear.io/topology: B
    appgear.io/module: "mod06-identity-sso"
    appgear.io/tenant-id: global
```

Aplicar em:

* `core-keycloak`, `core-argocd` (quando usar segredos rotativos), `core-istio-ingressgateway` (certificados), etc.
* Backstage, Flowise, N8n, Directus, Appsmith, Metabase, serviços das Suítes, desde que dependam de Secrets/ConfigMaps geridos pelo Vault.

### 4.4 Criar PrometheusRule de Dependências Críticas

No repositório Core:

```bash
cd webapp-ia-gitops-core
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
    appgear.io/topology: B
    appgear.io/module: "mod17-ops-resilience"
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
            description: "Todos os serviços dependentes (Keycloak, Flowise, Directus, Backstage) serão impactados."
```

Se necessário, estender com outras regras:

* Redis Core indisponível.
* Qdrant Core indisponível.
* Redpanda indisponível.
* Keycloak indisponível (quando for dependência explícita de portais/Suítes).

Adicionar esse arquivo ao kustomization de observabilidade, por exemplo:

```yaml
# apps/core/observability/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - prometheus-operator.yaml
  - rules/dependency-alerts.yaml
  # outros manifests de observabilidade
```

---

## 5. Como verificar

### 5.1 Verificar ordem de boot (Sync Waves)

1. Validar waves no Argo CD:

   ```bash
   argocd app list
   # conferir coluna SYNC STATUS e anotações via describe
   kubectl -n argocd get applications.argoproj.io core-keycloak -o yaml | grep sync-wave -n
   ```

2. Simular um boot ordenado:

   * Pausar e retomar sincronização ou deletar temporariamente uma Application e deixar Argo recriá-la:

     ```bash
     argocd app delete core-keycloak --cascade=false
     argocd app sync core-keycloak
     ```

3. Observar que:

   * `core-postgres` está **Healthy** antes de `core-keycloak`.
   * Backstage, Flowise, Directus, etc. só são sincronizados depois dos Core, respeitando as waves.

### 5.2 Verificar Init Containers

1. Escalar Postgres para 0 réplicas:

   ```bash
   kubectl scale statefulset core-postgres -n appgear-core --replicas=0
   ```

2. Reiniciar Keycloak:

   ```bash
   kubectl rollout restart deploy core-keycloak -n identity
   ```

3. Verificar status do pod:

   ```bash
   kubectl get pods -n identity
   kubectl describe pod <nome-do-pod-keycloak> -n identity
   ```

   Esperado:

   * Pod em estado `Init:0/1` com logs do initContainer repetindo “Aguardando Postgres…”.
   * Não deve entrar em `CrashLoopBackOff`.

4. Restaurar Postgres:

   ```bash
   kubectl scale statefulset core-postgres -n appgear-core --replicas=1
   ```

5. Confirmar que o pod do Keycloak completa o Init Container e vai para `Running`.

### 5.3 Verificar Reloader

1. Identificar um Secret usado por um Deployment anotado com `reloader.stakater.com/auto: "true"`, por exemplo `core-keycloak-db-credentials`.

2. Alterar o Secret (simulação de rotação):

   ```bash
   kubectl edit secret core-keycloak-db-credentials -n identity
   # alterar senha mantendo formatação válida
   ```

3. Observar o Deployment:

   ```bash
   kubectl get rs -n identity | grep core-keycloak
   kubectl get pods -n identity -w
   ```

   Esperado:

   * Criação de um novo ReplicaSet.
   * Rolling update dos pods do Keycloak, sem intervenção manual.

### 5.4 Verificar PrometheusRule

1. Validar que a regra foi carregada:

   ```bash
   kubectl get prometheusrule -n observability critical-dependencies -o yaml
   ```

2. Simular indisponibilidade do core-postgres (como em 5.2 – passo 1).

3. Verificar no Prometheus/Alertmanager:

   * Alerta `CriticalDependencyDown` deve aparecer após ~2 minutos.
   * Se integração de Alertmanager estiver configurada (M03), a notificação deve chegar nos canais definidos (Slack, e-mail, etc.).

---

## 6. Erros comuns

1. **Ausência ou erro em Sync Waves**

   * Sintoma: alguns serviços sobem antes das bases Core, causando falhas em cascata.
   * Correção: revisar todas as `annotations.argocd.argoproj.io/sync-wave` nas Applications Core e Suítes e ajustar conforme mapa de ondas (-10 a 0).

2. **Host/porta incorretos nos Init Containers**

   * Sintoma: initContainer preso indefinidamente em “Aguardando…”.
   * Correção: validar FQDN do serviço (`<svc>.<namespace>.svc.cluster.local`) e porta correta do banco/serviço.

3. **Ausência de limits em Init Containers**

   * Sintoma: pods violando política de recursos ou afetando nós em situações de stress.
   * Correção: garantir sempre `resources.limits` definidos em todos os Init Containers (como no exemplo: 50m/32Mi).

4. **Reloader instalado, mas Deployments sem annotation**

   * Sintoma: rotação de segredos não aciona rolling update.
   * Correção: adicionar `reloader.stakater.com/auto: "true"` nos Deployments que dependem de Secrets/ConfigMaps rotativos.

5. **PrometheusRule sem labels FinOps**

   * Sintoma: dificuldade em rastrear alertas por módulo/tenant no contexto de FinOps.
   * Correção: garantir labels `appgear.io/tenant-id`, `appgear.io/tier`, `appgear.io/topology`, `appgear.io/module` em todas as PrometheusRules.

6. **Usar este módulo na Topologia A (Docker Compose)**

   * Sintoma: tentativa de aplicar Sync Waves, Reloader e PrometheusRule num ambiente Docker-only.
   * Correção: lembrar que este módulo se aplica à **Topologia B (Kubernetes)**.
   * A Topologia A é apenas para desenvolvimento simplificado/local e não suporta Argo CD, CRDs do Prometheus Operator, etc.

7. **Timeout não definido nos scripts de espera (refinamento futuro)**

   * Na v0.1, o loop `until nc -z` é aceitável, e o próprio backoff do K8s trata falhas persistentes.
   * Para v1, pode-se introduzir um timeout total no script para evitar loops muito longos em casos de falha permanente.

---

## 7. Onde salvar

1. **Arquivo do módulo**

   * Nome sugerido:

     * `Módulo 17 v0.1.md`
   * Local recomendado (documentação modular):

     * Repositório: `appgear-contracts`
     * Diretório: raiz ou subpasta de módulos, conforme padrão adotado.

2. **Documento unificado de desenvolvimento**

   * Incluir este conteúdo, como seção específica, em:

     * Arquivo: `1 - Desenvolvimento v0.md`
   * Título sugerido no índice:

     ```md
     ### Módulo 17 – Políticas Operacionais e Resiliência (Orquestração de Boot, Auto-Healing, Dependências e Alertas)
     ```

3. **Repositórios GitOps**

   * **Core (`webapp-ia-gitops-core`)**

     * Applications com Sync Waves:

       * `apps/core/identity/core-keycloak-application.yaml`
       * `apps/core/storage/*` (Ceph, Postgres, Redis, Qdrant, Redpanda)
       * `apps/core/security/*` (Vault, OPA, OpenFGA)
       * `apps/core/border/*` (Traefik, Coraza, Kong, Istio, LiteLLM)
     * Reloader:

       * `apps/core/reloader/application-reloader.yaml`
       * `apps/core/reloader/kustomization.yaml`
     * Regras de observabilidade:

       * `apps/core/observability/rules/dependency-alerts.yaml`

   * **Suítes (`webapp-ia-gitops-suites`)**

     * Ajustes de Sync Waves e Init Containers nos manifests de:

       * Backstage, Flowise, N8n, Directus, Appsmith, Metabase.
       * Suíte Factory, Brain, Operations, Guardian (serviços dependentes de bancos Core).

Com isso, o **Módulo 17 – Políticas Operacionais e Resiliência v0.1** passa a estar **conforme** com o padrão de formato (Markdown), mantendo a lógica de resiliência validada e alinhando a aplicação com FinOps, GitOps e Observabilidade definidos nos módulos anteriores.
