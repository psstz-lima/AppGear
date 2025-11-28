#!/bin/bash
################################################################################
# AppGear - End-to-End (E2E) Smoke Test
# Valida funcionalidade real dos serviços (não apenas se estão rodando)
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuração
LITELLM_URL="http://localhost:4000"
FLOWISE_URL="http://localhost:3000"
N8N_URL="http://localhost:5678"
MASTER_KEY="sk-appgear-master-key-2025-LiteL1M!"

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AppGear - E2E Smoke Test${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Função de teste
assert_success() {
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "  ${RED}❌ $1${NC}"
        return 1
    fi
}

# 1. Teste LiteLLM (Conectividade Básica)
echo -e "${YELLOW}1. Testando LiteLLM (Gateway IA)...${NC}"

# Healthcheck
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$LITELLM_URL/health")
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "401" ]; then
    echo -e "  ${GREEN}✅ Healthcheck (HTTP $HTTP_CODE)${NC}"
else
    echo -e "  ${RED}❌ Healthcheck falhou (HTTP $HTTP_CODE)${NC}"
fi

# Listar Modelos (Auth Test)
MODELS=$(curl -s -H "Authorization: Bearer $MASTER_KEY" "$LITELLM_URL/v1/models" | jq -r '.data | length')
if [ "$MODELS" -gt 0 ]; then
    echo -e "  ${GREEN}✅ Auth & List Models ($MODELS modelos encontrados)${NC}"
else
    echo -e "  ${RED}❌ Falha ao listar modelos${NC}"
fi

# Inferência Real (Groq)
echo -n "  ⏳ Testando inferência (llama-3.1-8b)... "
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -X POST "$LITELLM_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MASTER_KEY" \
  -d '{
    "model": "llama-3.1-8b",
    "messages": [{"role": "user", "content": "ping"}],
    "max_tokens": 5
  }' | jq -r '.choices[0].message.content')
END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME)/1000000))

if [[ "$RESPONSE" != "null" && -n "$RESPONSE" ]]; then
    echo -e "${GREEN}✅ Sucesso! (${DURATION}ms)${NC}"
    echo -e "     Resposta: \"$RESPONSE\""
else
    echo -e "${RED}❌ Falha na inferência${NC}"
fi
echo ""

# 2. Teste Flowise
echo -e "${YELLOW}2. Testando Flowise (Workflows)...${NC}"

# Healthcheck (Home page)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FLOWISE_URL")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "  ${GREEN}✅ Interface Web acessível${NC}"
else
    echo -e "  ${RED}❌ Interface inacessível (HTTP $HTTP_CODE)${NC}"
fi

# API Check (Stats)
STATS=$(curl -s "$FLOWISE_URL/api/v1/stats")
if [[ $? -eq 0 ]]; then
    echo -e "  ${GREEN}✅ API respondendo${NC}"
else
    echo -e "  ${RED}❌ API falhou${NC}"
fi
echo ""

# 3. Teste n8n
echo -e "${YELLOW}3. Testando n8n (Automação)...${NC}"

# Healthcheck
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$N8N_URL/healthz")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "  ${GREEN}✅ Healthcheck OK${NC}"
else
    echo -e "  ${RED}❌ Healthcheck falhou (HTTP $HTTP_CODE)${NC}"
fi
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Teste Concluído${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
