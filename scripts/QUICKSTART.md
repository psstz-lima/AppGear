# AppGear - Guia Rápido de Scripts

## 🚀 Uso Mais Simples (Recomendado)

### Topologia A Minimal

```bash
# Iniciar
./scripts/stack.sh a-minimal start

# Ver status
./scripts/stack.sh a-minimal status

# Parar
./scripts/stack.sh a-minimal stop

# Reiniciar
./scripts/stack.sh a-minimal restart
```

---

## 📁 Uso Direto (Alternativa)

```bash
# Iniciar
sudo ./scripts/topology-a-minimal/startup-stack.sh

# Status
sudo ./scripts/topology-a-minimal/status-stack.sh

# Parar
sudo ./scripts/topology-a-minimal/shutdown-stack.sh
```

---

## 🎯 Comandos Rápidos

| Ação | Comando Curto |
|------|---------------|
| **Iniciar** | `./scripts/stack.sh a-minimal start` |
| **Parar** | `./scripts/stack.sh a-minimal stop` |
| **Status** | `./scripts/stack.sh a-minimal status` |
| **Reiniciar** | `./scripts/stack.sh a-minimal restart` |

---

## 📊 Acessar Serviços

Após iniciar a stack:

| Serviço | URL |
|---------|-----|
| **Flowise** (AI Workflows) | http://localhost:3000 |
| **n8n** (Automação) | http://localhost:5678 |
| **LiteLLM** (AI Gateway) | http://localhost:4000 |
| **Traefik** (Dashboard) | http://localhost:8080 |
| **Kong** (Admin) | http://localhost:8001 |

### Credenciais

Ver arquivo: `.secrets/credentials.md`

---

## 🐛 Problemas Comuns

### Stack não inicia
```bash
# Ver logs de um serviço específico
docker logs appgear-flowise --tail 50

# Forçar limpeza e reiniciar
docker stop $(docker ps -q --filter "name=appgear-")
./scripts/stack.sh a-minimal start
```

### Porta já em uso
```bash
# Ver o que está usando a porta
sudo lsof -i :3000  # Exemplo com porta 3000

# Matar processo
sudo kill -9 <PID>
```

### Permissão negada
```bash
# Dar permissão de execução
chmod +x scripts/*.sh
chmod +x scripts/topology-a-minimal/*.sh
```

---

## 📚 Documentação Completa

- **README Geral:** [scripts/README.md](README.md)
- **Topologia A Minimal:** [scripts/topology-a-minimal/README.md](topology-a-minimal/README.md)
- **Guia Groq:** [Guia de Integração Groq](../.gemini/antigravity/brain/5c0bd395-2a7f-4b37-b2bf-3d13caa13ee2/groq_integration_guide.md)

---

**Atualizado:** 28 de novembro de 2025
