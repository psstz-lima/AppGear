#!/bin/bash
################################################################################
# AppGear - E2E Smoke Test (Topologia A Standard - Kubernetes)
# Valida saúde básica da stack Kubernetes
################################################################################

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurar KUBECONFIG
export KUBECONFIG=~/.kube/config

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AppGear - E2E Smoke Test (Kubernetes)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Função para cleanup
cleanup() {
    pkill -f "kubectl port-forward" > /dev/null 2>&1 || true
}
trap cleanup EXIT

PASSED=0
WARNINGS=0
FAILED=0

# 1. Verificar Pods
echo -e "${BLUE}[1/6]${NC} Verificando Pods..."
kubectl get pods -n appgear --no-headers > /tmp/appgear_pods.txt 2>/dev/null || echo "" > /tmp/appgear_pods.txt
kubectl get pods -n observability --no-headers > /tmp/obs_pods.txt 2>/dev/null || echo "" > /tmp/obs_pods.txt

APPGEAR_RUNNING=$(grep -c "Running" /tmp/appgear_pods.txt || echo "0")
OBS_RUNNING=$(grep -c "Running" /tmp/obs_pods.txt || echo "0")

if [ "$APPGEAR_RUNNING" -ge 6 ] && [ "$OBS_RUNNING" -ge 2 ]; then
    echo -e "  ${GREEN}✅ Todos os pods rodando ($APPGEAR_RUNNING appgear + $OBS_RUNNING observability)${NC}"
    ((PASSED++))
else
    echo -e "  ${RED}✗ Pods faltando (appgear: $APPGEAR_RUNNING/6, obs: $OBS_RUNNING/2)${NC}"
    ((FAILED++))
fi

# 2. Verificar Services
echo ""
echo -e "${BLUE}[2/6]${NC} Verificando Services..."
SERVICES=$(kubectl get svc -n appgear --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$SERVICES" -ge 5 ]; then
    echo -e "  ${GREEN}✅ Services criados ($SERVICES)${NC}"
    ((PASSED++))
else
    echo -e "  ${YELLOW}⚠ Services insuficientes ($SERVICES/5)${NC}"
    ((WARNINGS++))
fi

# 3. Verificar PVCs
echo ""
echo -e "${BLUE}[3/6]${NC} Verificando Storage..."
PVCS=$(kubectl get pvc -n appgear --no-headers 2>/dev/null | grep -c "Bound" || echo "0")
if [ "$PVCS" -ge 4 ]; then
    echo -e "  ${GREEN}✅ PVCs bound ($PVCS)${NC}"
    ((PASSED++))
else
    echo -e "  ${YELLOW}⚠ PVCs não bound ($PVCS/4)${NC}"
    ((WARNINGS++))
fi

# 4. Testar Conectividade LiteLLM
echo ""
echo -e "${BLUE}[4/6]${NC} Testando Conectividade LiteLLM..."
kubectl port-forward -n appgear svc/litellm 4000:4000 > /dev/null 2>&1 &
sleep 3

if curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/ 2>/dev/null | grep -q "200\|404\|401"; then
    echo -e "  ${GREEN}✅ LiteLLM respondendo${NC}"
    ((PASSED++))
else
    echo -e "  ${RED}✗ LiteLLM não acessível${NC}"
    ((FAILED++))
fi

# 5. Testar Prometheus
echo ""
echo -e "${BLUE}[5/6]${NC} Testando Prometheus..."
kubectl port-forward -n observability svc/prometheus 9090:9090 > /dev/null 2>&1 &
sleep 3

if curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy 2>/dev/null | grep -q "200"; then
    echo -e "  ${GREEN}✅ Prometheus healthy${NC}"
    ((PASSED++))
else
    echo -e "  ${RED}✗ Prometheus não healthy${NC}"
    ((FAILED++))
fi

# 6. Testar Grafana
echo ""
echo -e "${BLUE}[6/6]${NC} Testando Grafana..."
kubectl port-forward -n observability svc/grafana 3001:3000 > /dev/null 2>&1 &
sleep 3

if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/health 2>/dev/null | grep -q "200"; then
    echo -e "  ${GREEN}✅ Grafana healthy${NC}"
    ((PASSED++))
else
    echo -e "  ${RED}✗ Grafana não healthy${NC}"
    ((FAILED++))
fi

# Resumo
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}  ✅ Teste Completo - Stack Validada!${NC}"
else
    echo -e "${YELLOW}  ⚠ Teste Completo com Falhas${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Resultados:"
echo -e "  ${GREEN}✅ Passou: $PASSED${NC}"
echo -e "  ${YELLOW}⚠  Avisos: $WARNINGS${NC}"
echo -e "  ${RED}✗  Falhou: $FAILED${NC}"
echo ""

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
