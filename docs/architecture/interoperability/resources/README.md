# Recursos de interoperabilidade

> [!IMPORTANT]
> **PASTA OFICIAL DE RECURSOS DA DIRETRIZ DE INTEROPERABILIDADE**  
>  
> Esta pasta complementa o documento `docs/architecture/interoperability/interoperability-v0.md` e deve concentrar **todos os artefatos auxiliares** usados para documentar e manter a interoperabilidade da AppGear (mapas, matrizes e fluxos AI-first).

---

## O que é

Esta pasta armazena os arquivos de **apoio** à Diretriz de Interoperabilidade, servindo como:

- ponto único para mapas Core x Suítes;
- matriz de interoperabilidade por módulo;
- descrição de fluxos AI-first ponta a ponta.

Ela **não substitui** o documento normativo `interoperability-v0.md`, mas organiza os detalhes operacionais em arquivos menores e reutilizáveis.

---

## Por que

Manter estes recursos separados em `resources/` permite:

- evitar que o `interoperability-v0.md` cresça demais;
- atualizar mapas, matrizes e fluxos sem alterar o texto normativo principal;
- facilitar uso por ferramentas (scripts, IA, validadores) que consomem YAML/MD específicos;
- ter um lugar padrão para **evidências complementares** de interoperabilidade.

---

## Arquivos esperados

Esta pasta deve conter, no mínimo:

- `mapa-global.md`  
  – Descreve o **mapa Core x Suítes**, listando componentes do Stack Core e Suítes (Factory, Brain, Operations, Guardian) e como se relacionam.

- `modulos.yaml`  
  – Matriz de interoperabilidade por módulo (M00–M17), indicando:
  - quais componentes Core/Suítes cada módulo usa;
  - integrações HTTP (Kong/Istio), eventos (Redpanda/RabbitMQ) e dados (Postgres, Qdrant, etc.);
  - aspectos de multi-tenancy, segurança e observabilidade relacionados a cada módulo.

- `fluxos-ai-first.md`  
  – Descreve os **fluxos ponta a ponta AI-first** (por exemplo: Backstage → n8n → Flowise → LiteLLM → Argo → vCluster → Suítes), além de fluxos críticos como:
  - DR/backup e restauração;
  - fluxos Edge/KubeEdge;
  - fluxos de telemetria e eventos.

Outros arquivos podem ser adicionados, desde que referenciados em `interoperability-v0.md` e/ou nos módulos de desenvolvimento.

---

## Como usar

1. Leia primeiro o documento principal:

   ```text
   docs/architecture/interoperability/interoperability-v0.md
````

2. Ao precisar de detalhes de integrações:

   * consulte `mapa-global.md` para entender **quem conversa com quem** no nível Core/Suítes;
   * consulte `modulos.yaml` para entender, módulo a módulo, **quais dependências de interoperabilidade existem**;
   * consulte `fluxos-ai-first.md` para ver os fluxos ponta a ponta e seus pontos de integração.

3. Quando criar ou alterar uma integração relevante (novo módulo, nova suíte, novo fluxo AI-first):

   * atualize o módulo correspondente em `development/v0.3/**`;
   * **atualize também** os arquivos desta pasta para manter a documentação de interoperabilidade consistente.

---

## Como manter

Sempre que houver mudanças em:

* Stack Core;
* Suítes (Factory, Brain, Operations, Guardian);
* módulos M00–M17;
* fluxos AI-first críticos;

verifique se é necessário atualizar:

* `mapa-global.md`;
* `modulos.yaml`;
* `fluxos-ai-first.md`;
* e, se for o caso, o próprio `interoperability-v0.md`.

Recomenda-se que PRs de mudança em interoperabilidade **sempre incluam**:

* ajustes nos módulos (`development/v0.3/**`);
* ajustes nos artefatos desta pasta (`resources/**`);
* a revisão correspondente na Diretriz de Interoperabilidade, quando houver impacto normativo.

---

## Onde salvar

Este arquivo deve permanecer em:

```text
docs/architecture/interoperability/resources/README.md
```

E esta pasta `resources/` é o **local único** para:

* mapas Core x Suítes;
* matrizes de interoperabilidade por módulo;
* fluxos AI-first;
* demais recursos auxiliares diretamente referenciados em:

```text
docs/architecture/interoperability/interoperability-v0.md