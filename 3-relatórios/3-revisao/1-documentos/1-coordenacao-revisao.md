# Coordenação de Retrofit v0 – Decisões Globais e Regras Transversais

Este documento define as **decisões globais** e as **regras transversais** que devem ser aplicadas em todos os módulos da arquitetura AppGear durante o processo de **Retrofit vx.x**.

Ele é o cabeçalho de referência do chat:

> **WEBAPP IA – Coordenação de Retrofit v0**

Nenhum módulo (00–17) pode contrariar estas regras sem que haja **alteração explícita do 0 – Contrato de Arquitetura**.

---

## 1. Escopo da coordenação de Retrofit

- Retrabalhar todos os módulos v0 para uma linha **v0.x**, garantindo:
  - Aderência total ao **0-contrato-v0**;
  - Correção de todas as **não-conformidades levantadas em auditoria**;
  - Remoção de `TODO`, `FIXME`, uso de `:latest` e exemplos que violem o contrato.
- As decisões globais aqui definidas são **padrão obrigatório**:
  - Os chats podem detalhar/especializar seja por módulo ou geral, porém sempre fazendo separação por módulos,
  - Mas não podem quebrar estas regras.

---

## 2. Forma canônica dos artefatos

1. Toda documentação oficial de módulo deve ser:
   - Arquivo **Markdown (`.md`)**;
   - Seguir a estrutura:  
     **O que é · Por que · Pré-requisitos · Como fazer (comandos) · Como verificar · Erros comuns · Onde salvar**.
2. Formatos legados:
   - Arquivos `.py` com docstring longa não são mais fonte da verdade;
   - Se existirem, tornam-se apenas **consumidores** que apontam para o `.md`.
3. O **`0-contrato-v0`** é sempre a **fonte da verdade arquitetural**:
   - Nenhum módulo pode contradizer o contrato;
   - Exceções precisam ser tratadas como proposta formal de alteração do Contrato.

---

## 3. Topologias oficiais

### 3.1. Topologia A – Docker Compose (Dev / Teste / Demo)

- Uso permitido apenas para:
  - **Desenvolvimento**, **teste local**, **PoC**, **demo**.
- Regras:
  - `.env` central é permitido apenas em contexto dev/demo;
  - A Topologia A **não é suportada para produção de clientes**;
  - Exemplos devem explicitar claramente essas limitações.

### 3.2. Topologia B – Kubernetes (Enterprise / Produção)

- Única topologia suportada para **produção enterprise**.
- Pilares obrigatórios:
  - Kubernetes + GitOps (Argo – App-of-Apps, Workflows/Events quando aplicável);
  - Istio Service Mesh com **mTLS STRICT**;
  - **vCluster por Workspace** (hard multi-tenancy);
  - Ceph como backend de storage;
  - Tailscale para conectividade híbrida;
  - KEDA para Scale-to-Zero nos add-ons;
  - LiteLLM como gateway único de IA.

Todos os módulos devem reforçar, em “Por que” / “Erros comuns”:

> Topologia A não é recomendada para produção; produção deve ser Topologia B.

---

## 4. GitOps e fonte de verdade

1. **Git é a fonte de verdade** para infra:
   - Manifestos Kubernetes, Kustomize, Helm, scripts de bootstrap;
   - Nada crítico deve depender apenas de comandos manuais sem ter um YAML correspondente.
2. Segredos imperativos:
   - Padrão: segredos vêm de **Vault + ExternalSecrets/SealedSecrets**;
   - Criação manual/imperativa é **exceção de bootstrap** bem documentada:
     - Ex.: segredo `argocd-repo-cred` inicial.
3. Cada módulo deve indicar claramente:
   - Quais repositórios Git são usados;
   - Em que pasta/overlay os manifestos daquele módulo residem.

---

## 5. Imagens e versionamento

1. É **proibido** usar `:latest` em exemplos de:
   - Deployments Kubernetes;
   - Docker Compose/Swarm.
2. Toda imagem deve ter **tag pinada**:
   - Ex.: `backstage:1.19.0`, `opencost:v1.30.0`, etc.
3. Onde possível:
   - Centralizar versões em tabela ou arquivo dedicado (por módulo ou por stack),
   - Facilitar upgrade coordenado em releases futuros.

---

## 6. Labels, FinOps e metadados

1. Labels mínimas obrigatórias em todo objeto relevante (Deployments, Pods, Services, ConfigMaps, Secrets, Jobs etc.):

   ```yaml
   appgear.io/part-of: <nome-da-plataforma-ou-stack>
   appgear.io/tier: <core|suite|workspace>
   appgear.io/suite: <core|factory|brain|operations|guardian>
   appgear.io/topology: <A|B>
   appgear.io/tenant-id: <global|id-do-tenant>
   appgear.io/workspace-id: <global|id-do-workspace>
````

2. As labels devem ser coerentes com:

   * Multi-tenancy (tenant/workspace/vCluster);
   * Requisitos de FinOps / OpenCost;
   * Regras de auditoria (M00-3 / Labels).
3. Durante o Retrofit, exemplos parciais devem ser corrigidos:

   * Nada de objetos “órfãos” sem `tenant-id` ou `part-of`.

---

## 7. Segredos, credenciais e dados sensíveis

1. **Vault** (Módulo 05) é a **fonte única de segredos**:

   * Integração preferencial via:

     * External Secrets Operator, ou
     * Vault Agent Injector (quando aplicável).
2. Regras transversais:

   * Não criar arquivos de credenciais em disco (`credentials-*.txt`) como solução padrão;
   * Não recomendar segredos em `.env` para produção.
3. Contas administrativas (ArgoCD, Keycloak, etc.):

   * Hashes de senha no Git apenas como **exceção de bootstrap**;
   * Deve haver política clara de:

     * Rotação pós-implantação;
     * Desativação em favor de SSO (Keycloak/MidPoint);
     * Migração para credenciais geridas pelo Vault.

---

## 8. Segurança de borda e rede

1. Cadeia de borda oficial na Topologia B:

   ```text
   Traefik → Coraza (WAF) → Kong (API Gateway) → Istio → Serviços internos
   ```

2. Regras:

   * É proibido expor serviços diretamente via Traefik/IngressRoute, ignorando Coraza/Kong, para produção;
   * Qualquer exemplo legado com bypass deve ser **corrigido**.

3. Rede interna:

   * Uso recomendado de **NetworkPolicies** para reforçar que o tráfego HTTP entra pela cadeia oficial;
   * Módulos que expõem HTTP devem assumir este fluxo como padrão.

---

## 9. Multi-tenancy e isolamento

1. Hierarquia oficial:

   * `tenant_id` → agrupa Workspaces de um cliente/entidade;
   * `workspace_id` → unidade de produto/projeto;
   * `vCluster` → unidade de execução isolada associada ao Workspace.

2. Serviços multi-tenant devem:

   * Segregar dados por `tenant_id` (schema, namespace, índices, coleções, buckets);
   * Respeitar autorização fina (Keycloak + OpenFGA);
   * Prever testes de não vazamento entre tenants.

3. Módulos de dados, IA, observabilidade ou integrações devem:

   * Explicar como `tenant-id` é aplicado (tags, schemas, índices, tópicos, etc.).

---

## 10. Observabilidade, retenção e custos

1. Módulos ligados a observabilidade (logs, métricas, tracing, FinOps) devem:

   * Explicitar políticas mínimas de retenção (Prometheus, Loki, etc.);
   * Considerar impacto de custos de armazenamento.
2. Exemplos precisam:

   * Incluir labels de `tenant-id`, `suite`, `tier` nas métricas e logs sempre que fizer sentido;
   * Referenciar dashboards/consultas padrão (Grafana, OpenCost, Lago).

---

## 11. Escalonamento e Scale-to-Zero (KEDA)

1. Serviços não 24x7 (especialmente add-ons e suítes) devem:

   * Ter estratégia de autoscaling documentada (HPA ou KEDA);
   * Preferencialmente usar **Scale-to-Zero** quando tecnicamente viável.
2. Módulos de:

   * n8n, Flowise, Appsmith, ferramentas de build/CI, agentes, etc.
   * Devem trazer exemplos de `ScaledObject` ou HPA para orientar o uso.

---

## 12. Uso da IA no processo de Retrofit

Para **cada chat de módulo (00–17)**:

1. O prompt deve sempre incluir:

   * Trecho relevante do **0-contrato-v0**;
   * Trecho da **2-auditoria-v0** referente ao módulo;
   * Versão atual do **Módulo v0 (.md)**.
2. A IA deve ser instruída a:

   1. Listar **não-conformidades** vs Contrato + Auditoria + este manifesto;
   2. Propor **correções** em forma de lista;
   3. Reescrever o **módulo completo (v0.x)** já aplicando as correções.
3. É proibido que um módulo reintroduza:

   * `:latest`,
   * Bypass de Coraza/Kong/Istio em produção,
   * Falta de labels obrigatórias,
   * Instruções de segredos fora do padrão Vault/ExternalSecrets (salvo bootstrap explícito).

---

## 13. Evolução deste manifesto

* Qualquer decisão nova que impacte mais de um módulo (ex.: versão padrão de Backstage ou padrão de rota do LiteLLM):

  * Deve ser registrada no documento **retrofit-v0** este usado para ajuste dos módulos dependentes;
  * Passa a ser obrigatória em todos os módulos relevantes.
* Alterações aqui descritas devem ser refletidas:

  * No `0-contrato-v0` (quando forem estruturais);
  * Nos módulos afetados (00–17), na próxima rodada de Retrofit.

---

## 14. Ordem e dependências dos módulos

1. Módulo 00 – Convenções, Repositórios e Nomenclatura  
2. Módulo 01 – Bootstrap GitOps e Argo CD (Core, Suites e Workspaces) 
3. Módulo 02 – Malha de Serviço e Borda (Istio, Traefik, Coraza, Kong)
4. Módulo 03 – Observabilidade e FinOps  
5. Módulo 04 – Armazenamento e Bancos Core  
6. Módulo 05 – Segurança e Segredos (Vault, OPA, Falco, OpenFGA)  
7. Módulo 06 – Identidade e SSO (Keycloak, midPoint, RBAC/ReBAC)  
8. Módulo 07 – Portal Backstage e Integrações Core  
9. Módulo 08 – Serviços de Aplicação Core (LiteLLM, Flowise, N8n, BPMN, Directus, Appsmith, Metabase)  
10. Módulo 09 – Suíte Factory (CDEs, Airbyte, Build, Multiplayer)  
11. Módulo 10 – Suíte Brain (RAG, Agentes, AutoML)  
12. Módulo 11 – Suíte Operations (IoT, Digital Twins, RPA, KubeEdge)  
13. Módulo 12 – Suíte Guardian (Security Suite, Legal AI, Chaos, App Store)  
14. Módulo 13 – Workspaces, vCluster e modelo por cliente  
15. Módulo 14 – Pipelines de Geração AI-First (N8n, Argo Workflows, Argo CD)  
16. Módulo 15 – Continuidade de Negócios (DR \& Backup Global) 
17. Módulo 16 – Conectividade Híbrida (VPN, Túneis e Acesso Remoto)  
18. Módulo 17 – Políticas Operacionais e Resiliência

---

## 15. Gramática de saída da IA por módulo

Toda rodada de Retrofit de módulo (00–17) deve produzir, **nesta ordem**, as seções:

1. `### MAPA_NC`  
2. `### PLANO_CORRECAO`  
3. `### MODULO_REESCRITO`  
4. `### CHECKLIST`

Nenhuma resposta de IA pode adicionar conteúdo estrutural fora dessas seções.