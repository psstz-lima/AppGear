#!/bin/bash
################################################################################
# AppGear - Stack Manager (Topologia A Minimal)
# Atalho dedicado para gerenciamento da Topologia A Minimal
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOPOLOGY_DIR="$PROJECT_ROOT/scripts/topology-a-minimal"

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  AppGear - Stack Manager (A-Minimal)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

show_usage() {
    show_header
    echo "Uso: $0 <ação> [args...]"
    echo ""
    echo "Ações Principais:"
    echo "  start        Inicia a stack"
    echo "  stop         Para a stack"
    echo "  restart      Reinicia a stack"
    echo "  status       Mostra status detalhado"
    echo ""
    echo "Ações Operacionais:"
    echo "  test         Roda testes E2E (Smoke Test)"
    echo "  backup       Executa backup dos dados"
    echo "  logs [grupo] Ver logs (grupos: ai, infra, gateway, app, all)"
    echo ""
    echo "Exemplos:"
    echo "  $0 start"
    echo "  $0 test"
    echo "  $0 logs ai -f"
    echo ""
}

# Verificar argumentos
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

ACTION=$1
shift 1 # Remove ação dos argumentos para passar o resto

# Verificar se topologia existe
if [ ! -d "$TOPOLOGY_DIR" ]; then
    echo -e "${RED}Erro: Diretório da topologia não encontrado: $TOPOLOGY_DIR${NC}"
    exit 1
fi

# Executar ação
case $ACTION in
    "start"|"up")
        echo -e "${GREEN}Iniciando Topologia A Minimal...${NC}"
        exec sudo "$TOPOLOGY_DIR/startup-stack-a-minimal.sh"
        ;;
    "stop"|"down")
        echo -e "${YELLOW}Parando Topologia A Minimal...${NC}"
        exec sudo "$TOPOLOGY_DIR/shutdown-stack-a-minimal.sh"
        ;;
    "status"|"ps")
        exec sudo "$TOPOLOGY_DIR/status-stack-a-minimal.sh"
        ;;
    "restart")
        echo -e "${YELLOW}Reiniciando Topologia A Minimal...${NC}"
        sudo "$TOPOLOGY_DIR/shutdown-stack-a-minimal.sh"
        sleep 3
        exec sudo "$TOPOLOGY_DIR/startup-stack-a-minimal.sh"
        ;;
    "test"|"e2e")
        exec "$TOPOLOGY_DIR/test-e2e-a-minimal.sh"
        ;;
    "backup")
        exec sudo "$TOPOLOGY_DIR/backup-manager-a-minimal.sh"
        ;;
    "logs")
        # Passa argumentos restantes (grupo, -f, etc)
        exec sudo "$TOPOLOGY_DIR/logs-viewer-a-minimal.sh" "$@"
        ;;
    *)
        echo -e "${RED}Erro: Ação '$ACTION' não reconhecida${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
