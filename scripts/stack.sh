#!/bin/bash
################################################################################
# AppGear - Quick Stack Manager
# Wrapper para facilitar uso dos scripts por topologia
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  AppGear - Stack Manager${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

show_usage() {
    show_header
    echo "Uso: $0 <topologia> <ação>"
    echo ""
    echo "Topologias disponíveis:"
    echo "  a-minimal    Topologia A Minimal (Docker Compose)"
    echo "  a-standard   Topologia A Standard (Kubernetes) [FUTURO]"
    echo "  b            Topologia B (Multi-tenant) [FUTURO]"
    echo ""
    echo "Ações:"
    echo "  start        Inicia a stack"
    echo "  stop         Para a stack"
    echo "  status       Mostra status"
    echo "  restart      Para e inicia novamente"
    echo ""
    echo "Exemplos:"
    echo "  $0 a-minimal start    # Inicia Topologia A Minimal"
    echo "  $0 a-minimal status   # Ver status"
    echo "  $0 a-minimal stop     # Para stack"
    echo ""
}

# Verificar argumentos
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

TOPOLOGY=$1
ACTION=$2

# Mapear topologia para diretório
case $TOPOLOGY in
    "a-minimal"|"minimal")
        TOPOLOGY_DIR="topology-a-minimal"
        ;;
    "a-standard"|"standard")
        TOPOLOGY_DIR="topology-a-standard"
        ;;
    "b")
        TOPOLOGY_DIR="topology-b"
        ;;
    *)
        echo -e "${RED}Erro: Topologia '$TOPOLOGY' não reconhecida${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

# Verificar se topologia existe
if [ ! -d "$SCRIPT_DIR/$TOPOLOGY_DIR" ]; then
    echo -e "${RED}Erro: Topologia '$TOPOLOGY' ainda não implementada${NC}"
    echo -e "${YELLOW}Diretório não encontrado: $SCRIPT_DIR/$TOPOLOGY_DIR${NC}"
    exit 1
fi

# Executar ação
case $ACTION in
    "start"|"up")
        echo -e "${GREEN}Iniciando $TOPOLOGY_DIR...${NC}"
        exec sudo "$SCRIPT_DIR/$TOPOLOGY_DIR/startup-stack.sh"
        ;;
    "stop"|"down")
        echo -e "${YELLOW}Parando $TOPOLOGY_DIR...${NC}"
        exec sudo "$SCRIPT_DIR/$TOPOLOGY_DIR/shutdown-stack.sh"
        ;;
    "status"|"ps")
        exec sudo "$SCRIPT_DIR/$TOPOLOGY_DIR/status-stack.sh"
        ;;
    "restart")
        echo -e "${YELLOW}Reiniciando $TOPOLOGY_DIR...${NC}"
        sudo "$SCRIPT_DIR/$TOPOLOGY_DIR/shutdown-stack.sh"
        sleep 3
        exec sudo "$SCRIPT_DIR/$TOPOLOGY_DIR/startup-stack.sh"
        ;;
    *)
        echo -e "${RED}Erro: Ação '$ACTION' não reconhecida${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
