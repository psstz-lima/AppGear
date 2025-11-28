#!/bin/bash
################################################################################
# AppGear Stack Startup Script
# Inicia todos os serviços na ordem correta
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/topology-a/minimal"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AppGear Stack - Startup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Funções de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para esperar container ficar healthy
wait_healthy() {
    local container=$1
    local max_wait=${2:-60}
    local count=0
    
    log_info "Aguardando $container ficar healthy..."
    
    while [ $count -lt $max_wait ]; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
            
            if [ "$health" = "healthy" ]; then
                log_success "$container está healthy"
                return 0
            elif [ "$health" = "none" ]; then
                # Container sem healthcheck
                if docker ps --format '{{.Status}}' -f "name=^${container}$" | grep -q "Up"; then
                    log_success "$container está rodando"
                    return 0
                fi
            fi
        fi
        
        sleep 2
        count=$((count + 2))
        
        if [ $((count % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    log_warning "$container não ficou healthy em ${max_wait}s"
    return 1
}

# Verificar se já está rodando
if docker ps --format '{{.Names}}' | grep -q "appgear-"; then
    log_warning "Alguns containers AppGear já estão rodando:"
    docker ps --format 'table {{.Names}}\t{{.Status}}' | grep appgear-
    echo ""
    read -p "Deseja parar tudo e reiniciar? [s/N] " -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log_info "Executando shutdown primeiro..."
        "$SCRIPT_DIR/shutdown-stack.sh"
        sleep 3
    else
        log_info "Continuando com containers existentes..."
    fi
fi

cd "$DEPLOYMENT_DIR"

# Carregar variáveis de ambiente
if [ -f ".env" ]; then
    log_info "Carregando variáveis de ambiente do .env..."
    set -a
    source .env
    set +a
    log_success "Variáveis carregadas"
else
    log_error "Arquivo .env não encontrado em $DEPLOYMENT_DIR"
    exit 1
fi

echo ""
log_info "Iniciando stack AppGear..."
echo ""

# FASE 1: Infraestrutura (PostgreSQL, Redis)
log_info "═══ FASE 1/4: Infraestrutura ═══"
echo ""

log_info "Iniciando PostgreSQL..."
sudo docker-compose up -d postgres
wait_healthy appgear-postgres 60

log_info "Iniciando Redis..."
sudo docker-compose up -d redis
wait_healthy appgear-redis 30

echo ""

# FASE 2: Gateways e Proxy (Traefik, Kong)
log_info "═══ FASE 2/4: Gateways e Proxy ═══"
echo ""

log_info "Iniciando Traefik..."
sudo docker-compose up -d traefik
sleep 3
log_success "Traefik iniciado"

log_info "Iniciando Kong..."
sudo docker-compose up -d kong
wait_healthy appgear-kong 60

echo ""

# FASE 3: AI Gateway (LiteLLM)
log_info "═══ FASE 3/4: AI Gateway ═══"
echo ""

# Verificar se LiteLLM existe como container parado
if docker ps -a --format '{{.Names}}' | grep -q "^appgear-litellm$"; then
    log_info "Iniciando LiteLLM existente..."
    docker start appgear-litellm
    sleep 5
    log_success "LiteLLM iniciado"
else
    log_info "Criando container LiteLLM..."
    
    sudo -E docker run -d \
      --name appgear-litellm \
      --hostname litellm \
      --network appgear-net-core \
      --network-alias litellm \
      --restart unless-stopped \
      -p 4000:4000 \
      -e LITELLM_MASTER_KEY="${LITELLM_MASTER_KEY}" \
      -e DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}" \
      -e REDIS_HOST=redis \
      -e REDIS_PORT=6379 \
      -e REDIS_PASSWORD="${REDIS_PASSWORD}" \
      -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
      -e GROQ_API_KEY="${GROQ_API_KEY}" \
      -v "$(pwd)/config/litellm-config.yaml:/app/config.yaml:ro" \
      ghcr.io/berriai/litellm:main-latest \
      --config /app/config.yaml
    
    sleep 10
    log_success "LiteLLM criado e iniciado"
fi

echo ""

# FASE 4: Aplicações (Flowise, n8n)
log_info "═══ FASE 4/4: Aplicações ═══"
echo ""

# Flowise
if docker ps -a --format '{{.Names}}' | grep -q "^appgear-flowise$"; then
    log_info "Iniciando Flowise existente..."
    docker start appgear-flowise
    sleep 5
    log_success "Flowise iniciado"
else
    log_info "Criando container Flowise (workaround docker-compose bug)..."
    sudo docker-compose up --no-deps -d flowise || {
        log_warning "Docker compose falhou, tentando criar manualmente..."
        
        sudo docker run -d \
          --name appgear-flowise \
          --network appgear-net-core \
          --restart unless-stopped \
          -p 3000:3000 \
          -e DATABASE_TYPE=postgres \
          -e DATABASE_HOST=postgres \
          -e DATABASE_PORT=5432 \
          -e DATABASE_USER="${POSTGRES_USER}" \
          -e DATABASE_PASSWORD="${POSTGRES_PASSWORD}" \
          -e DATABASE_NAME="${POSTGRES_DB}" \
          -e DATABASE_SCHEMA=flowise \
          -e FLOWISE_USERNAME="${FLOWISE_USERNAME}" \
          -e FLOWISE_PASSWORD="${FLOWISE_PASSWORD}" \
          -e APIKEY_PATH=/root/.flowise \
          -e SECRETKEY_PATH=/root/.flowise \
          -e LOG_LEVEL=info \
          -v flowise_data:/root/.flowise \
          flowiseai/flowise:1.4.7 \
          flowise start
    }
    sleep 10
    log_success "Flowise criado"
fi

# n8n
log_info "Iniciando n8n..."
sudo docker-compose up --no-deps -d n8n
sleep 5
log_success "n8n iniciado"

echo ""

# Verificação final
log_info "═══ Verificação Final ═══"
echo ""

log_info "Containers rodando:"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E "NAMES|appgear-"

echo ""
log_info "Testando conectividade..."

# Teste PostgreSQL
if docker exec appgear-postgres pg_isready -U appgear > /dev/null 2>&1; then
    log_success "PostgreSQL acessível"
else
    log_warning "PostgreSQL não está respondendo"
fi

# Teste Redis
if docker exec appgear-redis redis-cli ping > /dev/null 2>&1; then
    log_success "Redis acessível"
else
    log_warning "Redis não está respondendo"
fi

# Teste LiteLLM
if curl -s -f http://localhost:4000/health > /dev/null 2>&1 || curl -s http://localhost:4000/health | grep -q "error"; then
    log_success "LiteLLM acessível (porta 4000)"
else
    log_warning "LiteLLM pode não estar pronto ainda"
fi

# Teste Flowise
if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
    log_success "Flowise acessível (porta 3000)"
else
    log_warning "Flowise pode não estar pronto ainda"
fi

# Teste n8n
if curl -s -f http://localhost:5678 > /dev/null 2>&1; then
    log_success "n8n acessível (porta 5678)"
else
    log_warning "n8n pode não estar pronto ainda"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Startup Concluído!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
log_info "Serviços disponíveis:"
echo "  • Flowise:  http://localhost:3000"
echo "  • n8n:      http://localhost:5678"
echo "  • LiteLLM:  http://localhost:4000"
echo "  • Traefik:  http://localhost:8080"
echo "  • Kong:     http://localhost:8001"
echo ""
log_info "Para ver logs: docker logs -f <container-name>"
log_info "Para parar:    ./scripts/shutdown-stack.sh"
echo ""
