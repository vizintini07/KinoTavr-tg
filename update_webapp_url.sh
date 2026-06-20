#!/bin/bash

# Скрипт для автоматического обновления WEBAPP_URL и PUBLIC_API_URL после запуска ngrok
# Использование: ./update_webapp_url.sh

set -e

echo "🔍 Waiting for ngrok to start..."
sleep 5

# Получаем ngrok URL для Mini App
NGROK_WEBAPP_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

if [ -z "$NGROK_WEBAPP_URL" ] || [ "$NGROK_WEBAPP_URL" == "null" ]; then
    echo "❌ Error: Cannot get ngrok URL for Mini App"
    echo "Make sure ngrok is running: docker-compose up -d"
    exit 1
fi

echo "✅ Mini App ngrok URL: $NGROK_WEBAPP_URL"

# Получаем ngrok URL для API
NGROK_API_URL=$(curl -s http://localhost:4041/api/tunnels | jq -r '.tunnels[0].public_url')

if [ -z "$NGROK_API_URL" ] || [ "$NGROK_API_URL" == "null" ]; then
    echo "❌ Error: Cannot get ngrok URL for API"
    echo "Make sure ngrok_api is running: docker-compose logs ngrok_api"
    exit 1
fi

echo "✅ API ngrok URL: $NGROK_API_URL"

# Обновляем .env
if [ -f .env ]; then
    sed -i.bak "s|WEBAPP_URL=.*|WEBAPP_URL=$NGROK_WEBAPP_URL|g" .env
    sed -i.bak "s|PUBLIC_API_URL=.*|PUBLIC_API_URL=$NGROK_API_URL/chat|g" .env
    echo "📝 Updated .env file"
else
    echo "⚠️  Warning: .env file not found"
fi

# Перезапускаем бота
echo "🔄 Restarting telegram bot..."
docker-compose restart telegram_bot

echo "✅ Bot restarted successfully!"
echo ""
echo "📱 Mini App URL: $NGROK_WEBAPP_URL"
echo "🔌 API URL: $NGROK_API_URL/chat"
echo ""
echo "🌐 ngrok dashboards:"
echo "   Mini App: http://localhost:4040"
echo "   API: http://localhost:4041"
