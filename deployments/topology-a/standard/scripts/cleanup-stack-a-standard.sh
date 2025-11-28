#!/bin/bash
################################################################################
# AppGear - Cleanup Stack (Topologia A Standard)
# Remove todos os recursos Kubernetes
################################################################################

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  AppGear - Cleanup Stack (Kubernetes)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

read -p "Deseja remover TODOS os recursos da stack AppGear? [s/N] " -r
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo ""
read -p "Deseja MANTER os PVCs (dados persistentes)? [S/n] " -r
KEEP_PVC=true
if [[ $REPLY =~ ^[Nn]$ ]]; then
    KEEP_PVC=false
fi

echo ""
echo -e "${BLUE}Removendo recursos...${NC}"

# Matar port-forwards
pkill -f "kubectl port-forward" || true

# Remover deployments e services
kubectl delete -f deployments/topology-a/standard/k8s/05-apps/ || true
kubectl delete -f deployments/topology-a/standard/k8s/04-ai/ || true
kubectl delete -f deployments/topology-a/standard/k8s/02-databases/ || true

# Remover PVCs se solicitado
if [ "$KEEP_PVC" = false ]; then
    echo -e "${YELLOW}Removendo PVCs (dados serão perdidos)...${NC}"
    kubectl delete pvc -n appgear --all
fi

# Remover secrets e namespace (opcional)
read -p "Deseja remover o namespace 'appgear' (remove secrets também)? [s/N] " -r
if [[ $REPLY =~ ^[Ss]$ ]]; then
    kubectl delete namespace appgear
    echo -e "${GREEN}✅ Namespace removido${NC}"
else
    echo -e "${GREEN}✅ Namespace mantido${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Cleanup Completo!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
