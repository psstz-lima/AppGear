# Módulo 00 – Convenções, Repositórios e Nomenclatura

Versão: v0.2

### Atualizações v0.2

- Padroniza `.env` central, rotas Traefik por prefixo e labels `appgear.io/*` como pré-checagens obrigatórias.


### Premissas padrão (v0.2)

- Uso de `.env` central para variáveis sensíveis e `.env.example` versionado.
- Traefik como proxy reverso com rotas por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
- Stack de referência com Traefik, Ollama, Flowise, Directus + MinIO, Appsmith, n8n, Postgres, Qdrant, Redis, Tika, Gotenberg, SSO, mecanismo de Publish/Rollback, observabilidade (logs, métricas, traces) e PWA.
- Para frontends, recomendar **Tailwind CSS + shadcn/ui**.

---
Define o “alfabeto” da plataforma: nomes de clusters, namespaces, repositórios Git, módulos e labels (appgear.io/*).
Padroniza formato dos documentos (*.md), uso de .env central, estrutura de diretórios e convenções de FinOps (como rotular tudo por tenant/workspace).

---

## O que é

Este módulo estabelece a **camada base de governança técnica** da plataforma **AppGear**, definindo:

* O formato **canônico** de documentação de arquitetura (sempre em `.md`, nunca `.py`).
* Convenções de nomenclatura para:

  * diretórios de host em Topologia A (Docker/Compose/Swarm),
  * redes, stacks e serviços Docker/Swarm/Compose,
  * clusters, namespaces, tenants, vClusters e workspaces em Kubernetes (Topologia B),
  * repositórios Git relacionados à plataforma.
* Padrões **obrigatórios** de:

  * labels e annotations no Kubernetes (Topologia B),
  * labels Traefik para serviços expostos em Topologia A,
  * healthcheck em containers Docker e liveness/readiness em K8s.
* Diretrizes para:

  * uso de Policy as Code (OPA/Conftest/Kyverno) para validar manifests,
  * definição mínima de resources (CPU/RAM) em pods/serviços,
  * uso de `.env` em desenvolvimento e proteção contra vazamento de segredos.

Qualquer módulo técnico que não estiver aderente a este documento é considerado **não conforme** com a governança da plataforma.

---

## Por que

1. **Fonte da Verdade única e auditável**
   A governança não pode existir como comentário de código ou docstring Python isolada. A forma oficial deve ser um arquivo Markdown, versionado no repositório correto, acessível a desenvolvedores, operação, segurança e negócio.

2. **Separação clara entre Topologia A (DEV/PoC) e Topologia B (Produção)**
   Topologia A (host único, Docker/Compose/Swarm) é apropriada para desenvolvimento, testes locais e provas de conceito. Não oferece HA de nó nem resiliência a falha de host, por isso **não substitui Topologia B** (Swarm multi-nó ou Kubernetes) em produção.

3. **Migração de redes e stacks sem causar incidentes**
   Trocar nomes de redes (ex.: `core-net` → `appgear-net-core`) afeta containers e services em execução. Sem planejamento e janela de manutenção, a alteração de rede derruba serviço em horário crítico.

4. **Metadados consistentes em Kubernetes para observabilidade e FinOps**
   Sem labels/annotations padronizadas, não há visão consolidada por tenant, workspace, suite ou topologia. Isso dificulta métricas, cobrança interna, rastreabilidade e debugging.

5. **Healthchecks e Policy as Code como parte do fluxo normal**
   Healthchecks/Probes e labels não podem depender de disciplina manual. Precisam de **validação automática em CI** (Conftest/OPA/Kyverno) para garantir que nenhum artefato chegue a produção em desacordo.

6. **Segurança e tratamento de segredos desde o ambiente de desenvolvimento**
   `.env` é útil em DEV, mas quando comitado no Git transforma segredos em texto plano permanente. Este módulo define que `.env` **jamais** é versionado; somente `.env.example` (sem valores sensíveis) pode ser incluído no repositório.

---

## Pré-requisitos

* Repositório de documentação/arquitetura da plataforma:

  * `appgear-docs`

* Repositórios de infraestrutura/AppGear (mínimo esperado):

  * `appgear-infra-bootstrap`
  * `appgear-gitops-core`
  * `appgear-gitops-suites`
  * `appgear-backstage`
  * `appgear-workspace-template`

* Ambiente de desenvolvimento:

  * Host Linux (Ubuntu LTS),
  * `docker` + `docker compose` (ou Docker Swarm),
  * `git` instalado e configurado com acesso aos repositórios.

* Ambiente de QA/Produção:

  * Cluster Kubernetes nomeado no padrão `ag-<regiao>-core-<env>` (por exemplo: `ag-br-core-dev`, `ag-br-core-prod`),
  * Ferramentas: `kubectl`, `kustomize` ou `helm`,
  * Ferramenta GitOps (ArgoCD ou equivalente) operacional.

* CI configurável (GitHub Actions, GitLab CI, etc.) com permissão para rodar ferramentas de policy (Conftest/OPA/Kyverno).

* Documentos de contrato e interoperabilidade (em migração ou já migrados para `.md`):

  * `0 - Contrato v0.md`
  * `1 - Desenvolvimento v0.md`
  * `2 - Auditoria v0.md`
  * `3 - Interoperabilidade v0.md`

---

## Como fazer (comandos)

### 1. Estabelecer o artefato canônico em Markdown

#### 1.1 Criar/atualizar o arquivo do Módulo 00 no repositório de docs

```bash
git clone git@github.com:appgear/appgear-docs.git
cd appgear-docs

mkdir -p docs/architecture

touch "docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.md"
```

1. Abra o arquivo criado.
2. Cole o conteúdo deste módulo **como a única fonte oficial de Módulo 00**.
3. Salve o arquivo.

Versione:

```bash
git add "docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.md"
git commit -m "mod00: consolida governanca em markdown como fonte canonica"
git push origin main
```

#### 1.2 Transformar arquivos `.py` em consumidores da governança (não fonte)

Em qualquer repositório que ainda contenha um `modulo_00.py` ou semelhante com docstring extensa:

1. Remova o conteúdo da docstring descritiva.
2. Deixe apenas um cabeçalho mínimo, apontando para o `.md`:

### Por que

Fonte oficial:
  - Repositório: appgear-docs
  - Arquivo: docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.md

&nbsp; * uso incorreto de tags de imagem;

3. Versione normalmente:

```bash
git add path/do/modulo_00.py
git commit -m "mod00: aponta para markdown como fonte oficial de governanca"
git push origin main
```

---

### 2. Estruturar pastas de documentação e interoperabilidade

#### 2.1 Organizar arquitetura e interoperabilidade no `appgear-docs`

* Repositórios Git principais (docs, gitops-core, gitops-suites).

* Mínimo entendimento da topologia A (Docker) e B (Kubernetes).

### Como fazer (comandos)

touch "docs/interoperabilidade/mapa-global.md"
touch "docs/interoperabilidade/modulos.yaml"
```

4. Edite os arquivos criados com a estrutura mínima que referencia este Módulo 00 (especialmente os módulos 1, 2 e 3).
5. Versione:

```bash
git add docs
git commit -m "mod00: estrutura base de arquitetura + interoperabilidade alinhada ao padrao"
git push origin main
```

---

### 3. Topologia A – Host único (Docker/Compose/Swarm)

> AVISO IMPORTANTE
> Topologia A (host único com Docker Compose/Swarm) é **exclusiva** para:
>
> * DEV local,
> * ambientes de laboratório,
> * PoCs ou demos de curta duração.
>
> Produção e ambientes com SLA formal **devem** usar Topologia B (Swarm multi-nó ou Kubernetes com GitOps). Topologia A não provê HA de nó, nem isolamento adequado para falha de host.

#### 3.1 Estrutura de diretórios no host

Diretório canônico:

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

Criação:

```bash
sudo mkdir -p /opt/appgear/{config,data,logs,docs}
sudo mkdir -p /opt/appgear/config/{traefik,sso,directus,appsmith,n8n,flowise,bpmn,broker,bi,observability}
sudo mkdir -p /opt/appgear/data/{postgres,redis,qdrant,minio,broker}

sudo touch /opt/appgear/.env
sudo touch /opt/appgear/docker-compose.yml
```

> Recomenda-se utilizar `/opt/appgear` como raiz de **todas** as stacks Docker/Swarm relacionadas à AppGear em Topologia A.

#### 3.2 Redes overlay padronizadas e migração de nomes antigos

Redes padrão:

* `appgear-net-core` – rede de core/infraestrutura,
* `appgear-net-apps` – rede de aplicações e workloads de negócio.

Exemplo de definição em `docker-compose.yml`:

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

**Migração de redes legadas (ex.: `core-net`, `apps-net`)**

1. Programar **janela de manutenção** com impacto comunicado.

2. Identificar redes antigas:

   ```bash
   docker network ls | egrep "core-net|apps-net"
   ```

3. Ajustar `docker-compose.yml` para referenciar **apenas** `appgear-net-core` e `appgear-net-apps`.

4. Remover a stack antiga:

   ```bash
   docker stack rm appgear-core   # ou o nome atualmente em uso
   ```

5. Remover redes legadas após todos os services saírem:

   ```bash
   docker network rm core-net apps-net 2>/dev/null || true
   ```

6. Subir novamente:

   ```bash
   cd /opt/appgear
   docker stack deploy -c docker-compose.yml appgear-core
   ```

> A migração de rede **interrompe** comunicação entre containers enquanto a stack é recriada. Tratar como mudança de infraestrutura formal (change window), com registro em changelog.

#### 3.3 Nomes de stacks e serviços em Topologia A

* Stack principal de core: `appgear-core`
* Stack de aplicações/suites: `appgear-apps`

Padrão de serviços:

* Core: `core-<componente>`
  Ex.: `core-traefik`, `core-postgres`, `core-backstage`.
* Add-ons/suites: `addon-<suite>-<componente>`
  Ex.: `addon-factory-flowise`, `addon-brain-ollama`.

Exemplo de deploy:

```bash
cd /opt/appgear
docker stack deploy -c docker-compose.yml appgear-core
```

#### 3.4 Padrões de labels Traefik para serviços em Topologia A

Serviço Traefik (simplificado):

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

Serviço exposto por domínio:

```yaml
  core-backstage:
    image: ghcr.io/appgear/backstage:latest
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

> Regra: **todo** serviço HTTP exposto via Traefik **deve** usar um middleware de headers seguros (como `appgear-secure-headers`).

#### 3.5 Healthcheck padrão em Docker/Swarm

Exemplo Postgres:

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

Exemplo serviço HTTP:

```yaml
  core-backstage:
    image: ghcr.io/appgear/backstage:latest
    networks:
      - appgear-net-apps
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:7007/health || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 60s
```

#### 3.6 Resources mínimos para Swarm/Compose

Swarm (recomendado em PoC compartilhada):

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

Compose “puro” (sem Swarm):

```yaml
  core-backstage:
    mem_limit: 512m
```

> Mesmo em ambiente de DEV, é recomendável limitar memória para reduzir risco de exaustão do host.

---

### 4. Topologia B – Kubernetes + GitOps

#### 4.1 Padrões de nomes: clusters, namespaces, tenants, workspaces, vClusters

* Cluster físico:
  `ag-<regiao>-core-<env>`
  Ex.: `ag-br-core-dev`, `ag-br-core-prod`.

* Namespaces globais “core” (no cluster físico):
  `argocd`, `appgear-core`, `observability`, `security`, `backstage`.

* Tenants:
  `tenant-<slug>`
  Ex.: `tenant-acme`.

* Workspaces (por tenant):
  `kebab-case`: `acme-erp`, `acme-crm`, etc.

* vClusters (por workspace):
  `vcl-ws-<workspace_id>`

* Namespaces dentro do vCluster (por workspace):

  * `ws-<workspace_id>-core`
  * `ws-<workspace_id>-factory`
  * `ws-<workspace_id>-brain`
  * `ws-<workspace_id>-operations`
  * `ws-<workspace_id>-guardian`

#### 4.2 Labels e annotations obrigatórias para objetos K8s

Labels mínimas:

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

Annotations mínimas:

```yaml
metadata:
  annotations:
    appgear.io/contract-version: "v0"
    appgear.io/module: "mod00"
```

> Outros módulos podem exigir mais labels/annotations, mas as acima são o **mínimo obrigatório** em todos os Deployments/StatefulSets relacionados à plataforma.

#### 4.3 Resources (CPU/RAM) – regra de governança

Todo container em K8s deve declarar `requests` e `limits`:

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

* É proibido criar novos manifests sem `resources`.
* Valores exatos podem variar por perfil (light/medium/heavy), mas:

  * `requests` não pode ser omitido,
  * `limits` não pode ser omitido.
* Objetivo: evitar Noisy Neighbor e facilitar planejamento de capacidade.

#### 4.4 Probes (healthcheck) em Kubernetes

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

Banco de dados (exec):

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

> Probes são mandatórias para todos os workloads de negócio e componentes core.

---

### 5. Policy as Code (Docker + Kubernetes)

#### 5.1 Estrutura de diretórios de políticas

No repositório GitOps principal:

```bash
cd appgear-gitops-core
mkdir -p policy/kubernetes policy/compose
```

#### 5.2 Políticas OPA para labels e resources em K8s

Exemplo de política para labels obrigatórias:

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

Exemplo para `resources` obrigatórios:

```bash
cat > policy/kubernetes/resources_required.rego << 'EOF'
package appgear.k8s.resources

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources
  msg := sprintf("Deployment %s sem bloco resources para container %s", [input.metadata.name, container.name])
}

&nbsp;  image: ghcr.io/appgear/backstage:${BACKSTAGE_VERSION}

#### 5.3 Políticas para Traefik em `docker-compose.yml`

2. **Ajustar exemplos de `.env` para citar Vault**

&nbsp;  * Manter exemplos de `.env` como *default local*, mas adicionar comentários:

&nbsp;  ```env

#### 5.4 Integração das políticas ao CI

Exemplo em GitHub Actions:

&nbsp;  POSTGRES_PASSWORD=changeme # Nunca versionar; injetar via Vault/ExternalSecrets

&nbsp;  ```

3. **Especificar migração de redes**

      - name: Instala conftest
        run: |
          wget https://github.com/open-policy-agent/conftest/releases/download/v0.56.0/conftest_Linux_x86_64.tar.gz
          tar xzf conftest_Linux_x86_64.tar.gz
          sudo mv conftest /usr/local/bin/

&nbsp;    * planejar janela;

&nbsp;    * criar nova rede/alias;

> Regra: nenhum PR que introduza YAML K8s ou `docker-compose.yml` pode ser mergeado com falha de `conftest`.

---

### 6. Segredos em Dev (Topologia A) e `.env`

#### 6.1 Regra de ouro para `.env`

* O arquivo `/opt/appgear/.env` é **sempre local** ao host.
* `.env` nunca é commitado em nenhum repositório Git (nem mesmo de exemplos internos).
* Apenas `.env.example` é versionado, contendo **chaves** mas **sem valores** reais.

#### 6.2 `.gitignore` padrão para repositórios com Compose

No repositório que contém o `docker-compose.yml`:

&nbsp;  .env

touch .env.example
git add .gitignore .env.example
git commit -m "mod00: adiciona gitignore para .env e template de variaveis"
git push origin main
```

* `.env.example` deve conter apenas nomes de variáveis e comentários indicando o que cada uma faz.
* A cópia para `.env` é feita manualmente por cada operador/desenvolvedor.

#### 6.3 `.env.core` unificado (variáveis globais)

* As variáveis globais repetidas nos módulos ficam centralizadas em `/config/.env.core` (ver `config/.env.core`).
* Antes de executar comandos de qualquer módulo, carregue o arquivo centralizado:

  ```bash
  set -a
  source /config/.env.core
  set +a
  ```

* O arquivo deve conter apenas **valores de referência** (nunca segredos reais) quando versionado; os valores efetivos são preenchidos em ambientes seguros.

---

## Como verificar

1. **Arquivo canônico do Módulo 00 presente e versionado**

   ```bash
   cd appgear-docs
   ls "docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.md"
   ```

2. **Estrutura de documentação mínima criada**

   ```bash
   tree -L 3 docs
   ```

   Verificar a existência de `docs/architecture` e `docs/interoperabilidade`.

3. **Diretórios e arquivos base na Topologia A**

   ```bash
   sudo tree -L 3 /opt/appgear || sudo ls -R /opt/appgear
   ```

   Conferir se há `config`, `data`, `logs`, `docs`, `.env` e `docker-compose.yml`.

4. **Redes Docker com nomes padronizados**

   ```bash
   docker network ls | grep appgear-net
   ```

   Esperado: `appgear-net-core` e `appgear-net-apps`.

5. **Healthcheck configurado em serviços críticos**

   ```bash
   docker inspect core-postgres | jq '.[0].Spec.TaskTemplate.ContainerSpec.Healthcheck'
   docker inspect core-backstage | jq '.[0].Spec.TaskTemplate.ContainerSpec.Healthcheck'
   ```

6. **Labels e resources em Deployments no Kubernetes**

   ```bash
   kubectl get deploy -A -o yaml | yq '.metadata.labels'
   kubectl get deploy core-backstage -n appgear-core -o yaml | yq '.spec.template.spec.containers[0].resources'
   ```

7. **Probes definidas para workloads principais**

   ```bash
   kubectl get deploy core-backstage -n appgear-core -o yaml | yq '.spec.template.spec.containers[0].livenessProbe'
   kubectl get deploy core-backstage -n appgear-core -o yaml | yq '.spec.template.spec.containers[0].readinessProbe'
   ```

8. **Políticas de OPA/Conftest existentes e executando**

   ```bash
   cd appgear-gitops-core
   conftest test k8s/ -p policy/kubernetes
   conftest test docker-compose.yml -p policy/compose
   ```

9. **`.env` não versionado**

   ```bash
   git status --ignored | grep .env || echo ".env nao esta versionado (ok)"
   ```

---

## Erros comuns

* Migrar redes (`core-net` → `appgear-net-core`) sem janela de manutenção, causando parada inesperada do ambiente.
* Utilizar Topologia A em produção e, depois, associar incidentes à “instabilidade do Docker”, quando o problema é de arquitetura.
* Esquecer `requests`/`limits` em pods no Kubernetes, resultando em consumo excessivo de recursos e impacto em outros workloads.
* Comitar `.env` “temporariamente” no repositório, abrindo precedente para exposição permanente de segredos.
* Criar políticas OPA/Conftest/Kyverno, mas não adicioná-las ao pipeline de CI (viram apenas documentação técnica, sem efeito real).
* Expor serviços via Traefik sem o middleware de headers seguros (`appgear-secure-headers` ou equivalente).
* Deixar o Módulo 00 divergente entre `.py` e `.md`, gerando inconsistência de governança.

---

## Onde salvar

* **Repositório canônico de governança:**
  `appgear-docs`

* **Caminho do arquivo do módulo:**
  `docs/architecture/Modulo 00 - Convencoes e Nomenclatura v0.md`

* **Referências em outros módulos:**

  * `1 - Desenvolvimento v0.md`: deve declarar explicitamente que **toda prática de dev** precisa respeitar Módulo 00.
  * `2 - Auditoria v0.md`: deve usar este módulo como base de checklist para conformidade técnica.
  * `3 - Interoperabilidade v0.md`: deve assumir nomenclatura, redes, labels e convenções deste módulo como padrão.
  * Documentos de comercial/contrato podem referenciar Módulo 00 quando tratarem de responsabilidades de operação e SLA.

Este Módulo 00 passa a ser a base formal para qualquer decisão de topologia, nomenclatura, redes, policy, healthcheck e tratamento de segredos na plataforma AppGear.

---

## Dependências entre módulos

A relação de dependência lógica entre este módulo e os demais módulos da arquitetura AppGear deve ser tratada como **obrigatória** para implantação ordenada da plataforma:

* **Módulo 00 – Convenções, Repositórios e Nomenclatura**

  * É o **fundamento de governança técnica**.
  * Não depende de outros módulos.
  * Define:

    * padrão de documentação (`.md` canônico),
    * convenções de nomes (clusters, namespaces, tenants, workspaces, redes),
    * labels `appgear.io/*`,
    * regras mínimas de `resources`, probes e tratamento de `.env`,
    * estrutura base de Policy as Code.

* **Módulo 01 – Bootstrap GitOps e Argo CD**

  * **Depende diretamente do Módulo 00**:

    * utiliza nomenclatura de clusters (`ag-<regiao>-core-<env>`),
    * utiliza labels `appgear.io/*` definidas aqui,
    * respeita regras de `.env` e de repositórios Git padronizados.

* **Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)**

  * **Depende do Módulo 00**:

    * usa convenções de namespaces (`appgear-core`, `security`, `istio-system`),
    * aplica labels de governança (`appgear.io/tenant-id`, `appgear.io/topology`),
    * segue regras de healthchecks/probes e de Policy as Code.

* **Módulo 03 – Observabilidade e FinOps (Prometheus, Grafana, Loki, OpenCost, Lago)**

  * **Depende do Módulo 00**:

    * utiliza labels `appgear.io/tenant-id`, `appgear.io/workspace-id`, `appgear.io/suite` para recortes de custo e métricas,
    * utiliza convenções de namespaces (ex.: `observability`),
    * segue regras de `resources` mínimos e probes.

* **Módulo 04 – Armazenamento e Bancos Core (Ceph, Postgres, Redis, Qdrant, RabbitMQ, Redpanda)**

  * **Depende do Módulo 00**:

    * usa StorageClass, namespaces e labels padronizados,
    * aplica labeling de FinOps (`appgear.io/tenant-id: global`),
    * segue política de `resources` obrigatórios para statefuls e brokers.

* **Demais módulos (05+ – Segurança, SSO, Segredos, Suites, Workspaces, PWA, etc.)**

  * **Devem sempre depender deste Módulo 00**:

    * qualquer componente novo deve:

      * aderir a nomenclatura de namespaces, tenants e workspaces,
      * aplicar labels de governança `appgear.io/*`,
      * definir `resources.requests` e `resources.limits`,
      * seguir padrões de documentação e de repositórios definidos aqui.

Em resumo: **nenhum módulo técnico AppGear pode ser considerado conforme se não respeitar integralmente o Módulo 00**.
