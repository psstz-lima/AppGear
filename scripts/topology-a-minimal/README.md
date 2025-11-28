# Scripts AppGear - Topologia A Minimal

Scripts específicos para gerenciamento da **Topologia A Minimal** (Docker Compose).

## 📜 Scripts Disponíveis

### 🚀 startup-stack-a-minimal.sh
Inicia toda a stack na ordem correta.
```bash
sudo ./scripts/topology-a-minimal/startup-stack-a-minimal.sh
```

### 🛑 shutdown-stack-a-minimal.sh
Para toda a stack de forma segura.
```bash
sudo ./scripts/topology-a-minimal/shutdown-stack-a-minimal.sh
```

### 📊 status-stack-a-minimal.sh
Mostra status detalhado de todos os serviços.
```bash
sudo ./scripts/topology-a-minimal/status-stack-a-minimal.sh
```

### 🧪 test-e2e-a-minimal.sh
Executa teste de fumaça (Smoke Test) validando inferência de IA e APIs.
```bash
./scripts/topology-a-minimal/test-e2e-a-minimal.sh
```

### 💾 backup-manager-a-minimal.sh
Realiza backup dos dados persistentes (PostgreSQL, Flowise, n8n).
```bash
sudo ./scripts/topology-a-minimal/backup-manager-a-minimal.sh
```
*Salva em: `../../backups/YYYYMMDD_HHMMSS/`*

### 📜 logs-viewer-a-minimal.sh
Visualizador de logs unificado com filtros.
```bash
sudo ./scripts/topology-a-minimal/logs-viewer-a-minimal.sh [ai|infra|gateway|app|all] [-f]
```

---

## 🎯 Uso via Wrapper (Recomendado)

Use o atalho em `scripts/shortcuts/`:

```bash
# Operação Básica
./scripts/shortcuts/stack-a-minimal.sh start
./scripts/shortcuts/stack-a-minimal.sh stop
./scripts/shortcuts/stack-a-minimal.sh status

# Operação Avançada
./scripts/shortcuts/stack-a-minimal.sh test       # Rodar testes
./scripts/shortcuts/stack-a-minimal.sh backup     # Fazer backup
./scripts/shortcuts/stack-a-minimal.sh logs ai -f # Ver logs de IA em tempo real
```

---

**Topologia:** A Minimal (Docker Compose)  
**Versão:** 1.2  
**Atualizado:** 28 de novembro de 2025
