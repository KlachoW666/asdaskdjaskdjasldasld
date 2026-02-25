# n8n Server Setup - VPS 188.127.230.83

## Описание

Сервер n8n для автоматизации торговых сигналов, интегрированный с сайтом clabx.ru (91.219.151.7).

## Структура файлов

```
scenarN8N/
├── install.sh          # Скрипт установки n8n на Ubuntu 24.04
├── update.sh           # Скрипт обновления workflow с GitHub
├── config.env          # Конфигурация API ключей
├── crypto-trading-workflow.json    # Полный workflow
├── crypto-trading-full.json        # Расширенный workflow  
└── crypto-analyzer-simple.json      # Упрощённый workflow
```

## Установка на VPS

### 1. Подключение к серверу

```bash
ssh root@188.127.230.83
```

### 2. Клонирование репозитория

```bash
cd /root
git clone https://github.com/KlachoW666/asdaskdjaskdjasldasld.git scenarN8N
cd scenarN8N
```

### 3. Запуск установки

```bash
chmod +x install.sh
bash install.sh
```

## Использование

### Основные команды

```bash
# Статус n8n
pm2 status

# Логи
pm2 logs n8n

# Перезапуск
pm2 restart n8n

# Обновление workflow с GitHub
cd /home/n8n/n8n
./update.sh

# Обновление с конкретной ветки
./update.sh dev

# Принудительное обновление
./update.sh --force
```

### Доступ к n8n

- **Local:** http://188.127.230.83:5678
- **Domain:** https://clabx.ru (через nginx)
- **Webhook:** https://clabx.ru/webhook/

### Учётные данные

- **User:** admin
- **Password:** clabx_admin_2024

## Интеграция с GitHub

### Настройка GitHub

1. Создайте репозиторий на GitHub
2. Загрузите workflow JSON файлы в репозиторий
3. Настройте webhook для автоматических обновлений (опционально)

### Workflows для импорта

Импортируйте файлы в n8n:
1. `crypto-trading-full.json` - основной workflow
2. Или используйте упрощённый: `crypto-analyzer-simple.json`

## Интеграция с clabx.ru

### Связь между серверами

```
n8n Server (188.127.230.83)  <--->  Main Server (91.219.151.7)
         |                              |
      n8n:5678                      clabx.ru:3000
```

### API Communication

**n8n → Main Server:**
```bash
POST http://91.219.151.7:3000/api/trading-signal
Headers: X-API-Key: a8f3k2m9xQpL1nR7vY4wZ0cB6hJ5tU
Body: { symbol, direction, confidence, ... }
```

**Main Server → n8n:**
```bash
POST https://clabx.ru/webhook/analyze
Body: { symbol: "ETHUSDT" }
```

## API Ключи (вшиты)

| Сервис | Ключ |
|--------|------|
| Binance API | YOUR_BINANCE_API_KEY |
| News API | YOUR_NEWS_API_KEY |
| Telegram Bot | YOUR_TELEGRAM_BOT_TOKEN |
| Claude API | YOUR_ANTHROPIC_API_KEY |

## Автоматическое обновление

### Вариант 1: Ручное обновление

```bash
ssh root@188.127.230.83
cd /home/n8n/n8n
./update.sh
```

### Вариант 2: Webhook от GitHub

1. Создайте webhook в репозитории GitHub
2. URL: `http://188.127.230.83:5678/webhook/github`
3. Настройте триггер в n8n

### Вариант 3: Cron

```bash
crontab -e
# Добавить строку:
0 */6 * * * cd /home/n8n/n8n && ./update.sh >> /var/log/n8n-update.log 2>&1
```

## Устранение проблем

### n8n не запускается

```bash
pm2 logs n8n
pm2 restart n8n
```

### Проблемы с портом

```bash
netstat -tlnp | grep 5678
lsof -i :5678
```

### Переустановка n8n

```bash
pm2 stop n8n
pm2 delete n8n
cd /home/n8n/n8n
npm install n8n@latest -g
pm2 start ecosystem.config.js
```
