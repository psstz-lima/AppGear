# Relatório de Interoperabilidade v0.3 — Cross Check Intermodular

## Objetivo

Consolidar as análises de cross check dos módulos 00–17 na linha v0.3, apontando ações corretivas alinhadas ao baseline único (`development/v0.3/stack-unificada-v0.3.yaml`) e ao procedimento MAPA_NC → PLANO_CORRECAO → MODULO_REESCRITO → CHECKLIST.

## Fontes de verdade consideradas

- `development/v0.3/stack-unificada-v0.3.yaml` — tabela única para borda (Traefik → Coraza → Kong → Istio), namespaces e variáveis globais (.env central + Vault/ExternalSecrets).
- `STATUS-ATUAL.md` — diretrizes do procedimento CI/CD v1.1, uso obrigatório de labels `appgear.io/*` e publicação de artefatos em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}`.

## Síntese do cross check (v0.3)

- **Módulos avaliados:** 18 (00–17) na linha v0.3.
- **Cobertura de trilha CI/CD v1.1:** incompleta nos módulos 06–12; módulos 00–05 já seguem o fluxo MAPA_NC → PLANO_CORRECAO.
- **Aderência ao baseline de borda:** consistente em diagramas e manifests recentes, mas há resquícios de bypass direto em exemplos legados.
- **Configuração de ambiente:** `.env.example` presentes, porém sem referência explícita ao `.env` centralizado ou a ExternalSecrets em alguns módulos de suíte.
- **Rastreabilidade de artefatos:** `/artifacts` não está referenciado em todos os checklists; SBOM com hash SHA-256 ausente em parte dos módulos de 06–12.

## Achados prioritários e correções

### 1) Configuração de ambiente e segredos

**Achado:** divergência entre `.env.example` e variáveis exigidas pelo manifesto unificado; falta de apontamento para `/opt/appgear/.env` (Topologia A) ou ExternalSecrets + Vault (Topologia B).

**Correção requerida:**
- Referenciar explicitamente a carga do `.env` centralizado ou o binding de ExternalSecrets em todos os manifests/deploys.
- Limitar `.env.example` a documentação pública e remover segredos reais do repositório.

### 2) Cadeia de borda e mTLS STRICT

**Achado:** em alguns módulos de suíte ainda existem descrições ou diagramas com publicação direta via Traefik ou Kong sem o hop Coraza WAF.

**Correção requerida:**
- Atualizar diagramas e manifestos para reforçar a cadeia `Traefik (TLS passthrough SNI) → Coraza WAF → Kong → Istio IngressGateway → Service Mesh` com `tls_mode: STRICT`.
- Incluir `PeerAuthentication`/`DestinationRule` com `mode: STRICT` onde faltante e documentar exceções no quadro de monitoramento.

### 3) GitOps via ApplicationSets

**Achado:** alguns módulos ainda usam App-of-Apps como mecanismo principal ou não declaram o gerador `list` com labels `appgear.io/*`.

**Correção requerida:**
- Migrar todos os apps para ApplicationSets `list-generator`, mantendo App-of-Apps apenas como bootstrap.
- Adicionar labels de tenant/workspace/vcluster/env em todos os recursos para FinOps e auditoria.

### 4) Trilha de evidências CI/CD v1.1

**Achado:** falta de registro de MAPA_NC/PLANO_CORRECAO e de artefatos em `/artifacts/ai_reports` e `/artifacts/sbom` para módulos 06–12.

**Correção requerida:**
- Publicar o pacote MAPA_NC → PLANO_CORRECAO → MODULO_REESCRITO → CHECKLIST por módulo.
- Gerar e registrar SBOM com hash SHA-256 e logs de decisão do gate de IA em `/artifacts`.

### 5) Alinhamento de versão

**Achado:** coexistência pontual de rótulos legados (v0.2/v0.15) em headers de documentos.

**Correção requerida:**
- Padronizar cabeçalhos com `version: v0.3`, `schema: appgear-stack` e `compatibility: full`, conforme o manifesto.

## Roteiro mínimo de correção (por módulo)

1. **Mapear NCs** comparando o módulo com `stack-unificada-v0.3.yaml` (env, borda, namespaces, ApplicationSets).
2. **Planejar correções** priorizando: (a) cadeia de borda e mTLS, (b) GitOps via ApplicationSets, (c) labels `appgear.io/*`, (d) integração com LiteLLM/KEDA se aplicável.
3. **Reescrever artefatos** (diagramas, manifests, docs) com o bloco de metadados v0.3 e referências a `/opt/appgear/.env` ou ExternalSecrets.
4. **Registrar evidências** no fluxo CI/CD v1.1: MAPA_NC, PLANO_CORRECAO, MODULO_REESCRITO, CHECKLIST + artefatos (`/artifacts/{ai_reports, sbom, coverage, tests, docker}`) com hashes.

## Próximos passos

- Priorizar módulos 06–12 para fechar lacunas de trilha CI/CD e de publicação de artefatos.
- Validar que nenhum exemplo ou documentação publique serviços direto em Traefik/Kong sem Coraza e sem mTLS STRICT.
- Atualizar o quadro de monitoramento com exceções justificadas e responsáveis, garantindo rastreabilidade de FinOps e auditoria.
- **Status das correções aplicadas:** os módulos 06–12 já foram reescritos com o bloco de metadados v0.3, cadeia obrigatória Traefik → Coraza → Kong → Istio, `.env` centralizado/ExternalSecrets e trilha CI/CD v1.1 explicitada; pendências restantes se concentram na coleta de evidências (MAPA_NC/PLANO_CORRECAO/CHECKLIST) e no registro de hashes de SBOM.
