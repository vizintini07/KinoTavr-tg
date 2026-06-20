#!/bin/bash
# Инструкция по запуску KinoTavr с ngrok

echo "=== Запуск KinoTavr с ngrok ==="
echo ""

# Шаг 1: Проверка .env файла
echo "Шаг 1: Проверка .env файла"
if [ ! -f .env ]; then
    echo "❌ Файл .env не найден!"
    echo "Создайте .env файл на основе .env.example:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Проверка обязательных переменных
required_vars=("TELEGRAM_BOT_TOKEN" "OPENAI_API_KEY" "NGROK_AUTHTOKEN")
missing_vars=()

for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env || grep -q "^${var}=your_" .env; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "❌ Не хватает переменных в .env:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Откройте .env и заполните эти переменные:"
    echo "  nano .env"
    exit 1
fi

echo "✅ .env файл настроен"
echo ""

# Шаг 2: Остановка старых контейнеров
echo "Шаг 2: Остановка старых контейнеров"
docker-compose down
echo "✅ Старые контейнеры остановлены"
echo ""

# Шаг 3: Пересборка telegram_bot
echo "Шаг 3: Пересборка telegram_bot"
docker-compose build telegram_bot
echo "✅ telegram_bot пересобран"
echo ""

# Шаг 4: Запуск всех сервисов
echo "Шаг 4: Запуск всех сервисов (включая ngrok)"
docker-compose up -d
echo "✅ Все сервисы запущены"
echo ""

# Шаг 5: Ожидание запуска
echo "Шаг 5: Ожидание инициализации сервисов..."
sleep 10

# Проверка статуса
echo ""
echo "=== Статус контейнеров ==="
docker-compose ps
echo ""

# Шаг 6: Получение ngrok URL
echo "Шаг 6: Получение ngrok URL"
sleep 5

NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null)

if [ -z "$NGROK_URL" ] || [ "$NGROK_URL" == "null" ]; then
    echo "⚠️  Не удалось получить ngrok URL автоматически"
    echo ""
    echo "Проверьте вручную:"
    echo "  1. Откройте http://localhost:4040 в браузере"
    echo "  2. Или выполните: curl http://localhost:4040/api/tunnels | jq"
    echo ""
    echo "После получения URL запустите:"
    echo "  ./update_webapp_url.sh"
else
    echo "✅ ngrok URL получен: $NGROK_URL"
    echo ""

    # Шаг 7: Обновление WEBAPP_URL
    echo "Шаг 7: Обновление WEBAPP_URL"

    # Обновляем .env
    sed -i.bak "s|WEBAPP_URL=.*|WEBAPP_URL=$NGROK_URL|g" .env

    # Перезапускаем бота
    docker-compose restart telegram_bot

    echo "✅ WEBAPP_URL обновлен в .env"
    echo "✅ telegram_bot перезапущен"
fi

echo ""
echo "=== ✅ Запуск завершён! ==="
echo ""
echo "📱 Mini App URL: $NGROK_URL"
echo "🌐 ngrok dashboard: http://localhost:4040"
echo ""
echo "Полезные команды:"
echo "  docker-compose logs -f telegram_bot  # Логи бота"
echo "  docker-compose logs -f ngrok         # Логи ngrok"
echo "  docker-compose ps                     # Статус контейнеров"
echo "  ./diagnose.sh                         # Диагностика проблем"
echo ""
echo "Откройте бота в Telegram и нажмите кнопку '🎬 Открыть Кинотавр'"
