# Scripts de Gerenciamento AppGear

Scripts organizados por função e topologia para facilitar a operação e manutenção.

## 📁 Estrutura de Diretórios

```
scripts/
├── stack.sh ⭐                  # Script Principal (Wrapper)
├── QUICKSTART.md                # Guia Rápido
├── README.md                    # Documentação Geral
│
├── topology-a-minimal/          # Operação: Topologia A Minimal
│   ├── startup-stack.sh
│   ├── shutdown-stack.sh
│   └── status-stack.sh
│
├── checks/                      # Validação e QA
│   ├── validate-topology-a.sh   # Validação de Deployment
│   ├── validate-topology-b.sh
│   ├── check_docs.py            # Verificação de Documentação
│   ├── run_all_checks.py        # Suite de Testes
│   └── ... (outros scripts python)
│
└── requirements/                # Dependências
    └── requirements-tests.txt   # Libs para scripts Python
```

---

## 🚀 Uso Principal

Use o script `stack.sh` na raiz para a maioria das operações:

```bash
# Iniciar
./scripts/stack.sh a-minimal start

# Parar
./scripts/stack.sh a-minimal stop

# Status
./scripts/stack.sh a-minimal status
```

---

## 🔍 Scripts de Validação (Checks)

Localizados em `scripts/checks/`, estes scripts garantem a integridade do ambiente e da documentação.

### Validar Deployment
```bash
./scripts/checks/validate-topology-a.sh
```

### Validar Documentação e Estrutura
```bash
python3 scripts/checks/run_all_checks.py
```

---

## � Topologias

### topology-a-minimal/
Scripts operacionais para a versão Minimal da Topologia A (Docker Compose).
- **Foco:** Desenvolvimento local, testes rápidos.
- **Serviços:** LiteLLM, Flowise, n8n, Kong, Traefik, Postgres, Redis.

---

## 🛠️ Manutenção

### Adicionar Nova Topologia
1. Crie o diretório `scripts/topology-nome/`
2. Adicione `startup-stack.sh`, `shutdown-stack.sh`, `status-stack.sh`
3. Atualize `stack.sh` para reconhecer a nova topologia

### Dependências Python
Se for rodar os scripts de check Python:
```bash
pip install -r scripts/requirements/requirements-tests.txt
```

---

**Versão:** 1.1  
**Atualizado:** 28 de novembro de 2025
