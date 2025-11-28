#!/bin/bash
################################################################################
# AppGear - Backup Manager
# Gerencia backups dos dados persistentes da stack
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_ROOT="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AppGear - Backup Manager${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Verificar se containers estão rodando
if ! docker ps | grep -q "appgear-postgres"; then
    echo -e "${RED}Erro: PostgreSQL não está rodando. Inicie a stack primeiro.${NC}"
    exit 1
fi

# Criar diretório de backup
mkdir -p "$CURRENT_BACKUP_DIR"
echo -e "${BLUE}[INFO]${NC} Iniciando backup em: $CURRENT_BACKUP_DIR"

# 1. Backup PostgreSQL
echo -e "${YELLOW}1. Backup PostgreSQL...${NC}"
if docker exec appgear-postgres pg_dumpall -U appgear > "$CURRENT_BACKUP_DIR/postgres_dump.sql"; then
    gzip "$CURRENT_BACKUP_DIR/postgres_dump.sql"
    echo -e "  ${GREEN}✅ Database dumpado e comprimido (postgres_dump.sql.gz)${NC}"
else
    echo -e "  ${RED}❌ Falha no dump do PostgreSQL${NC}"
fi

# 2. Backup Flowise Data
echo -e "${YELLOW}2. Backup Flowise...${NC}"
# Flowise armazena dados em /root/.flowise
if docker cp appgear-flowise:/root/.flowise "$CURRENT_BACKUP_DIR/flowise_data"; then
    # Comprimir pasta para economizar espaço
    tar -czf "$CURRENT_BACKUP_DIR/flowise_data.tar.gz" -C "$CURRENT_BACKUP_DIR" flowise_data
    rm -rf "$CURRENT_BACKUP_DIR/flowise_data"
    echo -e "  ${GREEN}✅ Dados do Flowise salvos (flowise_data.tar.gz)${NC}"
else
    echo -e "  ${RED}❌ Falha ao copiar dados do Flowise${NC}"
fi

# 3. Backup n8n Data (se existir volume mapeado ou dados internos)
echo -e "${YELLOW}3. Backup n8n...${NC}"
# n8n geralmente usa /home/node/.n8n
if docker cp appgear-n8n:/home/node/.n8n "$CURRENT_BACKUP_DIR/n8n_data" 2>/dev/null; then
    tar -czf "$CURRENT_BACKUP_DIR/n8n_data.tar.gz" -C "$CURRENT_BACKUP_DIR" n8n_data
    rm -rf "$CURRENT_BACKUP_DIR/n8n_data"
    echo -e "  ${GREEN}✅ Dados do n8n salvos (n8n_data.tar.gz)${NC}"
else
    echo -e "  ${YELLOW}⚠️  Dados do n8n não encontrados ou inacessíveis${NC}"
fi

# 4. Rotação de Backups (Manter últimos 7)
echo -e "${BLUE}[INFO]${NC} Verificando rotação de backups..."
BACKUP_COUNT=$(ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | wc -l)
MAX_BACKUPS=7

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
    echo -e "  Removendo $REMOVE_COUNT backup(s) antigo(s)..."
    ls -1d "$BACKUP_ROOT"/*/ | head -n "$REMOVE_COUNT" | xargs rm -rf
    echo -e "  ${GREEN}✅ Limpeza concluída${NC}"
fi

SIZE=$(du -sh "$CURRENT_BACKUP_DIR" | cut -f1)
echo ""
echo -e "${GREEN}✅ Backup concluído com sucesso!${NC}"
echo -e "📁 Local: $CURRENT_BACKUP_DIR"
echo -e "📦 Tamanho: $SIZE"
echo ""
