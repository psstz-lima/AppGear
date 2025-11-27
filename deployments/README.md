# Deployments - AppGear

Este diretório contém todas as configurações de implantação da plataforma AppGear.

---

## 📁 Estrutura

```
deployments/
├── topology-a/           # Docker Compose
│   ├── README-topology-a.md
│   ├── minimal/          # ✅ 7 componentes (pronto)
│   │   ├── docker-compose.yml
│   │   ├── .env.example
│   │   └── config/
│   ├── standard/         # 15 componentes (futuro)
│   └── full/             # 25+ componentes (futuro)
│
└── topology-b/           # Kubernetes
    ├── README-topology-b.md (futuro)
    ├── minimal/          # (futuro)
    ├── standard/         # (futuro)
    └── enterprise/       # (futuro)
```

---

## 🚀 Topologia A - Docker Compose

**Status:** ✅ Minimal pronto  
**Uso:** Desenvolvimento, testes, PoCs, demos

### Perfis Disponíveis

#### Minimal ✅
- **Componentes:** 7
- **Setup:** ~15 minutos
- **Recursos:** 4GB RAM, 2 CPU
- **Uso:** PoC, dev local
- **Status:** Pronto
- **Onde:** `topology-a/minimal/`

#### Standard ⏳
- **Componentes:** 15
- **Setup:** ~1 hora
- **Recursos:** 8GB RAM, 4 CPU
- **Uso:** Desenvolvimento, testes integração
- **Status:** Planejado
- **Onde:** `topology-a/standard/` (futuro)

#### Full ⏳
- **Componentes:** 25+
- **Setup:** 2-3 horas
- **Recursos:** 16GB RAM, 8 CPU
- **Uso:** Testes completos, pré-produção
- **Status:** Planejado
- **Onde:** `topology-a/full/` (futuro)

### Quick Start

```bash
# Navegar para Topology A Minimal
cd topology-a/minimal

# Configurar
cp .env.example .env
nano .env  # Adicionar API keys

# Iniciar
docker-compose up -d

# Validar
cd ../../..  # Volta para raiz
./scripts/validate-topology-a.sh
```

**Documentação:** [topology-a/README-topology-a.md](topology-a/README-topology-a.md)

---

## ☸️ Topologia B - Kubernetes

**Status:** ⏳ Planejado  
**Uso:** Produção enterprise, multi-tenant

### Perfis Planejados

#### Minimal
- **Setup:** K3s/Minikube
- **Componentes:** 7 core
- **Features:** GitOps básico, Istio, KEDA
- **Status:** Planejado (Semana 6-9)

#### Standard
- **Setup:** Kubernetes cluster
- **Componentes:** 15
- **Features:** Full GitOps, vClusters, Observabilidade
- **Status:** Planejado

#### Enterprise
- **Setup:** Multi-node cluster
- **Componentes:** Full stack (25+)
- **Features:** HA, DR, Multi-cloud
- **Status:** Planejado

---

## ✅ Checklist de Implantação

### Antes de Implantar

- [ ] Escolher topologia (A ou B)
- [ ] Escolher perfil (minimal/standard/full)
- [ ] Verificar recursos disponíveis
- [ ] Ler documentação específica
- [ ] Preparar API keys necessárias

### Topologia A

- [ ] Docker e Docker Compose instalados
- [ ] Configurar `.env` a partir de `.env.example`
- [ ] Executar `docker-compose up -d`
- [ ] Validar com script `validate-topology-a.sh`
- [ ] Testar acessos (Flowise, n8n, Traefik)

### Topologia B (Quando Disponível)

- [ ] Kubernetes cluster configurado
- [ ] kubectl configurado
- [ ] Executar manifests
- [ ] Validar com script `validate-topology-b.sh`
- [ ] Verificar Argo CD, Istio, KEDA

---

## 🔄 Migração entre Topologias

### A → B (Futuro)

Quando migrar de Docker Compose para Kubernetes:

1. Exportar dados do PostgreSQL
2. Backup de volumes
3. Recriar em Kubernetes
4. Validar paridade

**Guia detalhado:** (será criado)

---

## 📊 Comparação de Topologias

| Feature | Topologia A | Topologia B |
|---------|-------------|-------------|
| **Orquestração** | Docker Compose | Kubernetes |
| **Setup** | Minutos | Horas |
| **Complexidade** | Baixa | Alta |
| **Escalabilidade** | Manual | Automática (KEDA) |
| **Multi-tenancy** | Lógico | Hard (vClusters) |
| **GitOps** | Manual | Argo CD |
| **Service Mesh** | Não | Istio mTLS |
| **DR** | Backup manual | Velero |
| **Uso** | Dev/PoC | Produção |

---

## 🆘 Troubleshooting

### Topologia A

```bash
# Ver logs
cd topology-a/minimal
docker-compose logs -f

# Reiniciar serviço
docker-compose restart [service]

# Rebuild
docker-compose up -d --build
```

### Topologia B

```bash
# Ver pods
kubectl get pods --all-namespaces

# Logs
kubectl logs -n [namespace] [pod]

# Reiniciar
kubectl rollout restart deployment [name] -n [namespace]
```

---

**Última Atualização:** 27 de novembro de 2025  
**Próxima Revisão:** Após validação Topologia A Minimal
