# Codex handoff: ScanAI / Oysyn Mobile

Актуально на 2026-08-10. Этот файл — короткая точка входа; затем читать `TECHNICAL_DOCUMENTATION.md`, `API_DOCUMENTATION.md`, `OYSYN_MOBILE_BACKEND_CONFIG_REFERENCE.md` и `../ai_scan_text_back/docs/mobile_backend_db_schema.md`.

## Состояние проекта

Flutter app `ai_scan_text` работает только с FastAPI Mobile Backend `../ai_scan_text_back` по `https://api-mobile.oysyn.asia/api/v1`.

Oysyn Core — источник истины по пользователям, организациям, ролям, балансу проверок, документам и отчётам. Mobile Backend выпускает свой access JWT, хранит mobile-инфраструктуру в отдельной PostgreSQL БД и проксирует бизнес-операции в Core через service token.

Последний завершённый функциональный этап: QR-подтверждение веб-входа и просмотр/отзыв подключённых веб-устройств из профиля мобильного приложения.

## Что реализовано

- Login через Core, выпуск mobile access JWT и создание записи `mobile_sessions` с SHA-256 hash refresh-токена.
- Профиль, организация, проверки документов, отчёты и PDF через `/api/v1/*` proxy API.
- QR-flow: локальные QR-сессии (`create/status/approve/reject/consume`) с аудитом в PostgreSQL; неизвестный local token подтверждается в Oysyn Core через `/auth/qr-confirm`.
- Экран подключённых устройств: `GET /sessions/devices` получает сессии из Core и кэширует нормализованное представление в `linked_device_sessions`; `POST /sessions/devices/{id}/revoke` отзывает Core-сессию.
- Alembic migrations `001`–`007`, включая `linked_device_sessions` и поля user-agent.

## Что пока не реализовано или требует hardening

- Нет `/auth/refresh`, `/auth/logout` и управления mobile-сессиями: refresh-токен сохраняется, но не используется; access JWT нельзя отозвать до `exp`.
- Metadata из `LoginRequest` не записывается в `mobile_devices` / `push_tokens`.
- Нет 2FA, push-уведомлений, настроек и admin/delegation API.
- В Flutter есть demo-login `oysyn / qwerty`; токены хранятся в `SharedPreferences`; API URL жёстко задан без flavor/env.
- CORS открыт (`allow_origins=["*"]`), автотестов нет. Upload сейчас читает файл в память и вызывает синхронный `requests` из async endpoint.

## Важные ограничения

- Не возвращать legacy `/api/auth/*` и `/api/scan/*` в приложение.
- Не добавлять регистрацию пользователей или хранение Core-паролей в Mobile Backend.
- Не передавать в Flutter service token, DB password или JWT secret.
- Для production QR Core не поддерживает reject/status update: reject неизвестного local token возвращает локальный результат, Core-сессия истекает по своему TTL.

## Где смотреть код

- Flutter: `lib/services/auth_service.dart`, `lib/services/qr_login_service.dart`, `lib/services/linked_devices_service.dart`, `lib/storage/token_storage.dart`, `lib/features/main_shell/`.
- Backend: `routes/mobile_v1.py`, `services/oysyn_core_client.py`, `mobile_models.py`, `alembic/versions/`.

## Ближайший план

1. Реализовать refresh/logout/revoke mobile sessions с ротацией refresh-токена.
2. Добавить регистрацию и обновление mobile device/push metadata.
3. Провести production hardening: secure storage, убрать demo-login, сузить CORS, лимиты/rate-limit и потоковая передача upload.
4. Добавить тесты QR, сессий, прав доступа и Core API contract.
5. Добавить Flutter flavor/env для local и production API.

## Проверки

```bash
cd /Users/asyl/FLUTTER/scanAI/ai_scan_text && flutter analyze
cd /Users/asyl/FLUTTER/scanAI/ai_scan_text_back && PYTHONPYCACHEPREFIX=/private/tmp/scanai-pycache python3 -m compileall -q .
```

При изменении API обновлять `docs/API_DOCUMENTATION.md`; при миграциях — `../ai_scan_text_back/docs/mobile_backend_db_schema.md`; при env/deployment — `docs/OYSYN_MOBILE_BACKEND_CONFIG_REFERENCE.md`.
