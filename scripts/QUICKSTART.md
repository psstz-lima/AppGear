# Guia Rápido - AppGear Scripts

Este guia mostra como usar os scripts de gerenciamento da plataforma AppGear.

## 🚀 Topologia A Minimal (Docker Compose)

Use o atalho dedicado em `scripts/shortcuts/`:

### 1. Iniciar Stack
```bash
./scripts/shortcuts/stack-a-minimal.sh start
```
*Inicia: PostgreSQL, Redis, Traefik, Kong, LiteLLM, Flowise, n8n*

### 2. Verificar Status
```bash
./scripts/shortcuts/stack-a-minimal.sh status
```

### 3. Ver Logs
```bash
# Ver logs de IA (LiteLLM + Flowise)
./scripts/shortcuts/stack-a-minimal.sh logs ai -f

# Ver logs de Infra (Postgres + Redis)
./scripts/shortcuts/stack-a-minimal.sh logs infra
```

### 4. Validar Funcionamento (Teste E2E)
```bash
./scripts/shortcuts/stack-a-minimal.sh test
```
*Valida inferência de IA e conectividade das APIs.*

### 5. Fazer Backup
```bash
./scripts/shortcuts/stack-a-minimal.sh backup
```
*Salva em `backups/YYYYMMDD_HHMMSS/`*

### 6. Parar Stack
```bash
./scripts/shortcuts/stack-a-minimal.sh stop
```

---

## 🔍 Validação de Ambiente

Para rodar os checks de integridade e documentação:

```bash
python3 scripts/checks/run_all_checks.py
```
