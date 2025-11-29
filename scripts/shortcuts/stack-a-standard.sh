#!/bin/bash
################################################################################
# AppGear - Stack Manager (Topologia A Standard - Kubernetes)
# Atalho dedicado para gerenciamento da Topologia A Standard (K3s)
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/topology-a/standard"

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  AppGear - Stack Manager (A-Standard K8s)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

show_usage() {
    show_header
    echo "Uso: $0 <ação> [args...]"
    echo ""
    echo "Ações Principais:"
    echo "  install      Instala K3s (primeira vez)"
    echo "  deploy       Deploy completo da stack"
    echo "  status       Mostra status dos pods"
    echo "  cleanup      Remove todos os recursos"
    echo ""
    echo "Ações de Acesso:"
    echo "  ports        Cria port-forwards para acesso local"
    echo "  prometheus   Port-forward Prometheus (9090)"
    echo "  grafana      Port-forward Grafana (3001)"
    echo "  flowise      Port-forward Flowise (3000)"
    echo "  litellm      Port-forward LiteLLM (4000)"
    echo "  n8n          Port-forward n8n (5678)"
    echo ""
    echo "Comandos Úteis:"
    echo "  logs <pod>   Ver logs de um pod"
    echo "  shell <pod>  Abrir shell em um pod"
    echo ""
    echo "Exemplos:"
    echo "  $0 install"
    echo "  $0 deploy"
    echo "  $0 ports"
    echo "  $0 logs flowise"
    echo ""
}

# Verificar argumentos
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

ACTION=$1
shift 1

# Configurar KUBECONFIG
export KUBECONFIG=~/.kube/config

# Executar ação
case $ACTION in
    "install"|"setup")
        echo -e "${GREEN}Instalando K3s...${NC}"
        exec sudo "$DEPLOYMENT_DIR/scripts/setup-k3s-a-standard.sh"
        ;;
    
    "deploy"|"up")
        echo -e "${GREEN}Deployando Topologia A Standard...${NC}"
        exec "$DEPLOYMENT_DIR/scripts/deploy-stack-a-standard.sh"
        ;;
    
    "cleanup"|"down")
        echo -e "${YELLOW}Removendo recursos...${NC}"
        exec "$DEPLOYMENT_DIR/scripts/cleanup-stack-a-standard.sh"
        ;;
    
    "status"|"ps")
        echo -e "${BLUE}Status da Stack AppGear (K8s):${NC}"
        echo ""
        echo "Namespace: appgear"
        kubectl get pods -n appgear
        echo ""
        echo "Namespace: observability"
        kubectl get pods -n observability
        ;;
    
    "ports")
        echo -e "${GREEN}Criando port-forwards...${NC}"
        kubectl port-forward -n appgear svc/flowise 3000:3000 > /dev/null 2>&1 &
        kubectl port-forward -n appgear svc/litellm 4000:4000 > /dev/null 2>&1 &
        kubectl port-forward -n appgear svc/n8n 5678:5678 > /dev/null 2>&1 &
        kubectl port-forward -n observability svc/prometheus 9099:9090 > /dev/null 2>&1 &
        kubectl port-forward -n observability svc/grafana 3001:3000 > /dev/null 2>&1 &
        sleep 2
        echo -e "${GREEN}Port-forwards ativos:${NC}"
        echo "  • Flowise:    http://localhost:3000"
        echo "  • LiteLLM:    http://localhost:4000"
        echo "  • n8n:        http://localhost:5678"
        echo "  • Prometheus: http://localhost:9099"
        echo "  • Grafana:    http://localhost:3001 (admin/appgear_grafana_2025)"
        ;;
    
    "prometheus")
        kubectl port-forward -n observability svc/prometheus 9099:9090
        ;;
    
    "grafana")
        kubectl port-forward -n observability svc/grafana 3001:3000
        ;;
    
    "flowise")
        kubectl port-forward -n appgear svc/flowise 3000:3000
        ;;
    
    "litellm")
        kubectl port-forward -n appgear svc/litellm 4000:4000
        ;;
    
    "n8n")
        kubectl port-forward -n appgear svc/n8n 5678:5678
        ;;
    
    "logs")
        if [ $# -lt 1 ]; then
            echo "Uso: $0 logs <pod-prefix>"
            echo "Exemplo: $0 logs flowise"
            exit 1
        fi
        POD_PREFIX=$1
        kubectl logs -f -n appgear -l app="$POD_PREFIX" --tail=50
        ;;
    
    "shell")
        if [ $# -lt 1 ]; then
            echo "Uso: $0 shell <pod-prefix>"
            echo "Exemplo: $0 shell flowise"
            exit 1
        fi
        POD_PREFIX=$1
        POD=$(kubectl get pods -n appgear -l app="$POD_PREFIX" -o jsonpath='{.items[0].metadata.name}')
        kubectl exec -it -n appgear "$POD" -- /bin/sh
        ;;
    
    *)
        echo -e "${RED}Erro: Ação '$ACTION' não reconhecida${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
