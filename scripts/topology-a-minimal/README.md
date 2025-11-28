# Scripts AppGear - Topologia A Minimal

Scripts específicos para gerenciamento da **Topologia A Minimal** (Docker Compose).

## 📜 Scripts Disponíveis

### 🚀 startup-stack.sh
Inicia toda a stack na ordem correta.

```bash
sudo ./scripts/topology-a-minimal/startup-stack.sh
```

**Fases de inicialização:**
1. PostgreSQL + Redis (infraestrutura)
2. Traefik + Kong (gateways)
3. LiteLLM (AI gateway)
4. Flowise + n8n (aplicações)

⏱️ **Tempo:** 1-2 minutos

---

### 🛑 shutdown-stack.sh
Para toda a stack de forma segura.

```bash
sudo ./scripts/topology-a-minimal/shutdown-stack.sh
```

**Opções:**
- Backup automático do PostgreSQL e Flowise (opcional)
- Shutdown ordenado (reverso da inicialização)
- Preserva dados e configurações

⏱️ **Tempo:** 30-60 segundos

---

### 📊 status-stack.sh
Mostra status detalhado de todos os serviços.

```bash
sudo ./scripts/topology-a-minimal/status-stack.sh
```

**Informações:**
- ✅ Containers rodando
- 🏥 Healthchecks
- 🔌 Portas acessíveis
- 💻 Uso de CPU/memória

---

## 🎯 Casos de Uso

### Início do Trabalho
```bash
cd ~/AppGear
sudo ./scripts/topology-a-minimal/startup-stack.sh
```

### Verificar Status
```bash
sudo ./scripts/topology-a-minimal/status-stack.sh
```

### Fim do Trabalho
```bash
sudo ./scripts/topology-a-minimal/shutdown-stack.sh
```

---

## 📦 Serviços Gerenciados

| Serviço | Porta | Função |
|---------|-------|--------|
| PostgreSQL | 5432 | Banco de dados |
| Redis | 6379 | Cache |
| Traefik | 80, 443, 8080 | Proxy reverso |
| Kong | 8000, 8001 | API Gateway |
| LiteLLM | 4000 | AI Gateway (Groq) |
| Flowise | 3000 | AI Workflows |
| n8n | 5678 | Automação |

**Total:** 7 containers

---

## ⚠️ Importante

### Permissões
Todos os scripts requerem **sudo** pois gerenciam containers Docker.

### Containers Manuais
Alguns containers são criados **fora do docker-compose** devido a bugs:
- `appgear-litellm` - Variável `GROQ_API_KEY` não passa
- `appgear-flowise` - Bug de migração na versão `latest`

Os scripts lidam com isso automaticamente! ✅

### Dados Preservados
O shutdown **NÃO remove**:
- ✅ Containers (ficam stopped)
- ✅ Volumes (dados PostgreSQL, Flowise)
- ✅ Redes Docker
- ✅ Configurações

---

## 🔧 Troubleshooting

### Erro de permissão
```bash
chmod +x scripts/topology-a-minimal/*.sh
```

### Ver logs de um serviço
```bash
docker logs appgear-flowise --tail 50 -f
```

### Forçar parada
```bash
docker stop appgear-<serviço> --time 5
```

---

**Topologia:** A Minimal (Docker Compose)  
**Versão:** 1.0  
**Data:** 28 de novembro de 2025
