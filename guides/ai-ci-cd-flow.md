# Fluxo CI/CD com Validação Automática por IA

Versão: v1.1

Este documento operacionaliza o **Procedimento Operacional – Aplicação das Melhorias no Pipeline CI/CD (v1.1)**, definindo fluxos, artefatos e responsabilidades para garantir que todas as entregas AppGear sejam validadas por IA, versionadas e auditáveis.

## Estado atual

- Fluxo aplica-se às correções v0.3 e mantém o gate automatizado da IA + RAPID/CCB sem ampliar o escopo de entrega.
- **Escopo**: linha v0 como baseline estável, módulos v0.3 em retrofit e guias interoperabilidade/auditoria alinhados ao `development/v0.3/stack-unificada-v0.3.yaml`.
- **Borda**: cadeia Traefik → Coraza → Kong → Istio (mTLS STRICT) permanece obrigatória, bem como LiteLLM como gateway único de IA e KEDA para cargas não 24/7.
- **Artefatos**: `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` com hashes SHA-256, parecer automatizado de IA e registro RAPID/CCB são pré-condições para liberar qualquer entrega.

---

## 1. Escopo

- Todas as branches e pipelines CI/CD do ecossistema AppGear (documentação, infraestrutura, serviços e suítes).
- Ambientes: Dev, Homologação, Produção em Topologia B (Kubernetes) e, quando necessário, Topologia A (PoC/legado).
- Artefatos mínimos: relatórios da IA, SBOM, cobertura, testes, imagens e pareceres RAPID/CCB.

---

## 2. Estrutura Canônica de Artefatos

Todos os pipelines devem publicar e versionar artefatos em estrutura única:

```
/artifacts
  /ai_reports       # respostas da IA (score, recomendações, bloqueios/liberações)
  /reports          # relatórios SARIF/JSON e outputs executivos
  /coverage         # métricas de teste/cobertura
  /tests            # logs e evidências de teste funcional/integrado
  /docker           # manifests de imagens, hashes e listas de reprodução
  /sbom             # SBOM JSON/XML/CycloneDX com hash SHA-256
```

Regras:
- Hash **SHA-256 obrigatório** para todos os arquivos publicados.
- Retenção mínima: **90 dias**; manter ACL para acesso auditável.
- Indexar artefatos por pipeline, branch e commit para rastreabilidade.

---

## 3. Fluxo Automatizado

1. **Coleta de insumos**
   - Código, diffs, dependências e metadados (commit, branch, autor).
2. **Envio para IA corporativa**
   - API dedicada recebe pacote e retorna **score de risco**, **classificação de impacto** e **parecer de bloqueio/liberação**.
3. **Gate de decisão**
   - Pipelines **falham automaticamente** quando a IA recomendar bloqueio.
   - Para liberações condicionais, registrar justificativa e responsável (RAPID/CCB).
4. **Geração de SBOM**
   - Produzir JSON, XML e CycloneDX equivalentes; registrar hash SHA-256 em `/artifacts/sbom`.
5. **Testes e cobertura**
   - Publicar métricas ≥85% (baseline) em `/artifacts/coverage`; logs em `/artifacts/tests`.
6. **Relatórios e publicação**
   - Persistir respostas da IA em `/artifacts/ai_reports`.
   - Consolidar SARIF/JSON e relatórios executivos em `/artifacts/reports`.
7. **Governança e auditoria**
   - Registrar decisão RAPID/CCB e parecer da IA.
   - Indexar links bidirecionais para o build no sistema de CI.

---

## 4. Responsabilidades e RACI

| Atividade                               | DevOps | QA | Segurança | Gestão |
| --------------------------------------- | ------ | -- | --------- | ------ |
| Operar pipeline e publicar artefatos    | R      | C  | I         | I      |
| Validar parecer da IA e aplicar bloqueio| R      | C  | A         | I      |
| Revisar cobertura e testes              | C      | A  | I         | I      |
| Aprovar exceções (RAPID/CCB)            | C      | I  | C         | A      |
| Revisar SBOM e hashes                   | R      | C  | A         | I      |

Legenda: **R = Responsible | A = Accountable | C = Consulted | I = Informed**

---

## 5. Checklist Operacional por Pipeline

- [ ] Envio para IA com metadados completos (commit, branch, autor, pacote de dependências).
- [ ] Parecer da IA armazenado em `/artifacts/ai_reports/*.json` com hash registrado.
- [ ] Gate automático de bloqueio/approvação aplicado conforme recomendação.
- [ ] SBOM JSON/XML/CycloneDX em `/artifacts/sbom` com hash SHA-256.
- [ ] Logs de testes e cobertura (≥85%) publicados em `/artifacts/tests` e `/artifacts/coverage`.
- [ ] Relatórios SARIF/JSON versionados em `/artifacts/reports`.
- [ ] Registro da decisão RAPID/CCB vinculado ao build.
- [ ] Retenção e ACL documentadas (≥90 dias).

---

## 6. Fluxo de Exceção e Auditoria

1. **Exceção solicitada**: equipe registra motivo, risco residual e duração da exceção.
2. **Validação**: Segurança revisa; IA reavalia o risco com contexto da exceção.
3. **Decisão**: CCB valida ou rejeita; todas as decisões ficam registradas em `/artifacts/reports`.
4. **Revisão periódica**: exceções são revalidadas a cada sprint ou antes de releases críticas.

---

## 7. Integrações recomendadas

- **CI**: GitHub Actions / GitLab CI com jobs para coleta, envio à IA, SBOM e publicação de artefatos.
- **IA**: endpoint corporativo com autenticação de serviço; fallback controlado para ambientes isolados.
- **Observabilidade**: dashboards exibindo tendência de risco, decisões da IA e maturidade do pipeline.
- **ITSM**: registro automático de mudança/versionamento quando infraestrutura do pipeline for alterada.

---

## 8. Evidências mínimas para auditoria

- Relatório da IA (JSON) com timestamp e identificação do build.
- Hashes SHA-256 de SBOMs e relatórios principais.
- Print/ID do job de CI comprovando aplicação do gate automatizado.
- Decisão RAPID/CCB registrada e vinculada ao pipeline.
- Retenção e ACL documentadas no repositório de artefatos.
