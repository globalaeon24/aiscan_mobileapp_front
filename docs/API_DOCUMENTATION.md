# ScanAI / Oysyn Mobile: API документация

Актуально на 2026-08-10. Мобильное приложение должно вызывать только Mobile Backend API `/api/v1/*`.

## Base URL

Production:

```text
https://api-mobile.oysyn.asia/api/v1
```

Local:

```text
http://127.0.0.1:8000/api/v1
```

Swagger:

```text
https://api-mobile.oysyn.asia/api/docs
```

Healthcheck:

```http
GET /health
```

Response:

```json
{"status":"ok"}
```

## Авторизация

После логина Mobile Backend возвращает mobile JWT `access_token` и случайный `refresh_token`.

Все приватные запросы:

```http
Authorization: Bearer <access_token>
```

При login backend создаёт запись `mobile_sessions` и хранит только SHA-256 hash refresh token. Клиент сохраняет raw token, но `/auth/refresh`, `/auth/logout` и mobile session revoke пока не реализованы: refresh token пока не используется, а access JWT действителен до `exp`.

## Mobile Backend Public API

### POST `/auth/login`

Логин пользователя через Oysyn Core API. Backend проверяет credentials в Core, затем выпускает mobile JWT.

Request:

```http
Content-Type: application/json
```

```json
{
  "email": "user@oysyn.kz",
  "password": "secret123",
  "device_id": "optional-device-id",
  "platform": "ios",
  "device_name": "iPhone",
  "device_model": "iPhone 15",
  "os_version": "17.5",
  "app_version": "1.0.0",
  "push_token": "optional-push-token",
  "push_provider": "apns"
}
```

Минимально обязательны только `email` и `password`. Backend создаёт technical `mobile_users` record и `mobile_sessions`; device/push поля уже есть в схеме запроса, но пока не синхронизируются в `mobile_devices` и `push_tokens`.

Response 200:

```json
{
  "access_token": "<mobile-jwt>",
  "refresh_token": "<random-refresh-token>",
  "token_type": "bearer",
  "user": {
    "id": 42,
    "email": "user@oysyn.kz",
    "first_name": "Айгерим",
    "last_name": "Сейткали",
    "middle_name": "Маратовна",
    "full_name": "Сейткали Айгерим Маратовна",
    "role": "EXP",
    "checks_available": 10,
    "organization_id": 5,
    "organization_name": "КазНУ",
    "phone_number": "+77001234567",
    "city": "ALA"
  }
}
```

Ошибки:

- `401` - Core API отклонил логин;
- `502` - Core API вернул успешный login без `user.id`;
- `503` - Core API недоступен;
- `500` - не настроен JWT secret или Core env.

### GET `/auth/verify`

Проверяет mobile JWT и актуальность пользователя через Oysyn Core.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "valid": true,
  "user": {
    "id": 42,
    "email": "user@oysyn.kz"
  }
}
```

Фактическая форма `user` зависит от Oysyn Core.

### GET `/sessions/devices`

Возвращает подключённые веб-устройства текущего пользователя. Backend получает исходные сессии из Oysyn Core, нормализует их и кэширует snapshot в `linked_device_sessions`.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "items": [
    {
      "id": 123,
      "core_session_id": "123",
      "device_name": "Chrome",
      "browser": "Chrome",
      "browser_version": "126.0",
      "platform": "macOS",
      "os_version": "14.5",
      "device_type": "desktop",
      "location": null,
      "ip_address": "203.0.113.10",
      "status": "active",
      "first_seen_at": "2026-06-11T10:00:00Z",
      "last_active_at": "2026-06-11T11:00:00Z",
      "revoked_at": null
    }
  ]
}
```

Форма исходного ответа Core может отличаться; backend поддерживает list и wrappers `items`, `results`, `data`, `sessions`, `devices`.

### POST `/sessions/devices/{session_id}/revoke`

Отзывает веб-сессию в Oysyn Core и обновляет локальный cache, если запись уже была получена.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "status": "revoked",
  "session_id": 123,
  "core": {}
}
```

### QR-login endpoints

QR-авторизация веб-сессии через мобильное приложение. Для production Oysyn Core flow сайт генерирует QR и кладет в него `token` UUID. Мобильное приложение сканирует token и вызывает Mobile Backend approve endpoint, а Mobile Backend подтверждает вход в Oysyn Core через internal `POST /auth/qr-confirm`.

Поддерживаемые payload в QR:

```json
{
  "token": "22ea4fa6-461e-4810-a218-f52949c4bb80"
}
```

Также поддерживаются plain token и URL с `token`, `qr_token` или `qrToken`.

Local QR-session endpoints ниже остаются совместимыми для собственного mobile backend flow. В local flow raw `qr_token` возвращается только при создании сессии и не хранится в БД, backend сохраняет только SHA-256 hash.

#### POST `/qr-login/sessions`

Публичный endpoint для веба. Создает короткоживущую QR-сессию.

Request:

```json
{
  "web_session_id": "optional-web-session-id"
}
```

Response 200:

```json
{
  "qr_token": "<raw-token-for-qr>",
  "status": "pending",
  "expires_at": "2026-06-10T12:00:00Z"
}
```

#### GET `/qr-login/sessions/{qr_token}/status`

Публичный endpoint для веба. Возвращает текущий статус QR-сессии.

Response 200:

```json
{
  "status": "pending",
  "expires_at": "2026-06-10T12:00:00Z",
  "approved_at": null,
  "rejected_at": null,
  "consumed_at": null
}
```

Статусы: `pending`, `approved`, `rejected`, `expired`, `consumed`.

#### POST `/qr-login/sessions/{qr_token}/approve`

Приватный endpoint мобильного приложения. Подтверждает вход в веб по отсканированному QR.

Если `qr_token` не найден в local `qr_login_sessions`, Mobile Backend считает его Oysyn Core token и вызывает Core `POST /auth/qr-confirm` с `X-Mobile-User-Id`.

Headers:

```http
Authorization: Bearer <access_token>
```

Request:

```json
{
  "device_id": "optional-device-id"
}
```

Response 200:

```json
{
  "status": "confirmed"
}
```

#### POST `/qr-login/sessions/{qr_token}/reject`

Приватный endpoint мобильного приложения. Отклоняет вход в веб.

Oysyn Core API на текущий момент не имеет endpoint для reject/status update. Поэтому для Core QR token reject не отправляется в Core; mobile backend возвращает `rejected`, а веб-сессия Core истекает по TTL.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "status": "rejected"
}
```

#### POST `/qr-login/sessions/{qr_token}/consume`

Публичный endpoint для веба. Одноразово переводит подтвержденную QR-сессию в `consumed`.

Response 200:

```json
{
  "status": "consumed",
  "expires_at": "2026-06-10T12:00:00Z",
  "approved_at": "2026-06-10T11:59:10Z",
  "rejected_at": null,
  "consumed_at": "2026-06-10T11:59:12Z"
}
```

Ошибки:

- `404` - QR-сессия не найдена;
- `409` - QR-сессия уже в другом статусе;
- `410` - QR-сессия истекла;
- `401` - mobile approve/reject вызван без валидного mobile JWT.

### GET `/me`

Возвращает профиль текущего пользователя из Oysyn Core.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "id": 42,
  "email": "user@oysyn.kz",
  "first_name": "Айгерим",
  "last_name": "Сейткали",
  "middle_name": "Маратовна",
  "full_name": "Сейткали Айгерим Маратовна",
  "role": "EXP",
  "checks_available": 10,
  "organization_id": 5,
  "organization_name": "КазНУ",
  "phone_number": "+77001234567",
  "city": "ALA"
}
```

### GET `/organizations/{organization_id}`

Возвращает организацию из Oysyn Core.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "id": 5,
  "title": "Казахский национальный университет",
  "city": "ALA",
  "city_display": "Алматы",
  "address": "пр. аль-Фараби, 71",
  "description": "...",
  "checks_available": 500
}
```

### GET `/checks`

История проверок пользователя.

Headers:

```http
Authorization: Bearer <access_token>
```

Query params:

| Параметр | Тип | Default | Описание |
| --- | --- | --- | --- |
| `status` | string | - | Фильтр статуса, например `UP`, `PR`, `CH`, `FA` |
| `page` | int | `1` | Номер страницы |
| `page_size` | int | `20` | Размер страницы, максимум `100` |

Response 200:

```json
{
  "count": 47,
  "pages": 3,
  "page": 1,
  "results": [
    {
      "id": 101,
      "title": "Дипломная работа",
      "author": "Айгерим Сейткали",
      "document_type": "DIPLOMA THESIS",
      "status": "CH",
      "status_display": "Проверен",
      "created_at": "2026-05-20T10:30:00Z",
      "originality_percentage": 87.5
    }
  ]
}
```

Flutter `ScanService.getHistoryPage` также умеет читать `items` или `data`, если Core API вернет другой wrapper.

### POST `/checks`

Создает проверку документа. Запрос проксируется в Oysyn Core как multipart upload.

Headers:

```http
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

Form-data:

| Поле | Тип | Обязательно | Default | Описание |
| --- | --- | --- | --- | --- |
| `title` | string | да | - | Название документа |
| `document` | file | да | - | PDF/DOCX/DOC/TXT/ODT/PPTX/RTF, если Core поддерживает |
| `author` | string | нет | - | Автор |
| `department` | string | нет | - | Кафедра/подразделение |
| `document_type` | string | нет | - | Тип документа |
| `include_ocr` | bool | нет | `false` | OCR для PDF/сканов |
| `ocr_languages` | string | нет | `rus` | Например `rus+kaz+eng` |
| `ai_check` | bool | нет | `true` | Проверка на AI-generated content |

Response 201:

```json
{
  "id": 102,
  "title": "Дипломная работа",
  "author": "Айгерим Сейткали",
  "department": "Информационные технологии",
  "document_type": "DIPLOMA THESIS",
  "document_type_display": "Diploma thesis",
  "status": "PR",
  "status_display": "Проверяется",
  "created_at": "2026-05-23T10:00:00Z",
  "estimated_completion": null,
  "modules": [],
  "originality_percentage": null
}
```

Типовые ошибки:

- `402` - нет доступных проверок, если так отвечает Core;
- `413` - файл слишком большой, если ограничен Nginx/Core;
- `415` - неподдерживаемый формат, если так отвечает Core.

### GET `/checks/{check_id}`

Детальная информация по проверке.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "id": 101,
  "title": "Дипломная работа",
  "author": "Айгерим Сейткали",
  "department": "Информационные технологии",
  "document_type": "DIPLOMA THESIS",
  "document_type_display": "Diploma thesis",
  "status": "CH",
  "status_display": "Проверен",
  "created_at": "2026-05-20T10:30:00Z",
  "estimated_completion": null,
  "modules": ["internet", "antiplagiat"],
  "originality_percentage": 87.5
}
```

### GET `/checks/{check_id}/report`

Числовые результаты проверки.

Headers:

```http
Authorization: Bearer <access_token>
```

Response 200:

```json
{
  "id": 55,
  "originality_percentage": 87.5,
  "plagiarism_percentage": 8.3,
  "citation_percentage": 4.2,
  "selfcitation_percentage": 0.0,
  "internet_originality_percentage": 91.0,
  "internet_plagiarism_percentage": 9.0,
  "human_written_percentage": 94.5,
  "chatgpt_generated_percentage": 5.5,
  "uniqueness": 87,
  "created_at": "2026-05-20T10:30:00Z",
  "finished_at": "2026-05-20T10:35:22Z"
}
```

Response 404:

```json
{"detail":"Отчёт ещё не готов"}
```

### GET `/checks/{check_id}/report/pdf/{report_type}`

Возвращает PDF-отчет, проксируя бинарный ответ Core API.

Allowed `report_type`:

| Значение | Назначение |
| --- | --- |
| `full_report` | Полный отчет |
| `short_report` | Краткий отчет |
| `certificate` | Сертификат оригинальности |
| `ai_certificate` | Сертификат проверки на ИИ |

Query params:

| Параметр | Значения | Default | Описание |
| --- | --- | --- | --- |
| `lang` | `kk`, `ru`, `en` | `ru` | Язык PDF |
| `download` | int | - | Если передан, Core может вернуть attachment |

Response 200:

```http
Content-Type: application/pdf
Content-Disposition: <copied-from-core-if-present>
```

Если `report_type` не входит в allowlist, Mobile Backend возвращает:

```json
{"detail":"Тип отчета не найден"}
```

## Oysyn Core Internal API contract

Flutter не должен ходить сюда напрямую. Это contract между Mobile Backend и Oysyn Core.

Mobile Backend использует base URL из:

```env
OYSYN_CORE_API_URL
```

или legacy:

```env
OYSYN_INTERNAL_API_BASE_URL
```

Service-to-service headers:

```http
Authorization: Bearer <OYSYN_CORE_SERVICE_TOKEN>
X-Mobile-User-Id: <core-user-id>
```

Для `POST /auth/login` `X-Mobile-User-Id` не передается, потому что пользователь еще не известен.

Фактические Core endpoints, которые вызывает `services/oysyn_core_client.py`:

| Method | Core path | Когда вызывается |
| --- | --- | --- |
| `POST` | `/auth/login` | `POST /api/v1/auth/login` |
| `GET` | `/auth/verify` | `GET /api/v1/auth/verify` |
| `POST` | `/auth/qr-confirm` | approve неизвестного local QR token |
| `GET` | `/users/me` | `GET /api/v1/me` |
| `GET` | `/sessions/devices` | `GET /api/v1/sessions/devices` |
| `POST` | `/sessions/devices/{id}/revoke` | `POST /api/v1/sessions/devices/{id}/revoke` |
| `GET` | `/organizations/{id}` | `GET /api/v1/organizations/{id}` |
| `GET` | `/checks` | `GET /api/v1/checks` |
| `POST` | `/checks` | `POST /api/v1/checks` |
| `GET` | `/checks/{id}` | `GET /api/v1/checks/{id}` |
| `GET` | `/checks/{id}/report` | `GET /api/v1/checks/{id}/report` |
| `GET` | `/checks/{id}/report/pdf/{type}/` | `GET /api/v1/checks/{id}/report/pdf/{type}` |

## Удаленные или отключенные legacy flows

Эти routes не должны использоваться мобильным приложением:

- `/api/auth/register`
- `/api/auth/login`
- `/api/auth/me`
- `/api/scan/*`
- OCR image upload как отдельный endpoint;
- проверка вставленного текста как отдельный endpoint.

Текущий путь проверки: только документ через `POST /api/v1/checks`.

## Planned API, еще не реализовано

Следующие зоны заложены в DB-модели, но публичных endpoints пока нет:

- refresh/logout/revoke sessions;
- device registration/update;
- push token registration;
- 2FA challenge/verify;
- notifications list/read;
- app settings/preferences;
- admin/delegation actions.

Перед добавлением этих endpoint’ов свериться с `../ai_scan_text_back/docs/mobile_backend_db_schema.md` и обновить этот файл.
