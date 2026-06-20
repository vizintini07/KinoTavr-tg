#!/bin/bash
# Финальный скрипт запуска KinoTavr с ngrok

set -e

echo "=== 🚀 Запуск KinoTavr с ngrok ==="
echo ""

# Шаг 1: Проверка .env файла
echo "📋 Шаг 1: Проверка .env файла"
if [ ! -f .env ]; then
    echo "❌ Файл .env не найден!"
    echo ""
    echo "Создайте .env файл:"
    echo "  cp .env.server.example .env"
    echo "  nano .env"
    echo ""
    echo "Заполните обязательные переменные:"
    echo "  - TELEGRAM_BOT_TOKEN"
    echo "  - OPENAI_API_KEY"
    echo "  - NGROK_AUTHTOKEN"
    exit 1
fi

# Проверка обязательных переменных
required_vars=("TELEGRAM_BOT_TOKEN" "OPENAI_API_KEY" "NGROK_AUTHTOKEN")
missing_vars=()

for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env 2>/dev/null || grep -q "^${var}=your_" .env 2>/dev/null || grep -q "^${var}=ваш_" .env 2>/dev/null; then
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

echo "✅ .env файл настроен корректно"
echo ""

# Шаг 2: Остановка старых контейнеров
echo "🛑 Шаг 2: Остановка старых контейнеров"
docker-compose down 2>/dev/null || true
echo "✅ Старые контейнеры остановлены"
echo ""

# Шаг 3: Пересборка telegram_bot
echo "🔨 Шаг 3: Пересборка telegram_bot"
docker-compose build telegram_bot
echo "✅ telegram_bot пересобран"
echo ""

# Шаг 4: Запуск всех сервисов
echo "🚀 Шаг 4: Запуск всех сервисов"
docker-compose up -d
echo "✅ Все сервисы запущены"
echo ""

# Шаг 5: Ожидание запуска
echo "⏳ Шаг 5: Ожидание инициализации сервисов (30 сек)..."
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo ""
echo ""

# Проверка статуса контейнеров
echo "=== 📊 Статус контейнеров ==="
docker-compose ps
echo ""

# Шаг 6: Получение ngrok URLs
echo "🌐 Шаг 6: Получение ngrok URLs"

# Ждём ещё немного для ngrok
sleep 10

# Получаем URL для Mini App
NGROK_WEBAPP_URL=""
for i in {1..10}; do
    NGROK_WEBAPP_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null)
    if [ ! -z "$NGROK_WEBAPP_URL" ] && [ "$NGROK_WEBAPP_URL" != "null" ]; then
        break
    fi
    echo "  Попытка $i/10: ожидание ngrok для Mini App..."
    sleep 3
done

# Получаем URL для API
NGROK_API_URL=""
for i in {1..10}; do
    NGROK_API_URL=$(curl -s http://localhost:4041/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null)
    if [ ! -z "$NGROK_API_URL" ] && [ "$NGROK_API_URL" != "null" ]; then
        break
    fi
    echo "  Попытка $i/10: ожидание ngrok для API..."
    sleep 3
done

# Проверяем результаты
if [ -z "$NGROK_WEBAPP_URL" ] || [ "$NGROK_WEBAPP_URL" == "null" ]; then
    echo "⚠️  Не удалось получить ngrok URL для Mini App"
    echo ""
    echo "Проверьте вручную:"
    echo "  1. Логи ngrok: docker-compose logs ngrok"
    echo "  2. Откройте: http://localhost:4040"
    echo ""
    echo "После получения URL выполните:"
    echo "  ./update_webapp_url.sh"
    exit 1
fi

if [ -z "$NGROK_API_URL" ] || [ "$NGROK_API_URL" == "null" ]; then
    echo "⚠️  Не удалось получить ngrok URL для API"
    echo ""
    echo "Проверьте вручную:"
    echo "  1. Логи ngrok_api: docker-compose logs ngrok_api"
    echo "  2. Откройте: http://localhost:4041"
    echo ""
    echo "После получения URL выполните:"
    echo "  ./update_webapp_url.sh"
    exit 1
fi

echo "✅ Mini App URL: $NGROK_WEBAPP_URL"
echo "✅ API URL: $NGROK_API_URL"
echo ""

# Шаг 7: Обновление .env
echo "📝 Шаг 7: Обновление .env с ngrok URLs"

# Создаём бэкап
cp .env .env.backup

# Обновляем URLs
if grep -q "^WEBAPP_URL=" .env; then
    sed -i.tmp "s|^WEBAPP_URL=.*|WEBAPP_URL=$NGROK_WEBAPP_URL|g" .env
else
    echo "WEBAPP_URL=$NGROK_WEBAPP_URL" >> .env
fi

if grep -q "^PUBLIC_API_URL=" .env; then
    sed -i.tmp "s|^PUBLIC_API_URL=.*|PUBLIC_API_URL=$NGROK_API_URL/chat|g" .env
else
    echo "PUBLIC_API_URL=$NGROK_API_URL/chat" >> .env
fi

rm -f .env.tmp

echo "✅ .env обновлён"
echo ""

# Шаг 8: Перезапуск бота
echo "🔄 Шаг 8: Перезапуск telegram_bot с новыми URLs"
docker-compose restart telegram_bot
echo "✅ Бот перезапущен"
echo ""

# Финал
echo "=== ✅ Запуск завершён успешно! ==="
echo ""
echo "📱 Mini App URL: $NGROK_WEBAPP_URL"
echo "🔌 API URL: $NGROK_API_URL/chat"
echo ""
echo "🌐 ngrok dashboards:"
echo "   Mini App: http://localhost:4040"
echo "   API: http://localhost:4041"
echo ""
echo "📋 Полезные команды:"
echo "  docker-compose logs -f telegram_bot  # Логи бота"
echo "  docker-compose logs -f ngrok         # Логи ngrok Mini App"
echo "  docker-compose logs -f ngrok_api     # Логи ngrok API"
echo "  docker-compose ps                    # Статус контейнеров"
echo ""
echo "🎬 Откройте бота в Telegram:"
echo "   1. Отправьте /start"
echo "   2. Нажмите '🎬 Открыть Кинотавр'"
echo "   3. Mini App должен работать без ошибок!"
echo ""
