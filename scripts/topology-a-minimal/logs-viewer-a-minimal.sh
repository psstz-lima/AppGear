#!/bin/bash
################################################################################
# AppGear - Logs Viewer
# Visualizador de logs unificado com filtros por grupo de serviço
################################################################################

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
    echo "Uso: $0 [grupo] [opções]"
    echo ""
    echo "Grupos:"
    echo "  all      Todos os serviços (padrão)"
    echo "  ai       LiteLLM + Flowise"
    echo "  infra    PostgreSQL + Redis"
    echo "  gateway  Traefik + Kong"
    echo "  app      Flowise + n8n"
    echo ""
    echo "Opções:"
    echo "  -f       Follow (acompanhar em tempo real)"
    echo "  --tail N Mostrar apenas últimas N linhas (padrão 50)"
    echo ""
}

GROUP=${1:-all}
shift

# Processar argumentos extras
ARGS=""
TAIL="50"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--follow) ARGS="$ARGS -f"; shift ;;
        --tail) TAIL="$2"; shift; shift ;;
        *) echo "Opção desconhecida: $1"; show_usage; exit 1 ;;
    esac
done

# Definir containers baseados no grupo
case $GROUP in
    "ai")
        CONTAINERS="appgear-litellm appgear-flowise"
        ;;
    "infra")
        CONTAINERS="appgear-postgres appgear-redis"
        ;;
    "gateway")
        CONTAINERS="appgear-traefik appgear-kong"
        ;;
    "app")
        CONTAINERS="appgear-flowise appgear-n8n"
        ;;
    "all")
        CONTAINERS="appgear-traefik appgear-kong appgear-postgres appgear-redis appgear-litellm appgear-flowise appgear-n8n"
        ;;
    *)
        echo "Grupo desconhecido: $GROUP"
        show_usage
        exit 1
        ;;
esac

echo -e "${BLUE}Visualizando logs de: $CONTAINERS${NC}"
echo -e "${YELLOW}Ctrl+C para sair${NC}"
echo ""

# Executar docker logs
# Nota: docker compose logs seria mais fácil se todos estivessem no compose,
# mas como temos containers manuais, usamos docker logs.
# Infelizmente docker logs não aceita múltiplos containers de uma vez nativamente de forma limpa como compose.
# Vamos usar um loop ou ferramenta externa se disponível, mas para bash puro:

if [[ "$ARGS" == *"-f"* ]]; then
    # Modo follow: infelizmente complexo para múltiplos containers sem docker-compose logs
    # Vamos tentar usar docker-compose logs para os que estão no compose e tail -f para os outros?
    # Melhor abordagem simples: usar 'docker logs' apenas para UM container ou avisar limitação.
    
    # Workaround: Usar trap para matar subprocessos
    trap 'kill $(jobs -p)' SIGINT
    
    for container in $CONTAINERS; do
        echo -e "${GREEN}--- $container ---${NC}"
        docker logs --tail "$TAIL" -f "$container" &
    done
    
    wait
else
    # Modo estático
    for container in $CONTAINERS; do
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  $container${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        docker logs --tail "$TAIL" "$container"
        echo ""
    done
fi
