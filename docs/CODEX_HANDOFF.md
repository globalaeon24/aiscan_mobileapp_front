# Codex handoff: ScanAI / Oysyn Mobile

Актуально на 2026-06-01. Прочитай этот файл первым, затем `TECHNICAL_DOCUMENTATION.md`, `API_DOCUMENTATION.md`, `OYSYN_MOBILE_BACKEND_CONFIG_REFERENCE.md` и `../ai_scan_text_back/docs/mobile_backend_db_schema.md`.

## Суть проекта

Flutter app `ai_scan_text` работает с FastAPI backend `../ai_scan_text_back`. Публичный API для приложения только один: `https://api-mobile.oysyn.asia/api/v1`.

Mobile Backend не является владельцем пользователей, организаций, ролей, баланса проверок и отчетов. Он выпускает mobile JWT и проксирует запросы в Oysyn Core Internal API через service token.

## Что важно не перепутать

- Старые `/api/auth/*` и `/api/scan/*` удалены из целевой архитектуры приложения.
- Регистрация пользователей в мобильном backend не реализуется: пользователи создаются в Oysyn Core.
- Проверка текста через paste и отдельный OCR image endpoint отключены на Flutter-стороне.
- Единственный production upload flow: `POST /api/v1/checks` multipart document upload.
- Mobile DB уже спроектирована, но текущие `/api/v1` endpoints почти не пишут в нее.
- Refresh token сейчас возвращается клиенту, но полноценного refresh/logout/session revoke flow еще нет.

## Где смотреть код

Frontend:

- `lib/config/api_config.dart` - production base URL.
- `lib/services/auth_service.dart` - login, сохранение token/user.
- `lib/services/scan_service.dart` - upload/history/details.
- `lib/storage/token_storage.dart` - SharedPreferences keys.
- `lib/features/main_shell/*` - основной UI.

Backend:

- `main.py` - app, CORS, health, router.
- `routes/mobile_v1.py` - public mobile API.
- `services/oysyn_core_client.py` - Core API adapter.
- `database.py` - DB engine, hard-fails without `DATABASE_URL`.
- `mobile_models.py` - local mobile infrastructure models.
- `alembic/versions/*.py` - migrations.
- `docs/mobile_backend_db_schema.md` - DB schema contract.

## Текущий API

Mobile endpoints:

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/verify`
- `GET /api/v1/me`
- `GET /api/v1/organizations/{organization_id}`
- `GET /api/v1/checks`
- `POST /api/v1/checks`
- `GET /api/v1/checks/{check_id}`
- `GET /api/v1/checks/{check_id}/report`
- `GET /api/v1/checks/{check_id}/report/pdf/{report_type}`

Allowed PDF report types:

- `full_report`
- `short_report`
- `certificate`
- `ai_certificate`

## Следующие логичные задачи

1. Реализовать refresh/logout/revoke sessions с записью `mobile_sessions`.
2. Использовать device metadata из `LoginRequest`: `mobile_devices`, `push_tokens`, `last_seen_at`.
3. Добавить QR login endpoints поверх `qr_login_sessions` и `qr_login_events`.
4. Добавить 2FA endpoints и Redis-backed code storage.
5. Добавить push notification registration/list/read.
6. Сделать Flutter flavor/env переключение production/local base URL.
7. Убрать или спрятать demo-login, если начинается production QA.
8. Сузить CORS перед финальным hardening.

## Проверки перед сдачей изменений

Backend:

```bash
cd /Users/asyl/FLUTTER/scanAI/ai_scan_text_back
python -m compileall .
```

Flutter:

```bash
cd /Users/asyl/FLUTTER/scanAI/ai_scan_text
flutter analyze
```

Если меняешь API contract, обнови `docs/API_DOCUMENTATION.md`. Если меняешь DB schema, обнови `../ai_scan_text_back/docs/mobile_backend_db_schema.md`. Если меняешь deployment/env, обнови `docs/OYSYN_MOBILE_BACKEND_CONFIG_REFERENCE.md`.
