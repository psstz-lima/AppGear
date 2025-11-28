# AppGear - Requirements Directory

Dependências Python para desenvolvimento e testes da plataforma AppGear.

## 📋 Conteúdo

- `requirements-tests.txt` - Dependências Python para testes
- Testes de validação das topologias
- Testes de integração

## 🚀 Setup

### Instalar Dependências de Teste

```bash
# Criar ambiente virtual (recomendado)
python3 -m venv .venv
source .venv/bin/activate  # Linux/Mac
# ou
.venv\Scripts\activate  # Windows

# Instalar dependências
pip install -r scripts/requirements/requirements-tests.txt
```

## 🧪 Executar Testes

### Todos os Testes
```bash
pytest
```

### Testes Específicos
```bash
pytest tests/test_topology_a.py
pytest tests/test_integration.py
```

### Com Coverage
```bash
pytest --cov=. --cov-report=html
```

## 📁 Estrutura

```
scripts/requirements/
├── README.md                    # Este arquivo
├── requirements-tests.txt       # Dependências de teste
└── (futuros) requirements-*.txt # Outros requirements conforme necessário
```

Testes automatizados serão adicionados futuramente em `scripts/tests/`.

---

**Criado:** 27 de novembro de 2025  
**Localização:** `/home/paulo-lima/AppGear/scripts/requirements/`
