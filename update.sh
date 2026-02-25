#!/bin/bash
# n8n Workflow Update Script
# Updates n8n Docker container and workflows
# Server: 188.127.230.83 (n8n)
# Main Server: 91.219.151.7 (clabx.ru)

set -e

# Configuration
N8N_DIR="/root/n8n"
N8N_PORT=5678
MAIN_SERVER="91.219.151.7"
GITHUB_REPO="https://github.com/KlachoW666/asdaskdjaskdjasldasld.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[UPDATE]${NC} $*"; }
success() { echo -e "${GREEN}[UPDATE]${NC} $*"; }
warn() { echo -e "${YELLOW}[UPDATE][WARN]${NC} $*"; }
err() { echo -e "${RED}[UPDATE][ERROR]${NC} $*" >&2; }

# Parse arguments
NO_RESTART=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-restart)
      NO_RESTART=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --help|-h)
      echo "n8n Workflow Update Script (Docker)"
      echo ""
      echo "Usage: $0 [options] [branch]"
      echo ""
      echo "Options:"
      echo "  --no-restart  Не перезапускать n8n"
      echo "  --force       Принудительное обновление"
      echo "  --help, -h    Показать справку"
      echo ""
      echo "Examples:"
      echo "  $0                    # Обновить n8n"
      echo "  $0 --force            # Принудительно"
      exit 0
      ;;
    *)
      BRANCH="$1"
      shift
      ;;
  esac
done

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "  🔄 n8n Docker Update"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if n8n directory exists
if [ ! -d "${N8N_DIR}" ]; then
  err "Директория n8n не найдена: ${N8N_DIR}"
  err "Сначала запустите install.sh"
  exit 1
fi

cd ${N8N_DIR}

# Stop n8n
if [ "${NO_RESTART}" = false ]; then
  log "Останавливаем n8n..."
  docker-compose down
fi

# Pull latest image
log "Скачиваем обновления образа n8n..."
docker-compose pull

# Copy new workflow files from GitHub if repo exists
if [ -d "${N8N_DIR}/workflows/.git" ]; then
  log "Обновляем workflow файлы..."
  cd ${N8N_DIR}/workflows
  git fetch origin
  git pull origin master || warn "Не удалось обновить workflows"
fi

# Start n8n
if [ "${NO_RESTART}" = false ]; then
  log "Запускаем n8n..."
  docker-compose up -d
  sleep 5
fi

# Notify main server
log "Уведомляем main server (${MAIN_SERVER})..."
curl -s -X POST "http://${MAIN_SERVER}:3000/api/n8n-sync" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: a8f3k2m9xQpL1nR7vY4wZ0cB6hJ5tU" \
  -d "{\"status\":\"updated\",\"type\":\"docker\"}" \
  2>/dev/null || warn "Не удалось уведомить main server"

# Final status
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "  ✅ Обновление завершено!"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Доступ к n8n:"
echo "   http://188.127.230.83:${N8N_PORT}"
echo "   https://clabx.ru (nginx)"
echo ""
echo "📝 Команды:"
echo "   docker ps                 - Статус"
echo "   docker logs n8n          - Логи"
echo "   docker-compose restart   - Перезапуск"
echo ""

# Show status
docker ps
