#!/bin/bash
################################################################################
# AppGear Stack Shutdown Script
# Desliga todos os serviços de forma segura e ordenada
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/topology-a/minimal"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         AppGear Stack - Shutdown Seguro                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} $1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to stop container gracefully
stop_container() {
    local container_name=$1
    local timeout=${2:-10}
    
    if docker ps -q -f name="^${container_name}$" | grep -q .; then
        print_step "Parando $container_name (timeout: ${timeout}s)..."
        if docker stop -t "$timeout" "$container_name" 2>/dev/null; then
            print_success "$container_name parado"
            return 0
        else
            print_error "Falha ao parar $container_name"
            return 1
        fi
    else
        echo "  ℹ️  $container_name não está rodando"
        return 0
    fi
}

# Function to wait for container to stop
wait_container_stopped() {
    local container_name=$1
    local max_wait=30
    local waited=0
    
    while docker ps -q -f name="^${container_name}$" | grep -q . && [ $waited -lt $max_wait ]; do
        sleep 1
        waited=$((waited + 1))
    done
    
    if [ $waited -ge $max_wait ]; then
        print_error "$container_name não parou no tempo esperado"
        return 1
    fi
    return 0
}

# Start shutdown process
echo ""
print_step "Iniciando processo de shutdown..."
echo ""

# Step 1: Stop application layer (Flowise, n8n)
echo -e "${BLUE}━━━ Camada de Aplicação ━━━${NC}"
stop_container "appgear-flowise" 15
stop_container "appgear-n8n" 15
echo ""

# Step 2: Stop AI Gateway (LiteLLM)
echo -e "${BLUE}━━━ Gateway de IA ━━━${NC}"
stop_container "appgear-litellm" 10
echo ""

# Step 3: Stop API Gateway (Kong)
echo -e "${BLUE}━━━ API Gateway ━━━${NC}"
stop_container "appgear-kong" 10
echo ""

# Step 4: Stop databases and cache (graceful shutdown to flush data)
echo -e "${BLUE}━━━ Bancos de Dados e Cache ━━━${NC}"
print_step "Parando Redis (flushing cache)..."
stop_container "appgear-redis" 15

print_step "Parando PostgreSQL (salvando dados)..."
stop_container "appgear-postgres" 30
echo ""

# Step 5: Stop reverse proxy (Traefik)
echo -e "${BLUE}━━━ Proxy Reverso ━━━${NC}"
stop_container "appgear-traefik" 5
echo ""

# Step 6: Stop docker-compose managed services (if any remaining)
echo -e "${BLUE}━━━ Docker Compose ━━━${NC}"
if [ -f "$DEPLOYMENT_DIR/docker-compose.yml" ]; then
    print_step "Parando serviços do docker-compose..."
    cd "$DEPLOYMENT_DIR"
    if docker-compose ps -q 2>/dev/null | grep -q .; then
        docker-compose down 2>/dev/null || true
        print_success "Docker Compose parado"
    else
        echo "  ℹ️  Nenhum serviço do docker-compose rodando"
    fi
fi
echo ""

# Step 7: Verify all containers are stopped
echo -e "${BLUE}━━━ Verificação Final ━━━${NC}"
print_step "Verificando containers restantes..."
RUNNING=$(docker ps --filter "name=appgear-" --format "{{.Names}}" | wc -l)

if [ "$RUNNING" -eq 0 ]; then
    print_success "Todos os containers AppGear foram parados"
else
    print_error "Ainda existem $RUNNING container(s) rodando:"
    docker ps --filter "name=appgear-" --format "  - {{.Names}} ({{.Status}})"
    echo ""
    read -p "Deseja forçar a parada destes containers? [s/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        docker ps --filter "name=appgear-" -q | xargs -r docker stop -t 5
        print_success "Containers forçados a parar"
    fi
fi
echo ""

# Step 8: Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Shutdown Completo                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Stack AppGear desligada com sucesso!${NC}"
echo ""
echo "Próximos passos:"
echo "  • Para iniciar novamente: ./scripts/startup-stack-a-minimal.sh"
echo "  • Para ver status:        ./scripts/status-stack-a-minimal.sh"
echo ""
