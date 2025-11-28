# Scripts de Gerenciamento AppGear

Scripts organizados por função e topologia para facilitar a operação e manutenção.

## 📁 Estrutura de Diretórios

```
scripts/
├── shortcuts/                   # Atalhos de Gerenciamento (Use estes!)
│   └── stack-a-minimal.sh       # Gerenciador Topologia A Minimal
│
├── topology-a-minimal/          # Scripts Operacionais (Backend)
│   ├── startup-stack.sh
│   ├── shutdown-stack.sh
│   ├── status-stack.sh
│   ├── test-e2e.sh
│   ├── backup-manager.sh
│   └── logs-viewer.sh
│
├── checks/                      # Validação e QA
│   ├── topology_a_checks.sh
│   ├── docs_consistency_checks.py
│   └── ...
│
├── requirements/                # Dependências Python
└── QUICKSTART.md                # Guia Rápido
```

---

## 🚀 Uso Principal (Atalhos)

Use os scripts em `scripts/shortcuts/` para gerenciar sua stack. Eles são pré-configurados para cada topologia.

### Topologia A Minimal
```bash
# Iniciar
./scripts/shortcuts/stack-a-minimal.sh start

# Parar
./scripts/shortcuts/stack-a-minimal.sh stop

# Status
./scripts/shortcuts/stack-a-minimal.sh status

# Logs
./scripts/shortcuts/stack-a-minimal.sh logs ai -f

# Teste E2E
./scripts/shortcuts/stack-a-minimal.sh test
```

---

## 🔍 Scripts de Validação (Checks)

Localizados em `scripts/checks/`, estes scripts garantem a integridade do ambiente e da documentação.

### Validar Deployment
```bash
./scripts/checks/topology_a_checks.sh
```

### Validar Documentação e Estrutura
```bash
python3 scripts/checks/run_all_checks.py
```

---

**Versão:** 1.2  
**Atualizado:** 28 de novembro de 2025
