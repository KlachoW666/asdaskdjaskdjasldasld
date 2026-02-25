#!/bin/bash
# n8n Installation Script for Ubuntu 24.04
# Using official n8n Docker image
# VPS: 188.127.230.83
# Domain: clabx.ru

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INSTALL]${NC} $*"; }
success() { echo -e "${GREEN}[INSTALL]${NC} $*"; }
warn() { echo -e "${YELLOW}[INSTALL][WARN]${NC} $*"; }
err() { echo -e "${RED}[INSTALL][ERROR]${NC} $*" >&2; }

# Configuration
N8N_PORT=5678
N8N_DIR="/root/n8n"
DOMAIN="clabx.ru"
MAIN_SERVER="91.219.151.7"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "  🚀 n8n Installation Script (Docker)"
log "  Server: 188.127.230.83"
log "  Domain: ${DOMAIN}"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  err "Запустите скрипт от root: sudo bash install.sh"
  exit 1
fi

# Update system
log "Обновляем систему..."
apt update && apt upgrade -y

# Install required packages
log "Устанавливаем необходимые пакеты..."
apt install -y curl wget git unzip nginx certbot python3 python3-pip ca-certificates gnupg

# Install Docker
if ! command -v docker &> /dev/null; then
  log "Устанавливаем Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
  success "Docker установлен"
else
  success "Docker уже установлен"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
  log "Устанавливаем Docker Compose..."
  curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  success "Docker Compose установлен"
fi

# Create n8n directory
log "Создаём директорию n8n..."
mkdir -p ${N8N_DIR}
mkdir -p ${N8N_DIR}/workflows
mkdir -p ${N8N_DIR}/data

# Create environment file
log "Создаём конфигурацию..."
cat > ${N8N_DIR}/.env << 'EOF'
# n8n Configuration
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=0.0.0.0
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=clabx_admin_2024
N8N_ENCRYPTION_KEY=n8n_clabx_encryption_key_2024

# Webhook URL
N8N_WEBHOOK_URL=https://${DOMAIN}/webhook/

# Execution
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
EXECUTIONS_TIMEOUT=300
EXECUTIONS_TIMEOUT_MAX=600

# Webhook settings
WEBHOOK_URL=https://${DOMAIN}/webhook/

# N8N Docker Image
N8N_IMAGE=docker.n8n.io/n8nio/n8n
N8N_TAG=latest

# Proxy settings
HTTP_PROXY=http://127.0.0.1:10809
HTTPS_PROXY=http://127.0.0.1:10809
NO_PROXY=localhost,127.0.0.1

# Your API Keys (SET THESE!)
BINANCE_API_KEY=YOUR_BINANCE_API_KEY
BINANCE_API_SECRET=YOUR_BINANCE_API_SECRET
NEWS_API_KEY=YOUR_NEWS_API_KEY
TELEGRAM_BOT_TOKEN=YOUR_TELEGRAM_BOT_TOKEN
ANTHROPIC_API_KEY=YOUR_ANTHROPIC_API_KEY
MAIN_SERVER_API_KEY=YOUR_MAIN_SERVER_API_KEY
SITE_API_KEY=YOUR_SITE_API_KEY

# Main Server
MAIN_SERVER_URL=http://91.219.151.7:3000
SITE_URL=https://clabx.ru
EOF

# Create docker-compose.yml
log "Создаём docker-compose.yml..."
cat > ${N8N_DIR}/docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: ${N8N_IMAGE}:${N8N_TAG}
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=clabx_admin_2024
      - N8N_ENCRYPTION_KEY=n8n_clabx_encryption_key_2024
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=https://clabx.ru/webhook/
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_TIMEOUT=300
      - N8N_LOG_LEVEL=info
      - HTTP_PROXY=http://127.0.0.1:10809
      - HTTPS_PROXY=http://127.0.0.1:10809
      - NO_PROXY=localhost,127.0.0.1
      # API Keys - Set your own keys
      - BINANCE_API_KEY=YOUR_BINANCE_API_KEY
      - BINANCE_API_SECRET=YOUR_BINANCE_API_SECRET
      - NEWS_API_KEY=YOUR_NEWS_API_KEY
      - TELEGRAM_BOT_TOKEN=YOUR_TELEGRAM_BOT_TOKEN
      - ANTHROPIC_API_KEY=YOUR_ANTHROPIC_API_KEY
      - MAIN_SERVER_URL=http://91.219.151.7:3000
      - MAIN_SERVER_API_KEY=YOUR_MAIN_SERVER_API_KEY
      - SITE_URL=https://clabx.ru
      - SITE_API_KEY=YOUR_SITE_API_KEY
    volumes:
      - ${N8N_DIR}/data:/home/node/.n8n
      - ${N8N_DIR}/workflows:/home/node/.n8n/workflows
    networks:
      - n8n_network

networks:
  n8n_network:
    driver: bridge
EOF

# Configure Nginx reverse proxy
log "Настраиваем Nginx..."
cat > /etc/nginx/sites-available/n8n << EOF
server {
    listen 80;
    server_name n8n.clabx.ru;

    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_buffering off;
        proxy_request_buffering off;
        
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /websocket {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Enable nginx site
ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n

# Test nginx config
nginx -t && systemctl reload nginx
success "Nginx настроен"

# Copy workflow files
if [ -d "/root/scenarN8N" ]; then
  log "Копируем workflow файлы..."
  cp -r /root/scenarN8N/* ${N8N_DIR}/workflows/
  success "Workflow файлы скопированы"
fi

# Start n8n with Docker
log "Запускаем n8n..."
cd ${N8N_DIR}
docker-compose up -d

# Wait for n8n to start
log "Ожидаем запуск n8n..."
sleep 10

# Check status
if docker ps | grep -q n8n; then
  success "n8n запущен!"
else
  err "Ошибка запуска n8n. Проверьте логи: docker logs n8n"
fi

# Enable firewall
log "Настраиваем firewall..."
ufw allow 22/tcp 2>/dev/null || true
ufw allow 80/tcp 2>/dev/null || true
ufw allow 443/tcp 2>/dev/null || true
ufw allow 5678/tcp 2>/dev/null || true

# Create update script
log "Создаём скрипт обновления..."
cat > ${N8N_DIR}/update.sh << 'UPDATEEOF'
#!/bin/bash
# n8n Update Script - Docker

set -e

N8N_DIR="/root/n8n"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[UPDATE]${NC} $*"; }
success() { echo -e "${GREEN}[UPDATE]${NC} $*"; }

BRANCH=${1:-main}

cd ${N8N_DIR}

log "Останавливаем n8n..."
docker-compose down

log "Скачиваем новый образ..."
docker-compose pull

log "Запускаем n8n..."
docker-compose up -d

success "Обновление завершено!"
log "n8n доступен на: http://188.127.230.83:5678"

UPDATEEOF

chmod +x ${N8N_DIR}/update.sh

# Final status
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "  ✅ n8n Installation Complete!"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Доступ к n8n:"
echo "   Local:   http://localhost:5678"
echo "   Server:  http://188.127.230.83:5678"
echo "   Domain:  https://clabx.ru (nginx)"
echo ""
echo "🔑 Учётные данные:"
echo "   User: admin"
echo "   Password: clabx_admin_2024"
echo ""
echo "📁 Директория: ${N8N_DIR}"
echo "📁 Workflows:  ${N8N_DIR}/workflows"
echo ""
echo "📝 Команды:"
echo "   docker ps               - Статус контейнеров"
echo "   docker logs n8n        - Логи n8n"
echo "   docker-compose restart - Перезапуск"
echo "   ${N8N_DIR}/update.sh  - Обновление"
echo ""

# Show status
docker ps
