# AppGear - Guia de Instalação: Topologia A Minimal

> 🎯 **Objetivo:** Guide de instalação específico para **Topologia A - Minimal** (FASE 1)  
> Para outras topologias, veja: [Índice de Guias](installation-guide.md)

**Versão do Guia:** 1.1  
**Última Atualização:** 27 de novembro de 2025  
**Topologia:** A - Minimal (7 serviços)  
**Complexidade:** Básica

---

## 📋 Índice

1. [Pré-Requisitos](#pré-requisitos)
2. [Preparação do Ambiente](#preparação-do-ambiente)
3. [Clonagem do Repositório](#clonagem-do-repositório)
4. [Configuração Inicial](#configuração-inicial)
5. [Instalação do Docker](#instalação-do-docker)
6. [Inicialização da Stack](#inicialização-da-stack)
7. [Verificação e Testes](#verificação-e-testes)
8. [Acesso às Interfaces](#acesso-às-interfaces)
9. [Troubleshooting](#troubleshooting)
10. [Próximos Passos](#próximos-passos)

---

## 🎯 Pré-Requisitos

### Hardware Mínimo
- **CPU:** 2 cores
- **RAM:** 4 GB disponível
- **Disco:** 10 GB livres
- **Rede:** Conexão com internet

### Software Necessário
- **SO:** Linux (Ubuntu 20.04+, Debian 11+), macOS, ou Windows 10/11 com WSL2
- **Git:** Versão 2.0+
- **Docker:** 20.10+ (recomendado: 28.2.2)
- **Docker Compose:** 1.29+ ou Docker Compose V2
- **Chave API:** OpenAI, Anthropic, Groq ou Ollama local

### Conhecimentos Básicos
- Terminal/linha de comando
- Conceitos básicos de Docker (desejável)
- Edição de arquivos de texto

---

## 🔧 Preparação do Ambiente

### 1. Verificar Sistema Operacional

```bash
# Ver versão do sistema
cat /etc/os-release

# Verificar recursos
free -h        # RAM disponível
df -h          # Espaço em disco
```

### 2. Atualizar Sistema

**Linux (Ubuntu/Debian):**
```bash
sudo apt update && sudo apt upgrade -y

# Verificar se git está instalado
git --version

# Se não estiver, instalar:
sudo apt install -y git
```

**Windows:**
```powershell
# Instalar WSL2 (se ainda não tiver)
wsl --install

# Instalar Ubuntu no WSL
wsl --install -d Ubuntu-22.04

# Reiniciar o computador
# Após reiniciar, abrir Ubuntu e atualizar:
sudo apt update && sudo apt upgrade -y
sudo apt install -y git
```

**macOS:**
```bash
# Instalar Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar git
brew install git
```

---

## 📥 Clonagem do Repositório

### 1. Escolher Diretório de Trabalho

```bash
# Criar diretório para projetos (recomendado)
mkdir -p ~/projects
cd ~/projects
```

### 2. Clonar Repositório

```bash
# Clonar AppGear
git clone https://github.com/seu-usuario/AppGear.git
cd AppGear

# Verificar estrutura
ls -la
```

**Você deve ver:**
- `deployments/` - Configurações de deployment
- `docs/` - Documentação
- `scripts/` - Scripts utilitários
- `README.md` - Documentação principal

---

## ⚙️ Configuração Inicial

### 1. Criar Arquivo de Credenciais

```bash
# O arquivo .secrets/credentials.md já existe
# Você pode visualizar (apenas leitura por enquanto)
cat .secrets/credentials.md
```

### 2. Configurar Variáveis de Ambiente

```bash
# Navegar para deployment
cd deployments/topology-a/minimal

# Copiar exemplo de configuração
cp .env.example .env

# Editar arquivo .env
nano .env  # ou seu editor preferido
```

### 3. Configurar API Key de IA

Edite o arquivo `.env` e adicione sua API key:

```bash
# Opção 1: OpenAI (Recomendado)
OPENAI_API_KEY=sk-sua-chave-aqui

# Opção 2: Anthropic (Claude)
# ANTHROPIC_API_KEY=sk-ant-sua-chave-aqui

# Opção 3: Groq (Rápido e barato)
# GROQ_API_KEY=gsk_sua-chave-aqui

# Opção 4: Ollama Local (Grátis, mas precisa rodar Ollama)
# OLLAMA_BASE_URL=http://host.docker.internal:11434
```

**💡 Dica:** Para OpenAI, obtenha sua chave em: https://platform.openai.com/api-keys

---

## 🐳 Instalação do Docker

### 1. Instalar Docker e Docker Compose

**Linux (Ubuntu/Debian):**
```bash
# Voltar para raiz do projeto
cd ~/projects/AppGear

# Instalar Docker e Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose python3-setuptools

# Verificar instalação
docker --version           # Esperado: 28.2+
docker-compose --version   # Esperado: 1.29+
```

**Windows (Docker Desktop):**
1. Baixar Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Instalar e reiniciar o computador
3. Abrir Docker Desktop e habilitar WSL2 backend
4. No terminal WSL2 Ubuntu:
```bash
# Verificar instalação
docker --version
docker compose version  # Note: sem hífen no Windows
```

**macOS:**
```bash
# Instalar via Homebrew
brew install docker docker-compose

# Ou baixar Docker Desktop para Mac
# https://www.docker.com/products/docker-desktop/
```

> ⚠️ **IMPORTANTE:** A versão `docker-compose 1.29.2` tem um bug ao recriar containers. Se encontrar erro `'ContainerConfig'`, use `docker run` manualmente (documentado abaixo).

### 2. Configurar Permissões

**Linux:**
```bash
# Adicionar seu usuário ao grupo docker
sudo usermod -aG docker $USER

# Ativar grupo (ou faça logout/login)
newgrp docker

# Testar sem sudo
docker ps
```

**Windows/macOS:**
- Docker Desktop gerencia permissões automaticamente
- Não é necessário configurar grupos

### 3. Iniciar Serviço Docker

```bash
# Iniciar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verificar status
sudo systemctl status docker
```

---

## 🚀 Inicialização da Stack

### 1. Verificar Porta 80 Disponível

**Linux:**
```bash
# Ver o que está usando porta 80
sudo ss -tlnp | grep :80

# Se Apache2 estiver rodando, parar:
sudo systemctl stop apache2
sudo systemctl disable apache2

# Liberar processos na porta 80 (se necessário)
sudo fuser -k 80/tcp
```

**Windows:**
```powershell
# Verificar porta 80
netstat -ano | findstr :80

# Se IIS estiver rodando, parar:
net stop w3svc

# Ou desabilitar via Services (services.msc)
```

### 2. Navegar para Deployment

```bash
cd ~/projects/AppGear/deployments/topology-a/minimal
```

### 3. Iniciar Serviços Base

```bash
# Iniciar stack base (sem Flowise)
sudo docker-compose up -d traefik kong postgres redis litellm n8n

# Aguardar ~2 minutos
sleep 120

# Verificar status
sudo docker-compose ps
```

### 4. Iniciar Flowise Manualmente

> ⚠️ **Importante:** Devido a um bug no docker-compose 1.29.2 e incompatibilidade do Flowise latest com PostgreSQL, usamos a versão 1.4.7 manualmente.

```bash
# Criar container Flowise manualmente
sudo docker run -d \
  --name appgear-flowise \
  --network appgear-net-core \
  --restart unless-stopped \
  -p 3000:3000 \
  -e DATABASE_TYPE=postgres \
  -e DATABASE_HOST=postgres \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USER=appgear \
  -e DATABASE_PASSWORD=appgear_secure_2025_P@ssw0rd \
  -e DATABASE_NAME=appgear \
  -e DATABASE_SCHEMA=flowise \
  -e FLOWISE_USERNAME=admin \
  -e FLOWISE_PASSWORD=flowise_secure_2025_Fl0w! \
  -e APIKEY_PATH=/root/.flowise \
  -e SECRETKEY_PATH=/root/.flowise \
  -e LOG_LEVEL=info \
  -v flowise_data:/root/.flowise \
  --label traefik.enable=true \
  --label "traefik.http.routers.flowise.rule=PathPrefix(\`/flowise\`)" \
  --label traefik.http.services.flowise.loadbalancer.server.port=3000 \
  flowiseai/flowise:1.4.7 \
  flowise start

# Aguardar Flowise inicializar
sleep 30
```

**Você deve ver 7 serviços rodando:**
- ✅ appgear-traefik
- ✅ appgear-kong  
- ✅ appgear-postgres
- ✅ appgear-redis
- ✅ appgear-litellm
- ✅ appgear-flowise (v1.4.7)
- ✅ appgear-n8n

### 5. Verificar Logs

```bash
# Ver logs de todos os serviços docker-compose
sudo docker-compose logs

# Ver logs do Flowise (criado manualmente)
sudo docker logs appgear-flowise --tail 50

# Ver logs de outros serviços
sudo docker logs appgear-n8n --tail 50
sudo docker logs appgear-litellm --tail 50

# Seguir logs em tempo real
sudo docker logs -f appgear-flowise
```

### 6. Verificar Todos os Containers

```bash
# Listar todos os containers AppGear
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep appgear

# Deve mostrar 7 containers UP
```

---

## ✅ Verificação e Testes

### 1. Executar Script de Validação

```bash
# Voltar para raiz do projeto
cd ~/projects/AppGear

# Executar validação automatizada
./scripts/validate-topology-a.sh
```

**Resultado esperado:** ✓✓✓ Topologia A está FUNCIONANDO!

### 2. Testar Conectividade

```bash
# Testar Flowise
curl http://localhost:3000

# Testar n8n
curl http://localhost:5678

# Testar Traefik
curl http://localhost:8080
```

### 3. Verificar Banco de Dados

```bash
# Conectar ao PostgreSQL
sudo docker exec -it appgear-postgres psql -U appgear -d appgear

# Dentro do PostgreSQL:
\l          # Listar databases
\dn         # Listar schemas
\q          # Sair
```

---

## 🌐 Acesso às Interfaces

### Flowise (AI Workflow Builder)
- **URL:** http://localhost:3000
- **Usuário:** admin
- **Senha:** flowise_secure_2025_Fl0w!
- **Uso:** Criar workflows de IA visual

### n8n (Automation Platform)
- **URL:** http://localhost:5678
- **Usuário:** eu.plima@outlook.com.br
- **Senha:** n8n_secure_2025_N8n!
- **Uso:** Automações e integrações

### Traefik Dashboard
- **URL:** http://localhost:8080
- **Autenticação:** Nenhuma (apenas dev)
- **Uso:** Monitorar roteamento e serviços

### Kong Admin API
- **URL:** http://localhost:8001
- **Autenticação:** Nenhuma (apenas dev)
- **Uso:** Gerenciar API Gateway

### Outros Serviços (Acesso Direto)
- **PostgreSQL:** localhost:5432 (appgear / appgear_secure_2025_P@ssw0rd)
- **Redis:** localhost:6379 (senha: redis_secure_2025_R3d1s!)
- **LiteLLM API:** http://localhost:4000 (Bearer: sk-appgear-master-key-2025-LiteL1M!)

---

## 🔧 Troubleshooting

### Problema: Docker não inicia

```bash
# Verificar status
sudo systemctl status docker

# Reiniciar Docker
sudo systemctl restart docker

# Ver logs
sudo journalctl -u docker -n 50
```

### Problema: Porta 80 em uso

**Linux:**
```bash
# Identificar processo
sudo lsof -i :80
sudo ss -tlnp | grep :80

# Parar Apache2
sudo systemctl stop apache2
sudo systemctl disable apache2

# Forçar liberação da porta
sudo fuser -k 80/tcp
```

**Windows:**
```powershell
# Identificar processo
netstat -ano | findstr :80

# Parar IIS
net stop w3svc

# Ou matar processo específico (substituir PID)
taskkill /PID <numero-do-processo> /F
```

### Problema: Flowise não inicia ou crashloop

> ⚠️ **Causa:** Versão `latest` tem bug de migração com PostgreSQL

**Solução: Usar versão 1.4.7**
```bash
# Parar e remover container problemático
sudo docker stop appgear-flowise
sudo docker rm appgear-flowise

# Limpar schema do banco
sudo docker exec appgear-postgres psql -U appgear -c "DROP SCHEMA IF EXISTS flowise CASCADE; CREATE SCHEMA flowise; GRANT ALL ON SCHEMA flowise TO appgear;"

# Recriar com versão 1.4.7 (comando completo na seção Inicialização)
# Use o comando docker run da seção "4. Iniciar Flowise Manualmente"
```

**Ver logs do Flowise:**
```bash
sudo docker logs appgear-flowise --tail 100

# Seguir em tempo real
sudo docker logs -f appgear-flowise
```

### Problema: docker-compose erro "ContainerConfig"

> ⚠️ **Causa:** Bug no docker-compose 1.29.2 ao recriar containers

**Solução:**
```bash
# Não use: docker-compose up -d --force-recreate
# Isso causa o erro ContainerConfig

# Em vez disso, parar e iniciar:
sudo docker-compose down
sudo docker-compose up -d

# Ou para Flowise, usar docker run manual (veja seção Inicialização)
```

### Problema: LiteLLM mostrando "unhealthy"

> ✅ **Isso é normal!** O healthcheck retorna 401 pois requer autenticação.

**Verificar se está funcional:**
```bash
# Ver logs - deve mostrar "Uvicorn running on http://0.0.0.0:4000"
sudo docker logs appgear-litellm --tail 20

# Testar com autenticação
curl -H "Authorization: Bearer sk-appgear-master-key-2025-LiteL1M!" \
     http://localhost:4000/health
```

### Problema: Containers crashando / Out of Memory

```bash
# Ver recursos do sistema
free -h
df -h

# Ver uso de memória dos containers
sudo docker stats --no-stream

# Aumentar swap se necessário (Linux)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Tornar swap permanente
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**Windows/macOS:**
- Aumentar recursos no Docker Desktop
- Settings → Resources → Aumentar RAM/CPU
- Recomendado: 4GB RAM, 2 CPUs

### Problema: "Permission denied" no Docker

```bash
# Adicionar ao grupo docker
sudo usermod -aG docker $USER

# Fazer logout/login ou:
newgrp docker
```

---

## 🎓 Próximos Passos

### 1. Primeiro Uso - Flowise

1. Acesse http://localhost:3000
2. Login com credenciais do admin
3. Explore a interface
4. Crie um "Chatflow" de exemplo
5. Teste com sua API key de IA

### 2. Primeiro Uso - n8n

1. Acesse http://localhost:5678
2. Login com seu email
3. Crie um "Workflow" de exemplo
4. Conecte com Flowise ou APIs externas
5. Ative e teste o workflow

### 3. Testar Integração

1. Criar workflow no Flowise usando LiteLLM
2. Chamar workflow do Flowise via n8n
3. Verificar logs no Traefik Dashboard
4. Monitorar PostgreSQL

### 4. Expandir Stack (FASE 2)

Quando estiver confortável com a FASE 1:
- Adicionar Prometheus, Grafana, Loki (Observabilidade)
- Adicionar Directus, Appsmith, Metabase (Apps)
- Adicionar Vault (Segredos)
- Adicionar Qdrant (RAG/Vetores)

**Documentação FASE 2:** `docs/guides/phase-2-standard.md` (futuro)

---

## 📚 Recursos Adicionais

### Documentação AppGear
- [README Principal](../../README.md)
- [Arquitetura](../architecture/contract/contract-v0.md)
- [Topologia A](../../deployments/topology-a/README-topology-a.md)
- [Scripts de Validação](../../scripts/README.md)

### Documentação Externa
- [Flowise Docs](https://docs.flowiseai.com/)
- [n8n Docs](https://docs.n8n.io/)
- [LiteLLM Docs](https://docs.litellm.ai/)
- [Docker Docs](https://docs.docker.com/)

### Suporte
- Issues no GitHub
- Documentação em `docs/`
- Arquivo de credenciais em `.secrets/credentials.md`

---

## 📝 Checklist de Instalação

Use este checklist para acompanhar seu progresso:

**Pré-Instalação:**
- [ ] Sistema operacional compatível (Linux/macOS/Windows+WSL2)
- [ ] 4GB RAM disponível
- [ ] 10GB espaço em disco
- [ ] Conexão com internet

**Instalação:**
- [ ] Sistema atualizado
- [ ] Git instalado e funcionando
- [ ] Repositório clonado
- [ ] Arquivo `.env` criado e configurado
- [ ] API key de IA configurada no `.env`
- [ ] Docker instalado (versão 20.10+)
- [ ] Docker Compose instalado (1.29+ ou V2)
- [ ] Permissões Docker configuradas (Linux)
- [ ] Porta 80 liberada (Apache2/IIS parados)

**Inicialização:**
- [ ] Serviços base iniciados (traefik, kong, postgres, redis, litellm, n8n)
- [ ] Flowise v1.4.7 iniciado manualmente
- [ ] Todos os 7 containers UP
- [ ] Script de validação executado com sucesso

**Testes:**
- [ ] Flowise acessível (http://localhost:3000)
- [ ] n8n acessível (http://localhost:5678)
- [ ] Traefik Dashboard acessível (http://localhost:8080)
- [ ] Login no Flowise bem-sucedido
- [ ] Login no n8n bem-sucedido

**Primeiro Uso:**
- [ ] Primeiro workflow criado no Flowise
- [ ] Primeiro workflow criado no n8n
- [ ] Integração Flowise + LiteLLM testada
- [ ] PostgreSQL verificado com dados

---

## 🔄 Atualizações deste Guia

| Data | Versão | Mudanças |
|------|--------|----------|
| 27/11/2025 | 1.0 | Versão inicial - FASE 1 completa |
| 27/11/2025 | 1.1 | Comandos reais testados, Flowise v1.4.7, suporte Windows |
| - | - | (Futuras atualizações serão registradas aqui) |

---

**Autor:** Paulo Lima + Antigravity AI  
**Projeto:** AppGear - AI-First Business Ecosystem Generator  
**Licença:** Ver LICENSE.md na raiz do projeto

---

✨ **Parabéns!** Se chegou até aqui, você tem uma stack AppGear funcional! 🚀
