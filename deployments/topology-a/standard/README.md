# Topologia A Standard - Kubernetes

Implementação da stack AppGear em Kubernetes usando K3s.

## 🎯 Estrutura de Diretórios

```
standard/
├── k8s/
│   ├── 00-namespaces/       # Namespaces e RBAC
│   ├── 01-storage/          # StorageClass, PV, PVC
│   ├── 02-databases/        # PostgreSQL, Redis
│   ├── 03-gateways/         # Traefik, Kong, Coraza
│   ├── 04-ai/               # LiteLLM
│   └── 05-apps/             # Flowise, n8n
│
└── scripts/
    ├── setup-k3s-a-standard.sh       # Instala K3s
    ├── deploy-stack-a-standard.sh    # Deploy completo
    └── cleanup-stack-a-standard.sh   # Remove recursos
```

## 🚀 Instalação

### 1. Instalar K3s
```bash
sudo ./scripts/setup-k3s-a-standard.sh
```

### 2. Deploy da Stack
```bash
./scripts/deploy-stack-a-standard.sh
```

### 3. Verificar Status
```bash
kubectl get pods -n appgear
```

## 📦 Componentes

| Componente | Tipo | Namespace | Porta |
|------------|------|-----------|-------|
| PostgreSQL | StatefulSet | appgear | 5432 |
| Redis | StatefulSet | appgear | 6379 |
| Traefik | DaemonSet | kube-system | 80, 443 |
| Kong | Deployment | appgear | 8000, 8001 |
| LiteLLM | Deployment | appgear | 4000 |
| Flowise | Deployment | appgear | 3000 |
| n8n | Deployment | appgear | 5678 |

## 🔍 Diferenças vs Minimal

| Aspecto | Minimal (Compose) | Standard (K8s) |
|---------|-------------------|----------------|
| Orquestração | Docker Compose | Kubernetes |
| Escalabilidade | Manual | Automática (HPA) |
| Alta Disponibilidade | Não | Sim (multi-réplica) |
| Observabilidade | Logs básicos | Prometheus + Grafana |
| Segurança | Básica | WAF + Network Policies |
| Backup | Script manual | Velero (futuro) |

---

**Versão:** 1.0  
**Status:** Em Desenvolvimento  
**Data:** 28 de novembro de 2025
