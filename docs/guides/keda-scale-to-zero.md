# Guia de KEDA e Scale-to-Zero (Topologia B)

Padroniza parâmetros críticos de KEDA para workloads core e add-ons pesados. Todos os charts Helm/Kustomize devem trazer esses blocos como **default** (sem flags opcionais para desligar), garantindo scale-to-zero em ambientes de desenvolvimento e pequeno porte.

Estado atual: permanece obrigatório para módulos v0.3 (baseline em `development/v0.3/stack-unificada-v0.3.yaml`) e para a linha v0 de contrato/auditoria, junto com a cadeia Traefik → Coraza → Kong → Istio e o gateway de IA LiteLLM.

## Parâmetros globais

```yaml
keda:
  enabled: true
  minReplicaCount: 0
  maxReplicaCount: 3 # ajustar por workload
  pollingInterval: 15   # seg, otimizado para feedback rápido em dev
  cooldownPeriod: 90    # seg, pode subir a 120s em ingestão de logs
```

> Replicar os valores em `values.yaml` e `kustomization.yaml` dos módulos correspondentes. Ajustar apenas quando houver justificativa de capacidade/cold-start.

## Keycloak / midPoint

* **Triggers**
  * HTTP (KEDA HTTP add-on): `scaledobject.keda.sh/hosts: sso.<dominio>` com `targetPendingRequests: 5`.
  * Métrica Prometheus: `keycloak_sessions_active` ou `http_requests_total` filtrado pelo serviço.
  * Fila (quando midPoint usa tarefas assíncronas): `rabbitmqQueueLength` ou `kafka` conforme broker configurado.
* **Observações**
  * `ScaledObject`/`ScaledJob` devem apontar para os Services `keycloak-http` e `midpoint-http`.
  * `cooldownPeriod: 90s` para evitar churn durante picos curtos de login.

## Ceph Gateways e Brokers

* **Triggers**
  * HTTP para RGW/ingress expondo S3: `targetPendingRequests: 10`.
  * Métrica de latência de operação (`ceph_objecter_op_r` via Prometheus) como gatilho secundário.
  * Fila para jobs de manutenção (rebalanceamento/backup) via `ScaledJob` com `queueLength` (RabbitMQ/Redpanda).
* **Defaults**
  * `pollingInterval: 15s`, `cooldownPeriod: 120s` para permitir drenagem segura.
  * Aplicar o bloco `keda:` em `values.yaml` dos gateways e nos overlays Kustomize dos brokers.

## Istio / Borda

* **Escopo**: gateways Ingress/Egress e proxies expostos (Traefik/Coraza/Istio). Sidecars de aplicação não são escalados individualmente, mas os deployments de gateway devem seguir o padrão.
* **Triggers**
  * HTTP (RPS) com `targetPendingRequests: 10`.
  * Métrica de tráfego (`istio_requests_total` filtrada por gateway) para ambientes sem add-on HTTP.
* **Defaults**
  * `cooldownPeriod: 60–90s`, `pollingInterval: 15s`, `minReplicaCount: 0`.

## Observabilidade (Loki/ELK)

* **Triggers**
  * HTTP para Loki Gateway ou ingest endpoint (`targetPendingRequests: 20`).
  * Prometheus: `loki_ingester_request_duration_seconds_count` ou `log_entries_total` como métrica de ingestão.
  * Fila: `ScaledJob` consumindo backlog em Redpanda/RabbitMQ quando existir buffer.
* **Defaults**
  * `minReplicaCount: 0`, `maxReplicaCount: 5`, `cooldownPeriod: 120s`, `pollingInterval: 15s`.
  * Manter o bloco `keda:` habilitado em charts/overlays de Promtail/Beats/Loki.

## Checklist de governança

- [ ] `values.yaml` e `kustomization.yaml` publicados com KEDA ativo e `minReplicaCount: 0`.
- [ ] Triggers documentados por componente (HTTP, fila, métrica) no repositório.
- [ ] `cooldownPeriod`/`pollingInterval` auditáveis e revisados a cada release.
- [ ] Dashboards de observabilidade incluem painéis de status dos `ScaledObjects`.
