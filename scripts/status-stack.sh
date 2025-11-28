#!/bin/bash
################################################################################
# AppGear Stack Status Script
# Mostra o status detalhado de todos os serviços
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AppGear Stack - Status${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Função para verificar container
check_container() {
    local name=$1
    local expected_port=$2
    
    if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
        local status=$(docker ps --format '{{.Status}}' -f "name=^${name}$")
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$name" 2>/dev/null || echo "none")
        
        if [ "$health" = "healthy" ]; then
            echo -e "  ${GREEN}✅ $name${NC} - $status (healthy)"
        elif [ "$health" = "unhealthy" ]; then
            echo -e "  ${YELLOW}⚠️  $name${NC} - $status (unhealthy)"
        else
            echo -e "  ${GREEN}✅ $name${NC} - $status"
        fi
        
        if [ -n "$expected_port" ]; then
            if curl -s -f "http://localhost:$expected_port" > /dev/null 2>&1 || curl -s "http://localhost:$expected_port" | grep -q "."; then
                echo -e "     ${GREEN}→${NC} Porta $expected_port acessível"
            else
                echo -e "     ${YELLOW}→${NC} Porta $expected_port não responde"
            fi
        fi
    else
        echo -e "  ${RED}❌ $name${NC} - Não está rodando"
    fi
}

echo -e "${CYAN}━━━ Infraestrutura ━━━${NC}"
check_container "appgear-postgres" "5432"
check_container "appgear-redis" "6379"
echo ""

echo -e "${CYAN}━━━ Gateways e Proxy ━━━${NC}"
check_container "appgear-traefik" "8080"
check_container "appgear-kong" "8001"
echo ""

echo -e "${CYAN}━━━ AI Gateway ━━━${NC}"
check_container "appgear-litellm" "4000"
echo ""

echo -e "${CYAN}━━━ Aplicações ━━━${NC}"
check_container "appgear-flowise" "3000"
check_container "appgear-n8n" "5678"
echo ""

# Resumo
RUNNING=$(docker ps --filter "name=appgear-" --format "{{.Names}}" | wc -l)
TOTAL=7

echo -e "${CYAN}━━━ Resumo ━━━${NC}"
if [ "$RUNNING" -eq "$TOTAL" ]; then
    echo -e "  ${GREEN}✅ Todos os $TOTAL serviços estão rodando${NC}"
elif [ "$RUNNING" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠️  $RUNNING de $TOTAL serviços rodando${NC}"
else
    echo -e "  ${RED}❌ Nenhum serviço rodando${NC}"
fi
echo ""

# Uso de recursos
echo -e "${CYAN}━━━ Recursos ━━━${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps --filter "name=appgear-" -q) 2>/dev/null || echo "  Nenhum container rodando"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
