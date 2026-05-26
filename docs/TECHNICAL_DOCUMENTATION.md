# ScanAI / Oysyn Mobile: техническая документация

## 1. Тестовая среда: адреса и хостнеймы

### Mobile Backend

| Назначение | Адрес |
| --- | --- |
| API мобильного backend | `https://api-mobile.oysyn.asia/api/v1` |
| Swagger / OpenAPI backend | `https://api-mobile.oysyn.asia/api/docs` |
| Healthcheck backend | `https://api-mobile.oysyn.asia/health` |
| Локальный запуск backend | `http://127.0.0.1:8000` |

### Oysyn Internal API

| Назначение | Адрес |
| --- | --- |
| Internal API тестовой среды | `http://192.168.142.220/api/internal/v1` |
| Авторизация service-to-service | `Authorization: Bearer <MOBILE_BACKEND_SECRET>` |
| Идентификатор пользователя | `X-Mobile-User-Id: <user_id>` |

### Тестовая база данных

| Параметр | Значение |
| --- | --- |
| Host | `127.0.0.1` |
| Port | `5432` |
| Database | `oysyn` |
| User | `oysyn` |

Пароль хранится только в `.env`. Не коммитить реальные значения секретов, токенов и паролей.

### Внешние сервисы

| Сервис | Назначение |
| --- | --- |
| ZeroGPT / RapidAPI | Проверка текста на AI-generated content |
| Oysyn DB / PostgreSQL | Единый источник пользователей, организаций, проверок и отчетов |
| Tesseract OCR | Распознавание текста из изображений |

## 2. Общая архитектура

Целевая схема первого этапа: мобильное приложение работает только с Mobile Backend, а Mobile Backend ходит во внутренние роуты Oysyn Core API. Oysyn Production/Test DB остается единственным источником бизнес-данных.

```text
Mobile App (iOS / Android)
  |
  | вызывает только публичный mobile API
  v
Mobile Backend (FastAPI)
  | /api/v1/auth/login
  | /api/v1/auth/verify
  | /api/v1/me
  | /api/v1/checks
  | /api/v1/checks/{id}
  | /api/v1/checks/{id}/report
  | /api/v1/checks/{id}/report/pdf/{type}
  |
  | вызывает только internal API
  v
Oysyn Core API
  | /api/internal/v1/auth/login
  | /api/internal/v1/auth/verify
  | /api/internal/v1/users/me
  | /api/internal/v1/checks
  | /api/internal/v1/checks/{id}
  | /api/internal/v1/checks/{id}/report
  | /api/internal/v1/checks/{id}/report/pdf/{type}/
  |
  | работает с БД
  v
Oysyn DB
```

### Flutter app

Клиентская часть находится в корне проекта `ai_scan_text`.

Основные зоны:

| Путь | Назначение |
| --- | --- |
| `lib/services/api_service.dart` | Общая HTTP-обертка для запросов к backend |
| `lib/services/auth_service.dart` | Логин, регистрация, сохранение токена |
| `lib/services/scan_service.dart` | Отправка текста/файлов на проверку |
| `lib/storage/token_storage.dart` | Локальное хранение access token |
| `lib/screens/*` и `lib/features/*` | UI мобильного приложения |

Клиент авторизуется через `/api/v1/auth/login`, сохраняет mobile JWT access token и отправляет его в заголовке:

```http
Authorization: Bearer <access_token>
```

### Mobile Backend

Backend находится в соседней директории `../ai_scan_text_back`.

Основные файлы:

| Путь | Назначение |
| --- | --- |
| `main.py` | Создание FastAPI app, CORS, подключение роутов |
| `database.py` | Подключение к PostgreSQL через `DATABASE_URL` |
| `auth_service.py` | JWT, регистрация, логин, получение текущего пользователя |
| `routes/mobile_v1.py` | Новый публичный API для мобильного приложения `/api/v1/*` |
| `routes/mobile_v1.py` | Production API для мобильного приложения `/api/v1/*` |
| `services/oysyn_core_client.py` | HTTP-клиент для Oysyn Core Internal API |
| `services/gpt_zero_service.py` | Интеграция с ZeroGPT / RapidAPI |
| `services/document_parser.py` | Извлечение текста из документов |
| `.env` | Локальные секреты и настройки окружения |

Backend выполняет четыре ключевые функции:

1. Принимает запросы мобильного приложения только через `/api/v1`.
2. Логинит пользователя через Oysyn Core Internal API и выдает mobile JWT.
3. Для приватных запросов извлекает `user_id` из mobile JWT.
4. Проксирует профиль, проверки и отчеты в Oysyn Core API с `MOBILE_BACKEND_SECRET` и `X-Mobile-User-Id`.

### База данных

Текущая backend-модель использует PostgreSQL через SQLAlchemy. В тестовой среде подключение должно идти через переменную:

```env
DATABASE_URL=postgresql://oysyn:<URL_ENCODED_DB_PASSWORD>@127.0.0.1:5432/oysyn
```

Реальный пароль хранится в `.env` и не должен попадать в git.

### Интеграция с Oysyn Internal API

Oysyn Internal API используется как service-to-service интеграция. Для всех запросов, кроме `POST /auth/login`, backend должен передавать:

```http
Authorization: Bearer <MOBILE_BACKEND_SECRET>
X-Mobile-User-Id: <user_id>
```

`MOBILE_BACKEND_SECRET` хранится в `.env`. Значение используется только на backend-стороне и не должно передаваться во Flutter-клиент.

## 3. Переменные окружения

Реальные секреты должны лежать в `.env`, шаблон без секретов - в `.env.example`.

Рекомендуемый набор:

```env
DATABASE_URL=postgresql://oysyn:<URL_ENCODED_DB_PASSWORD>@127.0.0.1:5432/oysyn
SECRET_KEY=<jwt-secret-min-32-chars>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

MOBILE_BACKEND_SECRET=<oysyn-internal-api-token>
OYSYN_INTERNAL_API_BASE_URL=http://192.168.142.220/api/internal/v1
OYSYN_INTERNAL_API_TIMEOUT=30

ZEROGPTURL=https://zerogpt.p.rapidapi.com/api/v1/detectText
X_RAPIDAPI_KEY=<rapidapi-key>
X_RAPIDAPI_HOST=zerogpt.p.rapidapi.com
```

Важно: во Flutter-приложение нельзя вшивать `MOBILE_BACKEND_SECRET`, пароль от DB или RapidAPI ключ. Все секретные вызовы выполняются только через backend.

## 4. Запуск backend в тестовой среде

1. Установить зависимости:

```bash
pip install -r requirements.txt
```

2. Проверить `.env`:

```bash
DATABASE_URL=postgresql://oysyn:<URL_ENCODED_DB_PASSWORD>@127.0.0.1:5432/oysyn
MOBILE_BACKEND_SECRET=<token>
OYSYN_INTERNAL_API_BASE_URL=http://192.168.142.220/api/internal/v1
```

3. Запустить backend:

```bash
uvicorn main:app --host 0.0.0.0 --port 8082
```

4. Проверить healthcheck:

```bash
curl https://api-mobile.oysyn.asia/health
```

Ожидаемый ответ:

```json
{ "status": "ok", "app": "scanai-backend" }
```
