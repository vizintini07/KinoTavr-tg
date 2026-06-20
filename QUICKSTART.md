# 🚀 Быстрый старт - Запуск за 3 шага

## Шаг 1: Создайте .env файл

```bash
cd /path/to/KinoTavr
cp .env.server.example .env
nano .env
```

**Заполните 3 обязательные переменные:**

```env
TELEGRAM_BOT_TOKEN=ваш_токен_бота
OPENAI_API_KEY=ваш_openai_или_groq_ключ
NGROK_AUTHTOKEN=ваш_ngrok_токен
```

Остальные переменные уже настроены по умолчанию.

---

## Шаг 2: Запустите всё одной командой

```bash
chmod +x start.sh
./start.sh
```

**Скрипт автоматически:**
- ✅ Проверит .env
- ✅ Остановит старые контейнеры
- ✅ Пересоберёт бота
- ✅ Запустит все сервисы (DB, AI, Bot, 2x ngrok)
- ✅ Получит ngrok URLs
- ✅ Обновит .env с реальными URLs
- ✅ Перезапустит бота

---

## Шаг 3: Проверьте работу

### 1. Откройте Telegram бота
- Отправьте `/start`
- Нажмите кнопку **"🎬 Открыть Кинотавр"**

### 2. Mini App должен открыться
- Красивый градиентный фон
- Приветственное сообщение
- Можно начать диалог

### 3. Проверьте что диалог работает
- Напишите: "Хочу что-то весёлое"
- Бот должен задать уточняющие вопросы
- В конце получите рекомендацию фильма

---

## 🌐 Проверка ngrok

```bash
# Dashboards
http://localhost:4040  # Mini App ngrok
http://localhost:4041  # API ngrok

# Логи
docker-compose logs -f telegram_bot
docker-compose logs -f ngrok
docker-compose logs -f ngrok_api
docker-compose logs -f ai_backend

# Статус
docker-compose ps
```

---

## ❌ Если что-то не работает

### Проблема: ngrok не запустился
```bash
# Проверьте токен
grep NGROK_AUTHTOKEN .env

# Логи
docker-compose logs ngrok
docker-compose logs ngrok_api
```

### Проблема: Mini App не открывается
```bash
# Проверьте WEBAPP_URL
grep WEBAPP_URL .env

# Должен быть ngrok URL вида: https://xxx.ngrok-free.app
# Если нет - запустите вручную:
./update_webapp_url.sh
```

### Проблема: "Ошибка связи с сервером" в Mini App
```bash
# Проверьте PUBLIC_API_URL
grep PUBLIC_API_URL .env

# Должен быть: https://xxx.ngrok-free.app/chat
# Если нет - запустите:
./update_webapp_url.sh
```

### Проблема: AI backend не отвечает
```bash
# Проверьте логи
docker-compose logs ai_backend

# Проверьте что порт 8001 работает
curl http://localhost:8001/ping
```

### Полная диагностика
```bash
chmod +x diagnose.sh
./diagnose.sh
```

---

## 🔄 Перезапуск после изменений

```bash
# Быстрый перезапуск бота
docker-compose restart telegram_bot

# Полный перезапуск всего
docker-compose down
docker-compose up -d
./update_webapp_url.sh
```

---

## 🛑 Остановка

```bash
docker-compose down
```

---

## ✅ Готово!

После выполнения всех шагов у вас будет:
- 🤖 Работающий Telegram бот
- 🎬 Mini App с красивым UI
- 🧠 AI backend для рекомендаций
- 🌐 2 ngrok туннеля (для Mini App и API)
- 📊 Все логи и мониторинг

**Наслаждайтесь!** 🎉
