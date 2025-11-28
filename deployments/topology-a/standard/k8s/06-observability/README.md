# Observabilidade - Instalação Manual

Devido a problemas de rede ao baixar o Helm chart completo do kube-prometheus-stack, vamos usar uma abordagem simplificada com manifests manuals.

## Opções de Instalação

### Opção 1: Prometheus + Grafana via Manifests (Lightweight)
Criar manifestos YAML simples para Prometheus e Grafana sem todas as dependências do kube-prometheus-stack.

**Vantagens:**
- Instalação rápida
- Menor consumo de recursos
- Sem dependência de downloads externos

### Opção 2: Tentar novamente kube-prometheus-stack mais tarde
Aguardar resolução de problemas de rede e tentar install via Helm novamente.

### Opção 3: Usar port-forward direto com Prometheus standalone
Deploy apenas do Prometheus em modo simples para teste.

## Status Atual

A stack AppGear está funcional sem observabilidade por enquanto. Podemos:
1. Continuar sem observabilidade e voltar depois
2. Implementar uma versão simplificada agora
3. Pular para Gateways (Traefik/Kong)

## Recomendação

Dado que a stack está rodando e funcional, sugiro **pular observabilidade por agora** e focar em:
- Implementar Gateways (Traefik/Kong) para expor serviços via Ingress
- Criar testes E2E adaptados para Kubernetes
- Documentar uso da stack K8s

Observabilidade pode ser adicionada depois quando a rede estiver mais estável.
