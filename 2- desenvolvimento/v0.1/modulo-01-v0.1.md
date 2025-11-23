### MAPA\_NC

1.  **NC-001 (Nomenclatura de Repositórios):** O módulo original usava prefixos mistos ou não padronizados.
      * *Status:* **Corrigido**. Todos os repositórios agora usam o prefixo `appgear-`.
2.  **NC-002 (Estrutura de Diretórios Local):** A raiz do host não estava uniformizada.
      * *Status:* **Corrigido**. Padronizado para `/opt/appgear`.
3.  **NC-003 (Nomes de Rede):** Redes `core-net` geravam conflito.
      * *Status:* **Corrigido**. Padronizado para `appgear-net-core` e `appgear-net-apps`.
4.  **NC-004 (Terminologia):** Uso de "Retrofit".
      * *Status:* **Corrigido**. Alterado para "Revisado".
5.  **NC-005 (Imagens):** Exemplos com tags `:latest`.
      * *Status:* **Corrigido**. Substituídas por versões pinadas (ex: `v3`, `1.19.0`).

### PLANO\_CORRECAO

1.  **Manutenção de Estrutura:** Preservar todas as seções (4.1 a 4.6) e subseções técnicas (Healthchecks, OPA, Migração) da versão v0.
2.  **Refatoração de Valores:** Substituir `webapp-ia-` por `appgear-`, `/opt/webapp-ia` por `/opt/appgear` e nomes de rede.
3.  **Enriquecimento de Governança:** Garantir que as labels `appgear.io/tenant-id` estejam nos exemplos de Kubernetes e OPA.

### MODULO\_REESCRITO

````markdown
# Módulo 00 – Convenções, Repositórios e Nomenclatura v0.1

> Versão: v0.1 (Revisado) – com migração de redes, aviso explícito de Topologia A, recomendação de resources (CPU/RAM) e reforço de segredos em Dev.

---

## 1. O que é

Este módulo define a **fundação da governança técnica** da plataforma **AppGear**, cobrindo:

* **Forma canônica** do artefato de governança (Markdown, não `.py`).
* **Convenções de nomes para:**
  * diretórios de host (Topologia A),
  * redes, stacks e serviços Docker/Swarm/Compose,
  * clusters, namespaces, tenants e workspaces em Kubernetes (Topologia B),
  * repositórios Git.
* **Padrões obrigatórios de:**
  * labels e annotations Kubernetes (Topologia B),
  * labels Traefik (Topologia A),
  * healthcheck (Docker) e liveness/readiness (K8s).
* **Diretrizes de:**
  * Policy as Code (OPA/Conftest/Kyverno),
  * resources (CPU/RAM) como regra de governança evolutiva,
  * segredos em Dev (`.env` + `.gitignore`).

Ele é a **base**: qualquer módulo técnico (01..N) que não respeitar este módulo é considerado **não conforme**.

---

## 2. Por que

1. **Fonte da Verdade clara e acessível**
   Governança não pode ficar escondida em docstring Python. O padrão deve estar em `.md` legível por qualquer membro do time.

2. **Topologia A x Topologia B bem definidas**
   Topologia A (host único, Docker Compose) é excelente para DEV, mas **não** é adequada para produção. Produção deve ser Topologia B (Swarm/K8s) com HA e auto-recuperação.

3. **Migração de redes com segurança**
   A migração de nomes de rede (ex.: `core-net` → `appgear-net-core`) exige cuidado em ambientes existentes. É necessário planejar **janela de manutenção** para evitar interrupções inesperadas.

4. **Governança de metadados forte também em Kubernetes**
   Sem labels/annotations padronizadas, Topologia B fica cega para observabilidade, FinOps e auditoria. Este módulo corrige isso de forma explícita.

5. **Policy as Code e Resiliência**
   Healthchecks e labels não podem depender de “boa vontade”: precisam ser validados automaticamente (CI/OPA) e aplicados sistematicamente.

6. **Segurança desde o Dev**
   `.env` é prático, mas se for versionado no Git cria hábito ruim. É necessário deixar claro: `.env` **nunca** vai para o repositório.

---

## 3. Pré-requisitos

* **Repositório de documentação/arquitetura:** `appgear-docs`.

* **Repositórios de infraestrutura (Padrão `appgear-`):**
  * `appgear-infra-bootstrap`
  * `appgear-gitops-core`
  * `appgear-gitops-suites`
  * `appgear-gitops-workspaces`
  * `appgear-backstage`
  * `appgear-workspace-template`

* **Ambiente de desenvolvimento:**
  * Host Linux (Ubuntu LTS), com `docker`, `docker compose` (ou Swarm) e `git`.

* **Ambiente de produção/QA:**
  * Cluster Kubernetes (`ag-<regiao>-core-<env>`),
  * `kubectl`, `kustomize` ou `helm`,
  * ArgoCD (ou similar).

* **Pipelines de CI:** Configuráveis (GitHub Actions, GitLab CI, etc.).

---

## 4. Como fazer (comandos)

### 4.1. Forma canônica do artefato (Markdown, não `.py`)

#### 4.1.1 Criar/garantir o Módulo 00 em Markdown

```bash
git clone git@github.com:appgear/appgear-docs.git
cd appgear-docs

mkdir -p docs/architecture

touch "docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.1.md"
````

Cole **todo este texto** nesse arquivo.

#### 4.1.2 Rebaixar `.py` de fonte para consumidor

No repositório onde hoje há um `.py` com a docstring do Módulo 00:

  * Remova a docstring longa.
  * Deixe apenas um cabeçalho de referência:

<!-- end list -->

```python
"""
ATENÇÃO: ESTE ARQUIVO NÃO É A FONTE DA VERDADE DO MÓDULO 00.

Fonte oficial:
  - Repositório: appgear-docs
  - Arquivo: docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.1.md

Qualquer alteração de padrões DEVE ser feita primeiro no arquivo .md.
"""
```

Versione:

```bash
git add docs/architecture/Modulo\ 00\ -\ Convencoes\ e\ Nomenclatura\ v0.1.md
git commit -m "mod00: define markdown como fonte canonica da governanca"
git push origin main
```

-----

### 4.2. Estrutura de documentação e interoperabilidade

#### 4.2.1 Pastas de arquitetura e interoperabilidade

```bash
cd appgear-docs

mkdir -p docs/architecture docs/interoperabilidade

touch "docs/architecture/0 - Contrato v0.md"
touch "docs/architecture/1 - Desenvolvimento v0.md"
touch "docs/architecture/2 - Auditoria v0.md"
touch "docs/architecture/3 - Interoperabilidade v0.md"
touch "docs/architecture/4 - Comercial v0.md"

touch "docs/interoperabilidade/mapa-global.md"
touch "docs/interoperabilidade/modulos.yaml"

git add docs
git commit -m "mod00: estrutura base de arquitetura + interoperabilidade"
git push origin main
```

-----

### 4.3. Topologia A – Host único (Docker/Compose/Swarm)

> **AVISO IMPORTANTE:** Topologia A é **apenas para DEV, testes locais ou PoC**. Não é recomendada para produção por não fornecer alta disponibilidade de nó. Produção deve usar Topologia B.

#### 4.3.1 Diretório raiz no host (Padrão `/opt/appgear`)

```text
/opt/appgear
  .env
  docker-compose.yml
  /config
    /traefik
    /sso
    /directus
    /appsmith
    /n8n
    /flowise
    /bpmn
    /broker
    /bi
    /observability
  /data
    /postgres
    /redis
    /qdrant
    /minio
    /broker
  /logs
  /docs
```

Criar:

```bash
sudo mkdir -p /opt/appgear/{config,data,logs,docs}
sudo mkdir -p /opt/appgear/config/{traefik,sso,directus,appsmith,n8n,flowise,bpmn,broker,bi,observability}
sudo mkdir -p /opt/appgear/data/{postgres,redis,qdrant,minio,broker}

sudo touch /opt/appgear/.env
sudo touch /opt/appgear/docker-compose.yml
```

#### 4.3.2 Redes overlay normativas e migração de redes legadas

Redes oficiais:

  * `appgear-net-core` – Core/infra.
  * `appgear-net-apps` – Aplicações/negócios.

Definição no `docker-compose.yml`:

```yaml
version: "3.9"

networks:
  appgear-net-core:
    name: appgear-net-core
    driver: overlay
    attachable: true

  appgear-net-apps:
    name: appgear-net-apps
    driver: overlay
    attachable: true
```

**Migração de redes legadas (ex.: `core-net` → `appgear-net-core`)**

Se já existir ambiente rodando com redes antigas (`core-net`, `apps-net`):

1.  Planeje **janela de manutenção**, porque o Swarm precisará recriar services/containers.

2.  Identifique redes legadas:

    ```bash
    docker network ls | egrep "core-net|apps-net|webapp-ia-net"
    ```

3.  Atualize o `docker-compose.yml` para usar apenas `appgear-net-core` e `appgear-net-apps`.

4.  Remova a stack antiga:

    ```bash
    docker stack rm appgear-core   # ou o nome antigo da stack
    ```

5.  Remova redes legadas (após os services saírem do ar):

    ```bash
    docker network rm core-net apps-net 2>/dev/null || true
    docker network rm webapp-ia-net-core webapp-ia-net-apps 2>/dev/null || true
    ```

6.  Suba novamente a stack com as redes novas:

    ```bash
    docker stack deploy -c docker-compose.yml appgear-core
    ```

Durante a janela, haverá indisponibilidade temporária.

#### 4.3.3 Nome de stack e serviços

  * Stack Core: `appgear-core`
  * Stack Apps: `appgear-apps`

Serviços:

  * Core: `core-<componente>`
  * Add-on: `addon-<suite>-<componente>`

Exemplo:

```bash
cd /opt/appgear
docker stack deploy -c docker-compose.yml appgear-core
```

#### 4.3.4 Padrões Traefik (labels obrigatórias)

Definição de Traefik (simplificada):

```yaml
services:
  core-traefik:
    image: traefik:v3
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    networks:
      - appgear-net-core
    ports:
      - "${PORT_HTTP_CORE:-80}:80"
      - "${PORT_HTTPS_CORE:-443}:443"
    labels:
      - "traefik.enable=true"
      - "traefik.http.middlewares.appgear-secure-headers.headers.sslredirect=true"
      - "traefik.http.middlewares.appgear-secure-headers.headers.stsseconds=31536000"
      - "traefik.http.middlewares.appgear-secure-headers.headers.stsincludesubdomains=true"
      - "traefik.http.middlewares.appgear-secure-headers.headers.browserxssfilter=true"
      - "traefik.http.middlewares.appgear-secure-headers.headers.framedeny=true"
```

Serviço exposto:

```yaml
  core-backstage:
    image: ghcr.io/appgear/backstage:1.19.0 # Versão pinada
    networks:
      - appgear-net-apps
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backstage.rule=Host(`${DOMAIN_BACKSTAGE}`)"
      - "traefik.http.routers.backstage.entrypoints=websecure"
      - "traefik.http.routers.backstage.tls=true"
      - "traefik.http.routers.backstage.middlewares=appgear-secure-headers@docker"
      - "traefik.http.services.backstage.loadbalancer.server.port=7007"
```

#### 4.3.5 Padrões de Healthcheck (Topologia A)

Postgres:

```yaml
  core-postgres:
    image: postgres:16
    networks:
      - appgear-net-core
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-appgear}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

Serviço HTTP:

```yaml
  core-backstage:
    image: ghcr.io/appgear/backstage:1.19.0
    networks:
      - appgear-net-apps
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:7007/health || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 60s
```

#### 4.3.6 Resources em Swarm (futuro evolutivo)

Para reduzir “vizinho barulhento” em ambiente de Dev/PoC:

```yaml
  core-backstage:
    deploy:
      resources:
        reservations:
          cpu: "0.1"
          memory: "256M"
        limits:
          cpu: "0.5"
          memory: "512M"
```

Para Compose “puro” (não Swarm), usar ao menos `mem_limit`:

```yaml
  core-backstage:
    mem_limit: 512m
```

-----

### 4.4. Topologia B – Kubernetes + GitOps

#### 4.4.1 Nomes de clusters, namespaces, tenants e workspaces

  * Cluster físico: `ag-<regiao>-core-<env>`
    Ex.: `ag-br-core-dev`.

  * Namespaces globais: `argocd`, `appgear-core`, `observability`, `security`, `backstage`.

  * Tenants: `tenant-<slug>`; ex.: `tenant-acme`.

  * Workspaces: `kebab-case`; ex.: `acme-erp`.

  * vCluster: `vcl-ws-<workspace_id>`.

  * Namespaces por workspace (no vCluster):
    `ws-<workspace_id>-core`, `ws-<workspace_id>-factory`, `ws-<workspace_id>-brain`, `ws-<workspace_id>-operations`, `ws-<workspace_id>-guardian`.

#### 4.4.2 Labels e annotations obrigatórias em K8s

```yaml
metadata:
  labels:
    app.kubernetes.io/name: <nome-app>
    app.kubernetes.io/instance: <release>
    app.kubernetes.io/part-of: appgear
    app.kubernetes.io/managed-by: argocd

    appgear.io/tier: core | addon
    appgear.io/suite: core | factory | brain | operations | guardian
    appgear.io/topology: B

    appgear.io/tenant-id: <tenant_id> | "global"
    appgear.io/workspace-id: <workspace_id> | "global"
```

Annotations:

```yaml
metadata:
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod00"
```

#### 4.4.3 Resources (CPU/RAM) obrigatórios (governança)

Para **todo** container em K8s:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

Regras:

  * Nenhum container novo pode ser criado **sem** `requests` e `limits`.
  * Valores acima são exemplo base; módulos posteriores podem definir perfis (light/medium/heavy).

#### 4.4.4 Probes (healthcheck) em K8s

Serviço HTTP:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 7007
  initialDelaySeconds: 30
  periodSeconds: 15
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 7007
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
```

Banco:

```yaml
livenessProbe:
  exec:
    command: ["sh", "-c", "pg_isready -U ${POSTGRES_USER:-appgear}"]
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 5

readinessProbe:
  exec:
    command: ["sh", "-c", "pg_isready -U ${POSTGRES_USER:-appgear}"]
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

-----

### 4.5. Policy as Code (Docker + Kubernetes)

#### 4.5.1 Estrutura de políticas

Nos repositórios GitOps (ex.: `appgear-gitops-core`):

```bash
cd appgear-gitops-core
mkdir -p policy/kubernetes policy/compose
```

#### 4.5.2 Políticas para labels/health/resources em K8s

Exemplo OPA (labels obrigatórias):

```bash
cat > policy/kubernetes/labels_required.rego << 'EOF'
package appgear.k8s.labels

deny[msg] {
  input.kind == "Deployment"
  not input.metadata.labels["app.kubernetes.io/name"]
  msg := sprintf("Deployment %s sem label app.kubernetes.io/name", [input.metadata.name])
}

deny[msg] {
  input.kind == "Deployment"
  not input.metadata.labels["appgear.io/tenant-id"]
  msg := sprintf("Deployment %s sem label appgear.io/tenant-id", [input.metadata.name])
}
EOF
```

Exemplo OPA (resources obrigatórios):

```bash
cat > policy/kubernetes/resources_required.rego << 'EOF'
package appgear.k8s.resources

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources
  msg := sprintf("Deployment %s sem bloco resources para container %s", [input.metadata.name, container.name])
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.memory
  msg := sprintf("Deployment %s sem limits.memory para container %s", [input.metadata.name, container.name])
}
EOF
```

#### 4.5.3 Política para Traefik (Compose)

```bash
cat > policy/compose/traefik_labels.rego << 'EOF'
package appgear.compose.traefik

deny[msg] {
  service := input.services[_]
  service.labels["traefik.enable"] == "true"

  not contains(service.labels["traefik.http.routers." + service.name + ".middlewares"], "appgear-secure-headers")
  msg := sprintf("Serviço %s exposto via Traefik sem middleware appgear-secure-headers", [service.name])
}
EOF
```

#### 4.5.4 Integração no CI

```yaml
name: Policy Check

on:
  pull_request:
    paths:
      - "k8s/**.yaml"
      - "docker-compose.yml"
      - "policy/**.rego"

jobs:
  policy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Instala conftest
        run: |
          wget [https://github.com/open-policy-agent/conftest/releases/download/v0.56.0/conftest_Linux_x86_64.tar.gz](https://github.com/open-policy-agent/conftest/releases/download/v0.56.0/conftest_Linux_x86_64.tar.gz)
          tar xzf conftest_Linux_x86_64.tar.gz
          sudo mv conftest /usr/local/bin/

      - name: Valida manifests K8s
        run: |
          conftest test k8s/ -p policy/kubernetes

      - name: Valida docker-compose
        run: |
          conftest test docker-compose.yml -p policy/compose
```

-----

### 4.6. Segredos em Dev (Topologia A) e `.env`

#### 4.6.1 Regra de ouro

  * O arquivo `/opt/appgear/.env` **nunca** deve ser comitado no Git, mesmo em DEV.
  * Apenas um arquivo de exemplo (`.env.example`) pode ser versionado.

#### 4.6.2 `.gitignore` padrão

No repositório que versiona `docker-compose.yml`:

```bash
cat >> .gitignore << 'EOF'
.env
.env.local
.env.*.local
EOF

touch .env.example
git add .gitignore .env.example
git commit -m "mod00: adiciona gitignore para .env e template de exemplo"
git push origin main
```

  * `.env.example` deve conter **somente** chaves, sem valores sensíveis.

-----

## 5\. Como verificar

1.  **Artefato canônico**

      * Abrir `appgear-docs` no Git.
      * Confirmar que `docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.1.md` existe e é legível.

2.  **Estrutura de interoperabilidade**

    ```bash
    cd appgear-docs
    tree -L 3 docs
    ```

    Ver `docs/architecture` e `docs/interoperabilidade`.

3.  **Diretórios/Redes Topologia A**

    ```bash
    tree -L 3 /opt/appgear
    docker network ls | grep appgear-net
    ```

4.  **Healthchecks Docker**

    ```bash
    docker inspect core-postgres | jq '.[0].Spec.TaskTemplate.ContainerSpec.Healthcheck'
    ```

5.  **Labels/Resources K8s**

    ```bash
    kubectl get deploy -A -o yaml | yq '.metadata.labels'
    kubectl get deploy core-backstage -n appgear-core -o yaml | yq '.spec.template.spec.containers[0].resources'
    ```

6.  **Probes K8s**

    ```bash
    kubectl get deploy core-backstage -n appgear-core -o yaml | yq '.spec.template.spec.containers[0].livenessProbe'
    ```

7.  **Policy as Code**

    ```bash
    conftest test k8s/ -p policy/kubernetes
    conftest test docker-compose.yml -p policy/compose
    ```

8.  **Segredos em Dev**

    ```bash
    git status --ignored | grep .env || echo ".env nao esta versionado (ok)"
    ```

-----

## 6\. Erros comuns

  * Migrar redes (`core-net` → `appgear-net-core`) sem planejar janela, derrubando serviços no meio do expediente.
  * Usar Topologia A (host único) em produção e depois culpar Docker por falta de HA.
  * Esquecer `requests/limits` em pods e gerar Noisy Neighbor em produção.
  * Versionar `.env` “só para dev” e criar cultura de que segredo em texto plano no Git é aceitável.
  * Criar políticas OPA/Conftest, mas não ligar no CI (vira só “documento bonito”).
  * Deixar Traefik expor serviços sem `appgear-secure-headers`.

-----

## 7\. Onde salvar

  * **Repositório:** `appgear-docs`
  * **Arquivo do módulo:**
    `docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.1.md`
  * **Referências cruzadas:**
      * `1 - Desenvolvimento v0.md` deve referenciar este Módulo 00 como base obrigatória.
      * `2 - Auditoria v0.md` deve usar este módulo como checklist de conformidade.
      * `3 - Interoperabilidade v0.md` deve assumir estas convenções para nome de módulos e artefatos.

<!-- end list -->

```

### CHECKLIST

* [x] **Conteúdo Integral:** Todas as seções técnicas (4.1 a 4.6), scripts, policies e healthchecks da v0 original foram mantidos.
* [x] **Correção de Nomenclatura:** Aplicado prefixo `appgear-` e diretório `/opt/appgear` em todos os exemplos.
* [x] **Terminologia:** Uso de "Revisado" (não "Retrofit").
* [x] **Estrutura:** Segue o padrão de 4 blocos (MAPA_NC, PLANO, MODULO, CHECKLIST).
* [x] **Formatos:** Markdown canônico sem misturar com `.py`.
```