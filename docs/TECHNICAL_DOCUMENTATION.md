# ScanAI / Oysyn Mobile: техническая документация

Актуально на 2026-08-10. Этот файл нужен следующему агенту Codex как карта проекта: что уже сделано, где лежит код, какие решения приняты и что нельзя ломать.

## Коротко о текущем состоянии

Проект состоит из Flutter-приложения `ai_scan_text` и FastAPI backend `../ai_scan_text_back`.

Главное архитектурное решение: мобильное приложение больше не работает со старыми локальными `/api/auth/*` и `/api/scan/*`. Клиент вызывает только production mobile API `/api/v1/*` на `https://api-mobile.oysyn.asia/api/v1`.

Mobile Backend выступает публичным адаптером для приложения и проксирует бизнес-данные в Oysyn Core Internal API. Источник истины по пользователям, организациям, ролям, балансу проверок, документам и отчетам - Oysyn Core, а не mobile DB.

## Репозитории и директории

| Компонент | Локальный путь | Назначение |
| --- | --- | --- |
| Flutter app | `/Users/asyl/FLUTTER/scanAI/ai_scan_text` | Мобильный клиент |
| Mobile Backend | `/Users/asyl/FLUTTER/scanAI/ai_scan_text_back` | FastAPI API для мобильного клиента |
| Workspace | `/Users/asyl/FLUTTER/scanAI/scanAI.code-workspace` | Общий workspace |
| Общая архитектура | `/Users/asyl/FLUTTER/scanAI/ARCHITECTURE.md` | Высокоуровневая карта |

GitHub:

| Компонент | Репозиторий | Ветка |
| --- | --- | --- |
| Frontend | `git@github.com:globalaeon24/aiscan_mobileapp_front.git` | `main` |
| Backend | `https://github.com/globalaeon24/aiscan_mobileapp_back.git` | `prod` |

## Production и тестовые адреса

| Назначение | Адрес |
| --- | --- |
| Mobile API base URL | `https://api-mobile.oysyn.asia/api/v1` |
| Swagger / OpenAPI | `https://api-mobile.oysyn.asia/api/docs` |
| Healthcheck | `https://api-mobile.oysyn.asia/health` |
| FastAPI локально | `http://127.0.0.1:8000` |

Oysyn Core Internal API задается через env:

```env
OYSYN_CORE_API_URL=<oysyn-core-internal-api-url>
OYSYN_CORE_SERVICE_TOKEN=<service-token>
OYSYN_CORE_API_TIMEOUT=30
```

Поддерживаются совместимые старые имена:

```env
OYSYN_INTERNAL_API_BASE_URL=<oysyn-core-internal-api-url>
MOBILE_BACKEND_SECRET=<service-token>
OYSYN_INTERNAL_API_TIMEOUT=30
```

## Архитектура запросов

```text
Flutter app
  |
  | HTTPS, Authorization: Bearer <mobile_access_token>
  v
Mobile Backend FastAPI
  | /api/v1/auth/login
  | /api/v1/auth/verify
  | /api/v1/me
  | /api/v1/organizations/{id}
  | /api/v1/checks
  | /api/v1/checks/{id}
  | /api/v1/checks/{id}/report
  | /api/v1/checks/{id}/report/pdf/{type}
  | /api/v1/qr-login/sessions/*
  | /api/v1/sessions/devices/*
  |
  | Authorization: Bearer <OYSYN_CORE_SERVICE_TOKEN>
  | X-Mobile-User-Id: <core user id>
  v
Oysyn Core Internal API
  |
  v
Oysyn Core DB
```

Mobile Backend создает собственный mobile JWT access token. В токене:

- `sub` - ID пользователя из Oysyn Core;
- `scope` - `mobile`;
- `jti` - случайный идентификатор;
- `exp` - срок действия из `ACCESS_TOKEN_EXPIRE_MINUTES`.

После успешного login backend создаёт `mobile_users` technical record и `mobile_sessions`: в БД записывается только SHA-256 hash случайного refresh token. Raw refresh token возвращается клиенту один раз. Endpoint'ов refresh/logout/revoke именно для mobile-сессий пока нет, поэтому этот token пока не используется, а access JWT нельзя отозвать до истечения `exp`.

## Flutter app

Ключевые файлы:

| Путь | Назначение |
| --- | --- |
| `lib/config/api_config.dart` | Production base URL: `https://api-mobile.oysyn.asia/api/v1` |
| `lib/services/api_service.dart` | Общая JSON HTTP-обертка, добавляет Bearer token, делает force logout на 401 |
| `lib/services/auth_service.dart` | Login через `/auth/login`, сохранение access/refresh token и user snapshot |
| `lib/services/scan_service.dart` | Upload документа, история, детали проверки |
| `lib/services/profile_service.dart` | Профиль и организация |
| `lib/services/qr_login_service.dart` | Разбор QR payload и approve/reject QR-входа |
| `lib/services/linked_devices_service.dart` | Список и отзыв подключённых веб-устройств |
| `lib/storage/token_storage.dart` | `SharedPreferences`: access token, refresh token, current user |
| `lib/models/scan_result.dart` | Адаптер ответа Core/mobile API в UI-модель |
| `lib/features/main_shell/*` | Новый shell/dashboard/documents/profile UI |

Важные текущие особенности клиента:

- Есть demo-login `oysyn / qwerty`, который сохраняет `demo_oysyn_token`. Он полезен только для UI-демо и не пройдет backend-auth.
- Регистрация в `AuthService.register` намеренно возвращает `false`: создание пользователей принадлежит Oysyn Core.
- `ScanService.uploadImageForOCR` и `ScanService.createScan(text)` намеренно бросают `UnsupportedError`. Старый OCR/text flow удален; проверка идет через загрузку документа в `/api/v1/checks`.
- Upload документа отправляет `multipart/form-data` с `title`, `document`, `include_ocr=true`, `ocr_languages=rus+kaz+eng`, `ai_check=true`.
- История поддерживает ответы вида `{results, count, page}` и запасные варианты `{items}` / `{data}`.
- В профиле есть переход на `linked_devices_page.dart`: данные берутся из `/sessions/devices`, отзыв — через `/sessions/devices/{id}/revoke`.

## Mobile Backend

Ключевые файлы:

| Путь | Назначение |
| --- | --- |
| `main.py` | FastAPI app, CORS, `/health`, подключение `/api/v1` |
| `routes/mobile_v1.py` | Единственный публичный API для мобильного клиента |
| `services/oysyn_core_client.py` | Service-to-service HTTP-клиент в Oysyn Core |
| `database.py` | SQLAlchemy engine/session, требует `DATABASE_URL` |
| `mobile_models.py` | SQLAlchemy-модели mobile DB |
| `alembic/versions/*.py` | Миграции 001-007 |
| `docs/mobile_backend_db_schema.md` | Подробная карта mobile DB |
| `.env.example` | Шаблон production env |

`main.py`:

- загружает `.env` через `python-dotenv`;
- открывает Swagger на `/api/docs`;
- открывает OpenAPI JSON на `/api/openapi.json`;
- отвечает `/health` как `{"status":"ok"}`;
- подключает `mobile_v1_router` с prefix `/api/v1`.

`services/oysyn_core_client.py`:

- читает `OYSYN_CORE_API_URL` или `OYSYN_INTERNAL_API_BASE_URL`;
- читает `OYSYN_CORE_SERVICE_TOKEN` или `MOBILE_BACKEND_SECRET`;
- добавляет `Authorization: Bearer <secret>`;
- добавляет `X-Mobile-User-Id` для приватных запросов;
- пробрасывает статус и ошибку Core API в FastAPI `HTTPException`;
- для PDF возвращает raw `requests.Response`.

## Mobile Backend DB

Mobile DB не дублирует Core. Большинство business endpoints остаются proxy к Core, но login уже пишет `mobile_users`/`mobile_sessions`, QR-flow пишет `qr_login_sessions`/`qr_login_events`, а список web-сессий кэшируется в `linked_device_sessions`.

Назначение mobile DB:

- устройства;
- мобильные сессии и hash refresh-токенов;
- push-токены;
- QR-login;
- 2FA;
- уведомления;
- мобильные статусы проверок;
- делегирование доступа;
- админские действия;
- аудит;
- security events;
- настройки;
- логи обращений к Core API;
- sync jobs.

Mobile DB не должна становиться копией Oysyn Core DB. В ней не должно быть source-of-truth таблиц users/organizations/roles/passwords.

Миграции:

| Revision | Блок |
| --- | --- |
| `001_mobile_core` | users/devices/sessions/push/notifications/audit |
| `002_mobile_security` | QR login, 2FA, security events |
| `003_mobile_checks` | mobile check requests/files/results/status events |
| `004_mobile_admin` | access delegation, admin actions |
| `005_mobile_settings_integrations` | settings, preferences, app versions, Core API logs, sync jobs |
| `006_linked_device_sessions` | кэш сессий устройств из Oysyn Core |
| `007_linked_ua_fields` | browser version, OS version, device type и user-agent для linked sessions |

Подробности: `../ai_scan_text_back/docs/mobile_backend_db_schema.md`.

## Переменные окружения backend

Минимальный production `.env`:

```env
ENVIRONMENT=production
DATABASE_URL=postgresql://aiscan_mobile_user:<REAL_PASSWORD>@127.0.0.1:5432/aiscan_mobile_db
REDIS_URL=redis://127.0.0.1:6379/0

SECRET_KEY=<jwt-secret-min-32-chars>
JWT_SECRET_KEY=<jwt-secret-min-32-chars>
ALGORITHM=HS256
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

OYSYN_CORE_API_URL=<oysyn-core-internal-api-url>
OYSYN_CORE_SERVICE_TOKEN=<oysyn-core-service-token>
OYSYN_CORE_API_TIMEOUT=30

MOBILE_BACKEND_SECRET=<same-or-legacy-service-token>
OYSYN_INTERNAL_API_BASE_URL=<same-or-legacy-core-url>
OYSYN_INTERNAL_API_TIMEOUT=30
```

Секреты не коммитить. Flutter-приложение не должно знать service token, DB password, Redis URL или JWT secret.

## Backend зависимости

Фактический `requirements.txt`:

```text
fastapi
uvicorn
sqlalchemy
psycopg2-binary
python-dotenv
python-jose[cryptography]
python-multipart
pydantic[email]
requests
alembic
```

Если добавляется Redis, фоновые задачи, SMS/push или файловое хранилище, зависимости надо добавлять осознанно и обновлять docs.

## Локальный запуск

Backend:

```bash
cd /Users/asyl/FLUTTER/scanAI/ai_scan_text_back
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --host 127.0.0.1 --port 8000
```

Проверка:

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/api/docs
```

Flutter:

```bash
cd /Users/asyl/FLUTTER/scanAI/ai_scan_text
flutter pub get
flutter run
```

Для локального backend нужно временно поменять `lib/config/api_config.dart` на `http://127.0.0.1:8000/api/v1` или сделать flavor/env-конфиг.

## Production infrastructure

Production summary:

```text
Internet
  -> api-mobile.oysyn.asia / 194.146.43.206
  -> pfSense
  -> External Nginx 192.168.75.100
  -> Internal mobile backend server 192.168.75.103
  -> Internal Nginx :80
  -> FastAPI 127.0.0.1:8000
```

Ограничения:

- pfSense не трогать без отдельной задачи;
- внешний Nginx `192.168.75.100` уже держит SSL;
- внутренний backend должен слушать `127.0.0.1:8000`, не `0.0.0.0`;
- внутренний Nginx на `192.168.75.103` проксирует `:80` на `127.0.0.1:8000`.

Подробности: `docs/OYSYN_MOBILE_BACKEND_CONFIG_REFERENCE.md`.

## Что уже сделано

- Flutter переведен на `https://api-mobile.oysyn.asia/api/v1`.
- Login клиента идет в `/auth/login`; сохраняются `access_token`, `refresh_token`, `user`.
- Старый register-flow отключен на клиенте.
- Старые OCR/text scan методы отключены через `UnsupportedError`.
- Документная проверка идет через `/checks` multipart upload.
- История и детали проверок читаются из `/checks` и `/checks/{id}`.
- Backend public API собран в `routes/mobile_v1.py`.
- Backend проксирует auth/profile/check/report/pdf/organization в Oysyn Core.
- JWT secret reading совместим с `JWT_SECRET_KEY` и `SECRET_KEY`.
- Oysyn Core config совместим с новыми и legacy env names.
- Добавлен `/health`.
- Добавлены SQLAlchemy mobile-модели и Alembic migrations 001-007.
- Login создаёт `mobile_sessions` и сохраняет только hash refresh-токена.
- Реализованы QR local sessions/events и подтверждение Core QR token.
- Реализованы список и отзыв подключённых устройств из профиля; добавлены migrations 006-007.
- Добавлен подробный документ схемы mobile DB.

## Известные незавершенные места

- Refresh token уже записывается как hash в `mobile_sessions`, но нет endpoint для refresh/logout/revoke; access JWT не проверяется по session status.
- `LoginRequest` принимает device metadata, но backend пока ее не сохраняет.
- `mobile_devices` и `push_tokens` пока не используются, а большая часть mobile DB остаётся подготовленной, но не подключённой к API.
- Нет 2FA endpoints, хотя таблицы для 2FA уже заложены.
- Нет push notification endpoints, хотя таблицы для push/notifications уже заложены.
- CORS сейчас открыт `allow_origins=["*"]`; перед production hardening сузить.
- Demo-login в Flutter может создать ложное ощущение авторизации, если тестировать реальные API.
- Для локального Flutter backend base URL пока hardcoded, нет flavor/env переключателя.
- Автоматических тестов для Flutter и backend нет. Upload документа читает файл целиком в память и использует blocking `requests` в async endpoint.

## Правила для следующего агента

- Не возвращать старые `/api/auth/*` и `/api/scan/*` во Flutter.
- Не добавлять регистрацию пользователей в Mobile Backend; это зона Oysyn Core.
- Не хранить пароли Core-пользователей в mobile DB.
- Не передавать `OYSYN_CORE_SERVICE_TOKEN` или `MOBILE_BACKEND_SECRET` в Flutter.
- Если меняются endpoint’ы, обновить `docs/API_DOCUMENTATION.md`.
- Если меняются таблицы/модели/миграции, обновить `../ai_scan_text_back/docs/mobile_backend_db_schema.md`.
- Если меняется deployment/env, обновить `docs/OYSYN_MOBILE_BACKEND_CONFIG_REFERENCE.md`.
