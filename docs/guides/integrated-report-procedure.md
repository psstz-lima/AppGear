# 📘 Procedimento Operacional – Aplicação das Melhorias no Pipeline CI/CD

## Classificação: CONFIDENCIAL

## Norma de Referência: ISO/IEC 27001 – NBR 27000 – Governança e Segurança da Informação

## Versão: 1.2

---

# 1. Objetivo

Estabelecer instruções formais, detalhadas e rastreáveis para implementação das melhorias no pipeline CI/CD, **removendo a obrigatoriedade de scanners tradicionais**, uma vez que a verificação de segurança será realizada por **mecanismos de IA corporativa**, garantindo conformidade, governança e rastreamento contínuo.

### Estado atual

- Procedimento operacional ajustado ao retrofit v0.3, mantendo hashes e estrutura de artefatos sem novas capacidades.
- Aplicação imediata sobre a linha **v0** (baseline estável) e retrofits **v0.3** dos módulos 00–17, tendo `development/v0.3/stack-unificada-v0.3.yaml` como referência única.
- Cadeia **Traefik → Coraza → Kong → Istio (mTLS STRICT)**, **LiteLLM** como gateway único de IA e **KEDA** como política padrão de escala para workloads não 24/7 permanecem mandatórios.
- Publicação de artefatos em `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` com hash **SHA-256** e registro do parecer automatizado da IA + RAPID/CCB é requisito de conformidade.

### Evidências de aplicação e lacunas

- **Fluxo CI/CD IA documentado** (`guides/ai-ci-cd-flow.md`) e referenciado nos documentos raiz (`README.md`, `MANIFESTO.md`, `STATUS-ATUAL.md`).
- **Evidências ainda não rastreadas** para execução real do gate de IA, geração de SBOM e retenção de artefatos em builds recentes; exigir anexação em `/artifacts` para cada pipeline.
- **Mapeamento de retrofit** concluído até módulos 05 na linha v0.1; módulos 06–12 em andamento e 13–17 pendentes de aplicação do checklist.

---

# 2. Escopo

Aplica-se às áreas de **Engenharia, DevOps, Segurança e QA**, abrangendo:

* Análise automatizada de segurança baseada em IA
* Eliminação de scans manuais ou ferramentas dedicadas
* Geração automática de alertas e relatórios
* Aumento da rastreabilidade das evidências
* Padronização de documentação de auditoria

---

# 3. Premissas

* A IA corporativa será responsável por análise de vulnerabilidades, riscos e fraudes em código e imagens.
* Todos os resultados devem ser automaticamente armazenados como evidências auditáveis.
* Geração de insights deve ocorrer em tempo real, com registro versionado.

---

# 4. Instruções Operacionais por Fase

## 4.1 Atualização da Infraestrutura CI/CD

### 4.1.1 Procedimentos

1. Validar que a plataforma CI integra-se com o componente de IA responsável por validação de segurança.
2. Configurar o armazenamento padronizado:

```
/artifacts
  /ai_reports
  /coverage
  /docker
  /tests
  /reports
```

3. Registrar em ferramenta ITSM a mudança de versão operacional.

### 4.1.2 Evidências

* Log de habilitação do módulo de IA
* Registro formal da change

---

## 4.2 Análise de Segurança Automatizada via IA

### 4.2.1 Execução

1. Em cada build, enviar código, diffs, dependências e metadados para o motor IA.

2. A IA retornará:

   * Score de risco da mudança
   * Classificação de impacto
   * Sugestões técnicas
   * Recomendação de bloqueio ou liberação

3. O pipeline deverá:

   * Rejeitar ou aprovar o build conforme decisão automatizada do motor de IA.
   * Armazenar o relatório retornado como evidência.

### 4.2.2 Evidências

* Relatório gerado em `/artifacts/ai_reports/*.json`
* Link reverso para o build analisado
* Acionamento do workflow automatizado

---

## 4.3 Geração e Publicação de SBOM (Sem Scanners Tradicionais)

### 4.3.1 Procedimentos

1. O motor de IA deverá extrair automaticamente a composição de dependências.
2. Gerar arquivo em formato:

* JSON
* XML
* CycloneDX equivalente

3. Registrar o hash SHA-256 para controle de integridade.

### 4.3.2 Critérios de Aceite

* SBOM gerado para 100% dos builds
* Referência cruzada entre SBOM e número de pipeline

---

## 4.4 Padronização de Relatórios e Auditoria

### 4.4.1 Procedimentos

1. Consolidar:

   * Parecer técnico de IA
   * Matriz de riscos
   * Registros de falhas
   * Métricas de build
   * Cobertura de testes

2. Todos os relatórios devem ser:

   * Versionados
   * Indexados
   * Disponíveis para auditoria interna e externa

### 4.4.2 Critérios

* Tempo de retenção ≥ 90 dias
* Acesso controlado por ACL

---

## 4.5 KPI de Qualidade

1. Manter cobertura mínima de 85%.
2. IA deve informar taxa de risco residual.
3. Panéis executivos devem exibir:

   * Tendência de risco por sprint
   * Velocidade de resolução
   * Índice de maturidade do pipeline

---

## 4.6 Governança e Workflow Decisório

Toda mudança deve seguir:

1. Abertura de RFC formal.
2. Validação da IA antes de submissão ao CCB.
3. Cadeia RAPID:

* Recommend – DevOps/Engenharia
* Agree – Segurança
* Perform – DevOps
* Input – QA e IA
* Decide – Comitê CCB

4. Registro obrigatório de aprovação.

---

# 5. Checklist de Execução

| Item                           | Obrigatório | Status verificado |
| ------------------------------ | ----------- | ----------------- |
| Validação automática por IA    | Sim         | Parcial – fluxo publicado (`guides/ai-ci-cd-flow.md`), execução por pipeline sem evidência em `/artifacts/ai_reports`. |
| SBOM gerado                    | Sim         | Não evidenciado – formato e hash definidos, porém falta comprovação de builds recentes. |
| Relatório automatizado emitido | Sim         | Parcial – exigido em guias e raízes, pendente registro consolidado por pipeline. |
| Evidências armazenadas         | Sim         | Em implantação – estrutura `/artifacts/{ai_reports,reports,coverage,tests,docker,sbom}` definida; ausência de amostras anexadas. |
| Parecer do CCB                 | Sim         | Não evidenciado – processo RAPID/CCB descrito, mas sem atas ou referências em `/artifacts/reports`. |

---

# 6. Riscos de Não Conformidade

A ausência do processo pode gerar:

* Falta de rastreabilidade
* Não atendimento aos requisitos de auditoria ISO/NBR
* Imprecisão na análise de risco
* Falha de governança evolutiva

---

# 7. Critério de Aceitação Final

O pipeline será considerado **conforme** quando:

* A IA tiver analisado 100% das entregas
* Relatórios e SBOM forem versionados
* Aprovação do CCB registrada
* Evidências estiverem disponíveis para auditoria

---

# 8. Encerramento

Após implementação:

* Emissão de relatório final
* Registro de mudança como concluída
* Disponibilização dos relatórios para auditor externo
