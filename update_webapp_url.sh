#!/bin/bash
# Скрипт для автоматического обновления WEBAPP_URL и PUBLIC_API_URL

set -e

echo "🔍 Получение ngrok URLs..."
echo ""

# Ждём немного для гарантии
sleep 3

# Получаем URL для Mini App
echo "📱 Проверка ngrok для Mini App (порт 4040)..."
NGROK_WEBAPP_URL=""
for i in {1..5}; do
    NGROK_WEBAPP_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null)
    if [ ! -z "$NGROK_WEBAPP_URL" ] && [ "$NGROK_WEBAPP_URL" != "null" ]; then
        echo "✅ Mini App URL: $NGROK_WEBAPP_URL"
        break
    fi
    echo "   Попытка $i/5..."
    sleep 2
done

if [ -z "$NGROK_WEBAPP_URL" ] || [ "$NGROK_WEBAPP_URL" == "null" ]; then
    echo "❌ Не удалось получить ngrok URL для Mini App"
    echo ""
    echo "Проверьте:"
    echo "  docker-compose logs ngrok"
    echo "  http://localhost:4040"
    exit 1
fi

# Получаем URL для API
echo ""
echo "🔌 Проверка ngrok для API (порт 4041)..."
NGROK_API_URL=""
for i in {1..5}; do
    NGROK_API_URL=$(curl -s http://localhost:4041/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null)
    if [ ! -z "$NGROK_API_URL" ] && [ "$NGROK_API_URL" != "null" ]; then
        echo "✅ API URL: $NGROK_API_URL"
        break
    fi
    echo "   Попытка $i/5..."
    sleep 2
done

if [ -z "$NGROK_API_URL" ] || [ "$NGROK_API_URL" == "null" ]; then
    echo "❌ Не удалось получить ngrok URL для API"
    echo ""
    echo "Проверьте:"
    echo "  docker-compose logs ngrok_api"
    echo "  http://localhost:4041"
    exit 1
fi

echo ""
echo "📝 Обновление .env файла..."

# Создаём бэкап
cp .env .env.backup

# Обновляем WEBAPP_URL
if grep -q "^WEBAPP_URL=" .env; then
    sed -i.tmp "s|^WEBAPP_URL=.*|WEBAPP_URL=$NGROK_WEBAPP_URL|g" .env
else
    echo "WEBAPP_URL=$NGROK_WEBAPP_URL" >> .env
fi

# Обновляем PUBLIC_API_URL
if grep -q "^PUBLIC_API_URL=" .env; then
    sed -i.tmp "s|^PUBLIC_API_URL=.*|PUBLIC_API_URL=$NGROK_API_URL/chat|g" .env
else
    echo "PUBLIC_API_URL=$NGROK_API_URL/chat" >> .env
fi

# Удаляем временные файлы
rm -f .env.tmp

echo "✅ .env обновлён"
echo "   Бэкап сохранён: .env.backup"
echo ""

# Перезапускаем бота
echo "🔄 Перезапуск telegram_bot..."
docker-compose restart telegram_bot

# Ждём запуска
sleep 5

echo ""
echo "=== ✅ Готово! ==="
echo ""
echo "📱 Mini App URL: $NGROK_WEBAPP_URL"
echo "🔌 API URL: $NGROK_API_URL/chat"
echo ""
echo "🌐 Dashboards:"
echo "   Mini App: http://localhost:4040"
echo "   API: http://localhost:4041"
echo ""
echo "🎬 Теперь откройте бота в Telegram и нажмите '🎬 Открыть Кинотавр'"
echo ""
