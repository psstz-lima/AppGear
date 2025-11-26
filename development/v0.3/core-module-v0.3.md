# M00 – Fundamentos de repositório e baseline (v0.3)

> [!IMPORTANT]
> Este arquivo descreve o módulo M00 da linha v0.3 da AppGear.  
> Deve ser lido em conjunto com:
> - `docs/architecture/contract/contract-v0.md`
> - `docs/architecture/audit/audit-v0.md`
> - `docs/architecture/interoperability/interoperability-v0.md`
> - `docs/architecture/interoperability/resources/fluxos-ai-first.md`
> - `docs/architecture/interoperability/resources/mapa-global.md`

## 1. Objetivo

Consolidar, em **um único módulo-base**, as premissas que todos os demais módulos repetiam:

- **Stack base obrigatória** (Traefik prefixado, Coraza WAF, Kong, Istio, componentes Core e Suítes).
- **.env central** e `.env.example` versionado como única fonte de variáveis sensíveis em DEV/PoC.
- **Pipeline de borda unificado** e ordem explícita de TLS passthrough.
- **Padronização de GitOps** via **ApplicationSet** para todos os apps (App-of-Apps + templates).
- Referência única para **manifestações compartilhadas** (stack unificada, namespaces e dependências cruzadas).

Todos os módulos v0.x devem **importar estas premissas** em vez de duplicá-las. Trechos repetidos devem ser removidos e substituídos por um link para este arquivo.

## 2. Premissas únicas (não duplicar nos módulos)

1. **Stack base e exposições**
   - Traefik operando por prefixo (`/flowise`, `/appsmith`, `/directus`, etc.).
   - Coraza como WAF obrigatório para todo tráfego externo.
   - Kong como API Gateway único, sem rotas diretas Traefik → serviços.
   - Istio com mTLS **STRICT** em toda a malha.
   - Componentes Core sempre provisionados por GitOps (Argo CD) e observabilidade habilitada (logs, métricas, traces).

2. **Ordem oficial do pipeline de rede (com TLS passthrough)**

   ```text
   [Traefik (TLS passthrough SNI)] -> [Coraza WAF] -> [Kong Gateway] -> [Istio IngressGateway] -> [Service Mesh]
   ```

   - A terminação TLS só ocorre no componente responsável pelo domínio do serviço (idealmente no **Istio IngressGateway**).
   - Nenhum serviço Core ou Suite pode ser exposto direto pelo Traefik sem passar por Coraza e Kong.

3. **Gestão de configuração**
   - `.env` centralizado em `/opt/appgear/.env` (Topologia A) e **ExternalSecrets + Vault** (Topologia B).
   - `.env.core` unificado em `/config/.env.core` com variáveis globais (Postgres, domínio base, LiteLLM, n8n, etc.), carregado em todos os módulos com `source /config/.env.core` para evitar duplicação.
   - Apenas `.env.example` é versionado; valores reais ficam fora do Git.

4. **GitOps e ApplicationSets**
   - Todos os apps devem ser declarados via **ApplicationSet**; uso direto de `Application` isolado só é aceito dentro do App-of-Apps.
   - Templates YAML ficam em `gitops/appsets/` e recebem `tenant_id`, `workspace_id`, `vcluster` e `env` por parâmetros.

## 3. Como reutilizar (guideline para módulos)

1. **Referencie** este módulo no cabeçalho dos demais (`Premissas padrão: ver modulo-core-v0.3`).
2. **Remova** blocos duplicados de stack base, .env, Traefik prefixado ou ordem de borda.
3. **Aplique** o pipeline de rede exatamente como definido acima em todos os diagramas e exemplos.
4. **Use** o template de ApplicationSet abaixo para novos apps ou para migrar módulos que ainda usam `Application` direto.

### 3.1. Template YAML – ApplicationSet padronizado

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: appgear-{{app}}
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - tenant: {{tenant_id}}
            workspace: {{workspace_id}}
            vcluster: {{vcluster}}
            env: {{env}}
  template:
    metadata:
      name: "{{app}}-{{workspace}}"
      labels:
        appgear.io/tenant: "{{tenant}}"
        appgear.io/workspace: "{{workspace}}"
        appgear.io/vcluster: "{{vcluster}}"
        appgear.io/env: "{{env}}"
    spec:
      project: core
      source:
        repoURL: git@github.com:appgear/appgear-gitops-core.git
        targetRevision: main
        path: apps/{{app}}
      destination:
        server: https://kubernetes.default.svc
        namespace: "{{workspace}}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

### 3.2. Manifesto unificado da stack

- Arquivo: `stack-unificada-v0.3.yaml` (mesmo diretório).
- Contém namespaces, borda/pipeline e os componentes Core + Suítes por topologia.
- Deve ser referenciado por todos os módulos que precisarem listar dependências inter-stack.

## 4. Migração de módulos existentes

1. **Identifique** se o módulo possui seções de premissas idênticas (stack base, Traefik prefixado, .env central, pipeline de borda).
2. **Troque** essas seções por um parágrafo curto referenciando este módulo (reduzindo redundância e risco de divergência).
3. **Certifique-se** de que qualquer menção à cadeia de borda siga exatamente `[Traefik] -> [Coraza WAF] -> [Kong Gateway] -> [Istio IngressGateway] -> [Service Mesh]`.
4. **Atualize** os manifests GitOps para usar ApplicationSet conforme o template acima.
5. **Use** o `stack-unificada-v0.3.yaml` como tabela de verdade para dependências e namespaces compartilhados.

## 5. Onde salvar

Este arquivo deve ser mantido em:

```text
development/v0.3/core-module-v0.3.md
```
