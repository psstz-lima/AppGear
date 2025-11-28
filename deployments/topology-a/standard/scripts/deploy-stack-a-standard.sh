#!/bin/bash
################################################################################
# AppGear - Deploy Stack (Topologia A Standard)
# Aplica todos os manifestos Kubernetes na ordem correta
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/../k8s" && pwd)"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AppGear - Deploy Stack (Kubernetes)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# ⚠️  VERIFICAÇÃO DE CONFLITO: Topologia Minimal (Docker Compose)
DOCKER_CONTAINERS=$(docker ps --filter "name=appgear-" --format "{{.Names}}" 2>/dev/null | wc -l)
if [ "$DOCKER_CONTAINERS" -gt 0 ]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           ⚠️  CONFLITO DE TOPOLOGIAS DETECTADO            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}A Topologia A Minimal (Docker Compose) está rodando com $DOCKER_CONTAINERS containers.${NC}"
    echo ""
    docker ps --filter "name=appgear-" --format "  • {{.Names}} ({{.Status}})"
    echo ""
    echo -e "${RED}ERRO:${NC} Não é possível iniciar a Topologia A Standard (Kubernetes)"
    echo -e "enquanto a Minimal está ativa devido a conflitos de:"
    echo ""
    echo "  • Portas (3000, 4000, 5678, 5432, 6379)"
    echo "  • Recursos (CPU, Memória)"
    echo "  • Dados (PostgreSQL, Redis)"
    echo ""
    echo -e "${BLUE}Soluções:${NC}"
    echo ""
    echo "  1. Parar a Topologia Minimal primeiro:"
    echo -e "     ${GREEN}./scripts/shortcuts/stack-a-minimal.sh stop${NC}"
    echo ""
    echo "  2. Ou use apenas a Minimal (já está rodando):"
    echo -e "     ${GREEN}# Acesse: http://localhost:3000 (Flowise)${NC}"
    echo ""
    exit 1
fi

# Verificar se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}[ERRO]${NC} kubectl não encontrado. Instale o K3s primeiro:"
    echo "  sudo ./setup-k3s-a-standard.sh"
    exit 1
fi

# Verificar se K3s está rodando
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}[ERRO]${NC} Kubernetes cluster não está acessível"
    exit 1
fi

echo -e "${BLUE}[1/6]${NC} Criando namespace e secrets..."
kubectl apply -f "$K8S_DIR/00-namespaces/"
sleep 2

echo -e "${BLUE}[2/6]${NC} Deployando bancos de dados (PostgreSQL, Redis)..."
kubectl apply -f "$K8S_DIR/02-databases/"
echo "  Aguardando PostgreSQL ficar ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n appgear --timeout=120s
echo "  Aguardando Redis ficar ready..."
kubectl wait --for=condition=ready pod -l app=redis -n appgear --timeout=60s
echo -e "  ${GREEN}✅${NC} Bancos de dados prontos"

echo ""
echo -e "${BLUE}[3/6]${NC} Deployando AI Gateway (LiteLLM)..."
kubectl apply -f "$K8S_DIR/04-ai/"
echo "  Aguardando LiteLLM ficar ready..."
kubectl wait --for=condition=ready pod -l app=litellm -n appgear --timeout=120s
echo -e "  ${GREEN}✅${NC} LiteLLM pronto"

echo ""
echo -e "${BLUE}[4/6]${NC} Deployando aplicações (Flowise, n8n)..."
kubectl apply -f "$K8S_DIR/05-apps/"
echo "  Aguardando Flowise ficar ready..."
kubectl wait --for=condition=ready pod -l app=flowise -n appgear --timeout=180s
echo "  Aguardando n8n ficar ready..."
kubectl wait --for=condition=ready pod -l app=n8n -n appgear --timeout=120s
echo -e "  ${GREEN}✅${NC} Aplicações prontas"

echo ""
echo -e "${BLUE}[5/6]${NC} Expondo serviços via port-forward..."
# Criar port-forwards em background
kubectl port-forward -n appgear svc/flowise 3000:3000 &
kubectl port-forward -n appgear svc/litellm 4000:4000 &
kubectl port-forward -n appgear svc/n8n 5678:5678 &
sleep 3
echo -e "  ${GREEN}✅${NC} Port-forwards ativos"

echo ""
echo -e "${BLUE}[6/6]${NC} Verificando status..."
kubectl get pods -n appgear

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Deploy Completo!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Serviços disponíveis:${NC}"
echo "  • Flowise:  http://localhost:3000"
echo "  • LiteLLM:  http://localhost:4000"
echo "  • n8n:      http://localhost:5678"
echo ""
echo -e "${BLUE}Comandos úteis:${NC}"
echo "  kubectl get pods -n appgear           # Ver pods"
echo "  kubectl logs -f <pod> -n appgear      # Ver logs"
echo "  kubectl describe pod <pod> -n appgear # Debug"
echo ""
