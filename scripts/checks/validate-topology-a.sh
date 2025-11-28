#!/bin/bash
# validate-topology-a.sh - Script de validação para Topologia A (Docker Compose)

set -e

echo "🔍 Validação da Topologia A - AppGear"
echo "===================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para checar se serviço está rodando
check_service() {
    local service=$1
    if docker-compose ps | grep -q "$service.*Up"; then
        echo -e "${GREEN}✓${NC} $service está rodando"
        return 0
    else
        echo -e "${RED}✗${NC} $service NÃO está rodando"
        return 1
    fi
}

# Função para checar porta
check_port() {
    local service=$1
    local port=$2
    local url=$3
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✓${NC} $service acessível em porta $port"
        return 0
    else
        echo -e "${RED}✗${NC} $service NÃO acessível em porta $port"
        return 1
    fi
}

# Mudar para diretório correto
DEPLOYMENT_DIR="deployments/topology-a/minimal"
if [ ! -d "$DEPLOYMENT_DIR" ]; then
    echo -e "${RED}✗${NC} Diretório $DEPLOYMENT_DIR não encontrado"
    exit 1
fi

cd "$DEPLOYMENT_DIR" || exit 1
echo -e "${GREEN}✓${NC} Diretório $DEPLOYMENT_DIR encontrado"

# Verificar se docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗${NC} docker-compose.yml não encontrado"
    exit 1
fi

echo -e "${GREEN}✓${NC} docker-compose.yml encontrado"
echo ""

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC} .env não encontrado (usando .env.example se disponível)"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✓${NC} .env criado a partir de .env.example"
    fi
else
    echo -e "${GREEN}✓${NC} .env encontrado"
fi
echo ""

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Docker não está rodando"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker está rodando"
echo ""

# 1. Validação de Serviços Core
echo "📦 Validando Serviços Core:"
echo "-------------------------"

SERVICES=(
    "traefik"
    "kong"
    "postgres"
    "redis"
    "litellm"
    "flowise"
    "n8n"
)

for service in "${SERVICES[@]}"; do
    check_service "$service" || true
done
echo ""

# 2. Validação de Rede
echo "🌐 Validando Configuração de Rede:"
echo "--------------------------------"

if docker network ls | grep -q "appgear-net-core"; then
    echo -e "${GREEN}✓${NC} Rede appgear-net-core criada"
else
    echo -e "${YELLOW}⚠${NC} Rede appgear-net-core não encontrada (será criada no up)"
fi
echo ""

# 3. Validação de Acessibilidade
echo "🔌 Validando Acessibilidade de Serviços:"
echo "--------------------------------------"

# Esperar um pouco para serviços iniciarem
sleep 5

check_port "Traefik Dashboard" "8080" "http://localhost:8080" || true
check_port "Kong Admin API" "8001" "http://localhost:8001" || true
check_port "Flowise" "3000" "http://localhost:3000" || true
check_port "n8n" "5678" "http://localhost:5678" || true
echo ""

# 4. Validação de Volumes
echo "💾 Validando Volumes Persistentes:"
echo "--------------------------------"

VOLUMES=$(docker volume ls --format '{{.Name}}' | grep appgear || true)
if [ -z "$VOLUMES" ]; then
    echo -e "${YELLOW}⚠${NC} Nenhum volume appgear encontrado (serão criados no up)"
else
    echo -e "${GREEN}✓${NC} Volumes encontrados:"
    echo "$VOLUMES" | sed 's/^/  - /'
fi
echo ""

# 5. Validação de Config.yaml LiteLLM
echo "🤖 Validando Configuração LiteLLM:"
echo "--------------------------------"

if docker-compose exec -T litellm ls /app/config.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} config.yaml do LiteLLM encontrado"
else
    echo -e "${YELLOW}⚠${NC} config.yaml do LiteLLM não encontrado ou serviço não iniciado"
fi
echo ""

# 6. Validação de Banco de Dados
echo "🗄️  Validando PostgreSQL:"
echo "----------------------"

if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PostgreSQL está pronto para conexões"
else
    echo -e "${RED}✗${NC} PostgreSQL não está pronto"
fi
echo ""

# 7. Validação de Redis
echo "⚡ Validando Redis:"
echo "----------------"

if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
    echo -e "${GREEN}✓${NC} Redis respondendo"
else
    echo -e "${RED}✗${NC} Redis não respondendo"
fi
echo ""

# 8. Checklist de Documentação
echo "📚 Checklist de Documentação:"
echo "---------------------------"

DOCS=(
    "README-topology-a.md"
    ".env.example"
    "docker-compose.yml"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓${NC} $doc existe"
    else
        echo -e "${RED}✗${NC} $doc não encontrado"
    fi
done
echo ""

# 9. Validação de Cadeia de Borda
echo "🛡️  Validando Cadeia de Borda:"
echo "----------------------------"

echo "Verificando rota: Traefik → Kong → Serviços"

# Verificar se Traefik está roteando para Kong
if curl -s http://localhost/api 2>/dev/null | grep -q "Kong\|no route"; then
    echo -e "${GREEN}✓${NC} Traefik → Kong OK"
else
    echo -e "${YELLOW}⚠${NC} Roteamento Traefik → Kong não verificado"
fi
echo ""

# 10. Relatório Final
echo "📊 Relatório Final:"
echo "=================="

RUNNING=$(docker-compose ps | grep "Up" | wc -l)
TOTAL=$(docker-compose ps | tail -n +3 | wc -l)

echo "Serviços rodando: $RUNNING/$TOTAL"

if [ "$RUNNING" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo -e "${GREEN}✓✓✓ Topologia A está FUNCIONANDO!${NC}"
    echo ""
    echo "🎉 Próximos passos:"
    echo "  1. Acessar Flowise: http://localhost:3000"
    echo "  2. Acessar n8n: http://localhost:5678"
    echo "  3. Testar workflow de exemplo"
    exit 0
elif [ "$RUNNING" -gt 0 ]; then
    echo -e "${YELLOW}⚠⚠⚠ Topologia A está PARCIALMENTE funcionando${NC}"
    echo ""
    echo "Verifique os serviços que não subiram com:"
    echo "  docker-compose logs [nome-do-serviço]"
    exit 1
else
    echo -e "${RED}✗✗✗ Topologia A NÃO está funcionando${NC}"
    echo ""
    echo "Inicie os serviços com:"
    echo "  docker-compose up -d"
    exit 1
fi
