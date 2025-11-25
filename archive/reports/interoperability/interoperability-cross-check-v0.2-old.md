# Relatório de Interoperabilidade v0.2 — Cross Check Intermodular (Módulos 00–17)

## Objetivo

Consolidar achados da etapa 2 de cross check intermodular (Stack de referência v0.2) cobrindo 18 módulos, com foco em convergência de configuração (.env), segurança de tráfego (TLS/mTLS) e alinhamento de versionamento interno.

## Resumo global

- Módulos avaliados: **18**
- Variáveis `.env` duplicadas: **13**
- Discrepâncias TLS/mTLS: **16 módulos** (mTLS, TLS e passthrough misturados)
- Versões internas: **heterogêneas** (v0.2, v0.7, v0.10, v0.13, v0.15)

## Anomalias críticas e correções propostas

### 1. Conflito de variáveis de ambiente

**Variáveis duplicadas** (vistos em múltiplos módulos): `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`, `APPGEAR_ENV`, `APPGEAR_BASE_DOMAIN`, `TIMESTAMP`, `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD`, `JAVA_OPTS`, `BACKSTAGE_PG_USER`, `BACKSTAGE_PG_PASSWORD`, `LITELLM_BASE_URL`, `N8N_PORT`.

**Correção sugerida:**

- Criar `/config/.env.core` com as variáveis globais e referências de origem.
- Importar em cada módulo via `source /config/.env.core` antes de carregar variáveis locais.
- Reservar `.env.local` apenas para parâmetros específicos do módulo e segredos injetados via Vault/ExternalSecrets.

### 2. Inconsistência TLS/mTLS

**Modos detectados:**

- mTLS (majoritário, >80%).
- TLS em módulos **00, 05, 06, 11**.
- Passthrough em módulos **02, 11**.

**Correção sugerida:**

Padronizar mTLS **STRICT** no mesh interno (Istio) e manter TLS apenas na borda. Pipeline recomendado:

```
Traefik (TLS) → Coraza (WAF) → Kong (TLS passthrough) → Istio (mTLS STRICT)
```

Checklist mínimo:

- `PeerAuthentication` e `DestinationRule` com `mode: STRICT` para serviços internos.
- Rotas de borda limitadas a Traefik → Coraza → Kong; exceções documentadas.
- Testes de smoke mTLS por módulo (handshake, cert rotation, fail-closed).

### 3. Divergência de versões internas

**Situação:** coexistem versões v0.2, v0.7, v0.10, v0.13, v0.15, indicando bases evolutivas distintas.

**Correção sugerida:**

- Uniformizar todos os manifests para `version: v0.3`.
- Adicionar bloco de metadados padronizado:

```
version: v0.3
schema: base44-stack
compatibility: full
```

- Validar compatibilidade em CI (lint de manifests + verificação de bloco de metadados).

## Recomendações de integração

| Área | Ação requerida | Resultado esperado |
| --- | --- | --- |
| .env | Centralizar variáveis globais em `.env.core` e referenciar via `source` | Build consistente e sem colisão de credenciais |
| TLS | Unificar mTLS STRICT no mesh e TLS na borda Traefik/Coraza/Kong | Comunicação interna segura e previsível |
| Namespaces | Validar nomes únicos e rótulos `appgear.io/*` | Evitar colisões em vCluster e garantir FinOps/auditoria |
| Argo CD | Consolidar ApplicationSets por workspace | Deploy homogêneo e governado por GitOps |
| Versionamento | Fixar baseline `v0.3` com bloco de metadados | Controle claro de compatibilidade entre módulos |
| Documentação | Publicar `stack-unificada-v0.3.yaml` e atualizar guias | Visão holística e rastreável da arquitetura |

## Próximos passos

1. Publicar `/config/.env.core` e adicionar importação explícita em todos os manifests/deploys.
2. Revisar gateways e policies para aplicar mTLS STRICT e remover passthrough interno residual.
3. Rodar lint automatizado para exigir bloco `version/schema/compatibility` em cada módulo.
4. Gerar manifesto `stack-unificada-v0.3.yaml` consolidando referências de versão, TLS/mTLS e cadeia de borda.
