# Scripts AppGear - Topologia A Minimal

Scripts específicos para gerenciamento da **Topologia A Minimal** (Docker Compose).

## 📜 Scripts Disponíveis

### 🚀 startup-stack.sh
Inicia toda a stack na ordem correta.
```bash
sudo ./scripts/topology-a-minimal/startup-stack.sh
```

### 🛑 shutdown-stack.sh
Para toda a stack de forma segura.
```bash
sudo ./scripts/topology-a-minimal/shutdown-stack.sh
```

### 📊 status-stack.sh
Mostra status detalhado de todos os serviços.
```bash
sudo ./scripts/topology-a-minimal/status-stack.sh
```

### 🧪 test-e2e.sh
Executa teste de fumaça (Smoke Test) validando inferência de IA e APIs.
```bash
./scripts/topology-a-minimal/test-e2e.sh
```

### 💾 backup-manager.sh
Realiza backup dos dados persistentes (PostgreSQL, Flowise, n8n).
```bash
sudo ./scripts/topology-a-minimal/backup-manager.sh
```
*Salva em: `../../backups/YYYYMMDD_HHMMSS/`*

### 📜 logs-viewer.sh
Visualizador de logs unificado com filtros.
```bash
sudo ./scripts/topology-a-minimal/logs-viewer.sh [ai|infra|gateway|app|all] [-f]
```

---

## 🎯 Uso via Wrapper (Recomendado)

Use o script `stack.sh` na raiz `scripts/`:

```bash
# Operação Básica
./scripts/stack.sh a-minimal start
./scripts/stack.sh a-minimal stop
./scripts/stack.sh a-minimal status

# Operação Avançada
./scripts/stack.sh a-minimal test       # Rodar testes
./scripts/stack.sh a-minimal backup     # Fazer backup
./scripts/stack.sh a-minimal logs ai -f # Ver logs de IA em tempo real
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

---

**Topologia:** A Minimal (Docker Compose)  
**Versão:** 1.1  
**Atualizado:** 28 de novembro de 2025
