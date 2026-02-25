# N8N Workflow - Crypto Trading Signal Analyzer

## Описание

Полностью автоматизированный workflow для анализа криптовалютных торговых сигналов.

## Функциональность

1. **Сбор данных с Binance:**
   - Свечи 1m, 5m, 1h
   - Стакан (Order Book)
   - 24h тикер

2. **Технический анализ:**
   - Анализ свечей (паттерны, RSI, EMA, объём)
   - Анализ стакана (DOM Score, Imbalance, Walls)
   - Группировка по таймфреймам

3. **Анализ новостей:**
   - NewsAPI для получения крипто-новостей
   - Сентимент-анализ

4. **AI анализ:**
   - Anthropic Claude для финального решения
   - Рекомендация: LONG / SHORT / WAIT

5. **Риск-менеджмент:**
   - Проверка минимальной уверенности
   - Рекомендация по открытию сделки

6. **Уведомления:**
   - Telegram бот
   - Отправка на сайт clabx.ru

## Установка

### 1. Импорт workflow

1. Откройте n8n на вашем VPS (http://91.219.151.7:5678)
2. Перейдите в Workflows → Import from File
3. Выберите файл `crypto-trading-workflow.json`

### 2. Настройка API ключей

Создайте Credentials в n8n:

#### Telegram:
- Type: Telegram API
- Bot Token: `YOUR_TELEGRAM_BOT_TOKEN`

#### Anthropic API:
- Type: Header Auth
- Headers:
  - `x-api-key`: `YOUR_ANTHROPIC_API_KEY`
  - `anthropic-version`: `2023-06-01`

### 3. Настройка переменных

В узле "Set Symbol" можно задать:
- `symbol` - символ для анализа (по умолчанию ETHUSDT)
- Параметры риск-менеджмента

## Использование

### Ручной запуск:
Нажмите "Execute Workflow" и введите символ (например, ETHUSDT, BTCUSDT)

### Автоматический запуск:
Workflow настроен на автоматический запуск каждые 5 минут

## API Endpoints

### Webhook для внешних запросов

Добавьте узел Webhook перед "Set Symbol" для приёма внешних запросов:

```json
{
  "method": "GET",
  "path": "crypto-analyze",
  "responseMode": "onReceived",
  "options": {}
}
```

Пример запроса:
```
https://your-n8n-url.com/webhook/crypto-analyze?symbol=ETHUSDT
```

## Интеграция с clabx.ru

Сайт отправляет запросы на n8n webhook для получения анализа.
Настройте в n8n webhook и обновите URL в коде сайта.

## Структура ответа

```json
{
  "symbol": "ETHUSDT",
  "final": {
    "direction": "LONG",
    "confidence": 0.75
  },
  "riskManagement": {
    "shouldTrade": true,
    "recommendedAction": "Открыть позицию LONG"
  },
  "aiRecommendation": "LONG"
}
```
