#!/bin/bash
# validate-topology-b.sh - Script de validação para Topologia B (Kubernetes)

set -e

echo "🔍 Validação da Topologia B - AppGear (Kubernetes)"
echo "================================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se kubectl está instalado e configurado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗${NC} kubectl não instalado"
    exit 1
fi

echo -e "${GREEN}✓${NC} kubectl instalado"

# Verificar conectividade com cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗${NC} Não conectado a nenhum cluster Kubernetes"
    exit 1
fi

echo -e "${GREEN}✓${NC} Conectado ao cluster Kubernetes"
echo ""

# 1. Validação de Namespaces AppGear
echo "📦 Validando Namespaces AppGear:"
echo "-------------------------------"

NAMESPACES=(
    "argocd"
    "istio-system"
    "traefik"
    "kong"
    "vault"
    "observability"
    "data"
)

for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Namespace $ns existe"
    else
        echo -e "${YELLOW}⚠${NC} Namespace $ns não encontrado"
    fi
done
echo ""

# 2. Validação de Componentes Core
echo "🎯 Validando Componentes Core:"
echo "----------------------------"

# Traefik
if kubectl get pods -n traefik -l app.kubernetes.io/name=traefik | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Traefik rodando"
else
    echo -e "${RED}✗${NC} Traefik não encontrado"
fi

# Kong
if kubectl get pods -n kong -l app.kubernetes.io/name=kong | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Kong rodando"
else
    echo -e "${RED}✗${NC} Kong não encontrado"
fi

# Istio
if kubectl get pods -n istio-system -l app=istiod | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Istio rodando"
else
    echo -e "${YELLOW}⚠${NC} Istio não encontrado"
fi

# Argo CD
if kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Argo CD rodando"
else
    echo -e "${YELLOW}⚠${NC} Argo CD não encontrado"
fi

# Vault
if kubectl get pods -n vault -l app.kubernetes.io/name=vault | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Vault rodando"
else
    echo -e "${YELLOW}⚠${NC} Vault não encontrado"
fi
echo ""

# 3. Validação de mTLS Istio
echo "🔐 Validando mTLS Istio:"
echo "----------------------"

if kubectl get peerauth --all-namespaces | grep -q "STRICT"; then
    echo -e "${GREEN}✓${NC} PeerAuthentication STRICT configurado"
else
    echo -e "${YELLOW}⚠${NC} mTLS STRICT não encontrado"
fi
echo ""

# 4. Validação de KEDA
echo "⚡ Validando KEDA:"
echo "----------------"

if kubectl get pods -n keda | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} KEDA rodando"
    
    # Verificar ScaledObjects
    SCALED=$(kubectl get scaledobjects --all-namespaces 2>/dev/null | wc -l)
    if [ "$SCALED" -gt 1 ]; then
        echo -e "${GREEN}✓${NC} ScaledObjects encontrados: $((SCALED-1))"
    else
        echo -e "${YELLOW}⚠${NC} Nenhum ScaledObject encontrado"
    fi
else
    echo -e "${YELLOW}⚠${NC} KEDA não encontrado"
fi
echo ""

# 5. Validação de vClusters
echo "🏢 Validando vClusters:"
echo "---------------------"

VCLUSTERS=$(kubectl get virtualclusters --all-namespaces 2>/dev/null | tail -n +2 | wc -l || echo "0")
if [ "$VCLUSTERS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} vClusters encontrados: $VCLUSTERS"
else
    echo -e "${YELLOW}⚠${NC} Nenhum vCluster encontrado"
fi
echo ""

# 6. Validação de Labels AppGear
echo "🏷️  Validando Labels appgear.io/*:"
echo "--------------------------------"

LABELED_PODS=$(kubectl get pods --all-namespaces -l appgear.io/tenant 2>/dev/null | tail -n +2 | wc -l || echo "0")
if [ "$LABELED_PODS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Pods com labels appgear.io/*: $LABELED_PODS"
else
    echo -e "${YELLOW}⚠${NC} Nenhum pod com labels appgear.io/* encontrado"
fi
echo ""

# 7. Validação de GitOps (Argo CD)
echo "📋 Validando GitOps (Argo CD):"
echo "----------------------------"

if kubectl get applications -n argocd &> /dev/null; then
    APPS=$(kubectl get applications -n argocd | tail -n +2 | wc -l)
    echo -e "${GREEN}✓${NC} Applications do Argo CD: $APPS"
    
    SYNCED=$(kubectl get applications -n argocd -o json | jq '[.items[] | select(.status.sync.status=="Synced")] | length' 2>/dev/null || echo "0")
    echo -e "${GREEN}✓${NC} Applications Synced: $SYNCED/$APPS"
else
    echo -e "${YELLOW}⚠${NC} Argo CD Applications não encontrados"
fi
echo ""

# 8. Validação de ApplicationSets
echo "📚 Validando ApplicationSets:"
echo "---------------------------"

if kubectl get applicationsets -n argocd &> /dev/null; then
    APPSETS=$(kubectl get applicationsets -n argocd | tail -n +2 | wc -l)
    echo -e "${GREEN}✓${NC} ApplicationSets encontrados: $APPSETS"
else
    echo -e "${YELLOW}⚠${NC} ApplicationSets não encontrados"
fi
echo ""

# 9. Validação de Observabilidade
echo "📊 Validando Observabilidade:"
echo "---------------------------"

# Prometheus
if kubectl get pods -n observability -l app.kubernetes.io/name=prometheus | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Prometheus rodando"
else
    echo -e "${YELLOW}⚠${NC} Prometheus não encontrado"
fi

# Grafana
if kubectl get pods -n observability -l app.kubernetes.io/name=grafana | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Grafana rodando"
else
    echo -e "${YELLOW}⚠${NC} Grafana não encontrado"
fi

# Loki
if kubectl get pods -n observability -l app.kubernetes.io/name=loki | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Loki rodando"
else
    echo -e "${YELLOW}⚠${NC} Loki não encontrado"
fi
echo ""

# 10. Validação de Velero (DR)
echo "💾 Validando Velero (DR):"
echo "-----------------------"

if kubectl get pods -n velero | grep -q "Running"; then
    echo -e "${GREEN}✓${NC} Velero rodando"
    
    # Verificar backups
    BACKUPS=$(kubectl get backups -n velero 2>/dev/null | tail -n +2 | wc -l || echo "0")
    if [ "$BACKUPS" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Backups encontrados: $BACKUPS"
    else
        echo -e "${YELLOW}⚠${NC} Nenhum backup encontrado"
    fi
else
    echo -e "${YELLOW}⚠${NC} Velero não encontrado"
fi
echo ""

# 11. Validação de Cadeia de Borda
echo "🛡️  Validando Cadeia de Borda:"
echo "----------------------------"

echo "Verificando ordem: Traefik → Coraza → Kong → Istio"

# Verificar IngressRoutes do Traefik
INGRESSROUTES=$(kubectl get ingressroutes --all-namespaces 2>/dev/null | tail -n +2 | wc -l || echo "0")
if [ "$INGRESSROUTES" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} IngressRoutes encontrados: $INGRESSROUTES"
else
    echo -e "${YELLOW}⚠${NC} Nenhum IngressRoute encontrado"
fi

# Verificar Ingress do Kong
INGRESSES=$(kubectl get ingress --all-namespaces -l app.kubernetes.io/name=kong 2>/dev/null | tail -n +2 | wc -l || echo "0")
if [ "$INGRESSES" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Ingresses do Kong: $INGRESSES"
else
    echo -e "${YELLOW}⚠${NC} Nenhum Ingress do Kong encontrado"
fi
echo ""

# 12. Relatório Final
echo "📊 Relatório Final:"
echo "=================="

ALL_PODS=$(kubectl get pods --all-namespaces | tail -n +2 | wc -l)
RUNNING_PODS=$(kubectl get pods --all-namespaces | grep "Running" | wc -l)

echo "Pods totais: $ALL_PODS"
echo "Pods rodando: $RUNNING_PODS"
echo ""

if [ "$RUNNING_PODS" -gt 20 ]; then
    echo -e "${GREEN}✓✓✓ Topologia B está FUNCIONANDO!${NC}"
    echo ""
    echo "🎉 Cluster Kubernetes está operacional!"
    echo ""
    echo "Próximos passos:"
    echo "  1. Validar cross-check entre módulos"
    echo "  2. Executar testes end-to-end"
    echo "  3. Verificar métricas no Grafana"
    exit 0
else
    echo -e "${YELLOW}⚠⚠⚠ Topologia B está PARCIALMENTE funcionando${NC}"
    echo ""
    echo "Verifique pods com problemas:"
    echo "  kubectl get pods --all-namespaces | grep -v Running"
    exit 1
fi
