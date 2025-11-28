#!/bin/bash
################################################################################
# AppGear - K3s Setup Script (Topologia A Standard)
# Instala e configura K3s para rodar a stack AppGear
################################################################################

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AppGear - K3s Setup (Topologia A Standard)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Verificar se já está instalado
if command -v k3s &> /dev/null; then
    echo -e "${YELLOW}[AVISO]${NC} K3s já está instalado."
    k3s --version
    echo ""
    read -p "Deseja reinstalar? [s/N] " -r
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${GREEN}Mantendo instalação existente.${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Removendo instalação existente...${NC}"
    /usr/local/bin/k3s-uninstall.sh || true
fi

# Verificar requisitos
echo -e "${BLUE}[1/5]${NC} Verificando requisitos..."

# RAM mínima (4GB)
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 4 ]; then
    echo -e "${RED}[ERRO]${NC} Memória insuficiente. Mínimo: 4GB, Disponível: ${TOTAL_RAM}GB"
    exit 1
fi
echo -e "  ${GREEN}✅${NC} RAM: ${TOTAL_RAM}GB"

# Espaço em disco (20GB)
FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_SPACE" -lt 20 ]; then
    echo -e "${RED}[ERRO]${NC} Espaço em disco insuficiente. Mínimo: 20GB, Disponível: ${FREE_SPACE}GB"
    exit 1
fi
echo -e "  ${GREEN}✅${NC} Disco: ${FREE_SPACE}GB disponíveis"

# Instalar K3s
echo ""
echo -e "${BLUE}[2/5]${NC} Instalando K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Aguardar K3s iniciar
echo -e "${BLUE}[3/5]${NC} Aguardando K3s iniciar..."
sleep 10

# Verificar instalação
if ! systemctl is-active --quiet k3s; then
    echo -e "${RED}[ERRO]${NC} K3s não iniciou corretamente"
    sudo journalctl -u k3s -n 50
    exit 1
fi
echo -e "  ${GREEN}✅${NC} K3s rodando"

# Configurar kubeconfig
echo -e "${BLUE}[4/5]${NC} Configurando kubectl..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Adicionar ao .bashrc se não existir
if ! grep -q "KUBECONFIG" ~/.bashrc; then
    echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
fi

# Testar kubectl
if kubectl get nodes | grep -q "Ready"; then
    echo -e "  ${GREEN}✅${NC} kubectl configurado"
else
    echo -e "${RED}[ERRO]${NC} kubectl não está funcionando"
    exit 1
fi

# Instalar Helm
echo -e "${BLUE}[5/5]${NC} Instalando Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo -e "  ${GREEN}✅${NC} Helm instalado"
else
    echo -e "  ${GREEN}✅${NC} Helm já instalado ($(helm version --short))"
fi

# Adicionar repos Helm úteis
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add traefik https://traefik.github.io/charts
helm repo add kong https://charts.konghq.com
helm repo update

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  K3s Setup Completo!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Informações do Cluster:${NC}"
kubectl get nodes
echo ""
kubectl version --short
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo "  1. Deploy dos namespaces: kubectl apply -f k8s/00-namespaces/"
echo "  2. Deploy da stack: ./deploy-stack-a-standard.sh"
echo ""
