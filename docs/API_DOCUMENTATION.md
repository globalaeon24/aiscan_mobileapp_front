# ScanAI / Oysyn Mobile: API документация

## 1. Mobile Backend API для мобильного приложения

**Base URL:** `https://api-mobile.oysyn.asia/api/v1`

Для локального запуска:

**Local Base URL:** `http://127.0.0.1:8000/api/v1`

### Авторизация Mobile Backend

Мобильное приложение вызывает только Mobile Backend. После логина backend возвращает mobile JWT access token. Все приватные запросы должны содержать:

```http
Authorization: Bearer <access_token>
```

### POST `/auth/login`

Логин пользователя через Oysyn Core API. Backend ожидает JSON.

**Headers**

```http
Content-Type: application/json
```

**Request body**

```json
{
  "email": "user@oysyn.kz",
  "password": "secret123"
}
```

**Response 200**

```json
{
  "access_token": "<jwt>",
  "token_type": "bearer",
  "user": {
    "id": 42,
    "email": "user@oysyn.kz",
    "first_name": "Айгерим",
    "last_name": "Сейткали",
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

**Response 401**

```json
{
  "detail": "Неверный email или пароль"
}
```

### GET `/auth/verify`

Проверяет mobile JWT и актуальность пользователя в Oysyn Core API.

**Headers**

```http
Authorization: Bearer <access_token>
```

**Response 200**

```json
{
  "valid": true,
  "user": { "...user object..." }
}
```

### GET `/me`

Возвращает текущего пользователя.

**Headers**

```http
Authorization: Bearer <access_token>
```

**Response 200**

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

### GET `/checks`

История проверок пользователя с пагинацией.

**Query params**

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `status` | string | - | `UP`, `PR`, `CH`, `FA` |
| `page` | int | `1` | Номер страницы |
| `page_size` | int | `20` | Размер страницы, максимум 100 |

**Headers**

```http
Authorization: Bearer <access_token>
```

**Response 200**

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

### POST `/checks`

Загрузка документа на проверку.

**Headers**

```http
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Form-data**

| Поле | Тип | Обязательно | Описание |
| --- | --- | --- | --- |
| `title` | string | да | Название документа |
| `document` | file | да | PDF, DOCX, DOC, TXT, ODT, PPTX, RTF |
| `author` | string | нет | Автор |
| `department` | string | нет | Кафедра / подразделение |
| `document_type` | string | нет | Тип документа |
| `include_ocr` | bool | нет | OCR для PDF, default `false` |
| `ocr_languages` | string | нет | Например `rus+kaz`, default `rus` |
| `ai_check` | bool | нет | Проверка на ИИ, default `true` |

**Response 201**

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

### GET `/checks/{id}`

Детальная информация по одной проверке.

### GET `/checks/{id}/report`

Числовые результаты проверки.

### GET `/checks/{id}/report/pdf/{report_type}`

PDF-отчет. Поддерживаемые `report_type`:

| report_type | Назначение |
| --- | --- |
| `full_report` | Полный отчет |
| `short_report` | Краткий отчет |
| `certificate` | Сертификат оригинальности |
| `ai_certificate` | Сертификат проверки на ИИ |

**Query params**

| Параметр | Значения | По умолчанию | Описание |
| --- | --- | --- | --- |
| `lang` | `kk`, `ru`, `en` | `ru` | Язык PDF |
| `download` | `1` | - | Если передан, файл скачивается |

## 1.1 Legacy Mobile Backend API

Старые локальные роуты `/api/auth/*` и `/api/scan/*` удалены. Мобильное приложение должно использовать только `/api/v1/*`.

## 2. Oysyn Internal API

**Base URL:** `http://192.168.142.220/api/internal/v1`

Это API используется backend-сервисом для интеграции с тестовой Oysyn DB. Flutter-клиент не должен обращаться к этому API напрямую.

### Service-to-service авторизация

Все запросы от Mobile Backend должны содержать:

```http
Authorization: Bearer <MOBILE_BACKEND_SECRET>
X-Mobile-User-Id: <user_id>
```

Исключение: `POST /auth/login`, для него `X-Mobile-User-Id` не нужен.

### POST `/auth/login`

Проверяет credentials пользователя в Oysyn.

**Headers**

```http
Authorization: Bearer <MOBILE_BACKEND_SECRET>
Content-Type: application/json
```

**Request body**

```json
{
  "email": "user@oysyn.kz",
  "password": "secret123"
}
```

**Response 200**

```json
{
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

**Response 401**

```json
{ "error": "Неверный email или пароль" }
```

### GET `/auth/verify`

Проверяет пользователя и возвращает профиль.

**Headers**

```http
Authorization: Bearer <MOBILE_BACKEND_SECRET>
X-Mobile-User-Id: 42
```

**Response 200**

```json
{
  "valid": true,
  "user": { "...user object..." }
}
```

### GET `/users/me`

Возвращает профиль текущего пользователя.

**Headers**

```http
Authorization: Bearer <MOBILE_BACKEND_SECRET>
X-Mobile-User-Id: 42
```

**Response 200**

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

### GET `/checks`

История проверок пользователя с пагинацией.

**Query params**

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `status` | string | - | `UP`, `PR`, `CH`, `FA` |
| `page` | int | `1` | Номер страницы |
| `page_size` | int | `20` | Размер страницы, максимум 100 |

**Response 200**

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

### POST `/checks`

Загрузка документа на проверку. Списывает одну проверку с баланса пользователя.

**Headers**

```http
Authorization: Bearer <MOBILE_BACKEND_SECRET>
X-Mobile-User-Id: 42
Content-Type: multipart/form-data
```

**Form-data**

| Поле | Тип | Обязательно | Описание |
| --- | --- | --- | --- |
| `title` | string | да | Название документа |
| `document` | file | да | PDF, DOCX, DOC, TXT, ODT, PPTX, RTF |
| `author` | string | нет | Автор |
| `department` | string | нет | Кафедра / подразделение |
| `document_type` | string | нет | Тип документа |
| `include_ocr` | bool | нет | OCR для PDF, default `false` |
| `ocr_languages` | string | нет | Например `rus+kaz`, default `rus` |
| `ai_check` | bool | нет | Проверка на ИИ, default `true` |

**Response 201**

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

**Response 402**

```json
{ "error": "Нет доступных проверок" }
```

### GET `/checks/{id}`

Детальная информация по одной проверке.

**Response 200**

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

### GET `/checks/{id}/report`

Числовые результаты проверки.

**Response 200**

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

**Response 404**

```json
{ "error": "Отчёт ещё не готов" }
```

### PDF отчеты

| Endpoint | Назначение |
| --- | --- |
| `GET /checks/{id}/report/pdf/full_report/` | Полный отчет PDF |
| `GET /checks/{id}/report/pdf/short_report/` | Краткий отчет PDF |
| `GET /checks/{id}/report/pdf/certificate/` | Сертификат оригинальности PDF |
| `GET /checks/{id}/report/pdf/ai_certificate/` | Сертификат проверки на ИИ PDF |

**Query params**

| Параметр | Значения | По умолчанию | Описание |
| --- | --- | --- | --- |
| `lang` | `kk`, `ru`, `en` | `ru` | Язык PDF |
| `download` | `1` | - | Если передан, файл скачивается |

**Response 200**

PDF файл с `Content-Type: application/pdf`.

**Response 503**

```text
Отчёт ещё формируется, попробуйте позже.
```

### GET `/organizations/{id}`

Информация об организации.

**Response 200**

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

**Response 403**

```json
{ "error": "Доступ запрещён" }
```

## 3. Справочники Oysyn Internal API

### Роли

| Код | Роль |
| --- | --- |
| `EXP` | Expert |
| `MOD` | Moderator |
| `SUP` | Supervisor |
| `ADM` | Administrator |

### Статусы документа

| Код | Значение |
| --- | --- |
| `UP` | Загружен |
| `PR` | Проверяется |
| `CH` | Проверен |
| `FA` | Ошибка |

### Типы документов

| Значение | Описание |
| --- | --- |
| `ARTICLE` | Статья |
| `COURSE WORK` | Курсовая работа |
| `DOCTORAL` | Докторская диссертация |
| `DIPLOMA THESIS` | Дипломная работа |
| `DIPLOMA PROJECT` | Дипломный проект |
| `MASTERS` | Магистерская диссертация |
| `STUDYGUIDE` | Учебное пособие |
| `TEXTBOOK` | Учебник |
| `BOOK` | Книга |
| `RESEARCH` | Исследование |
| `MONOGRAPH` | Монография |
| `ABSTRACT` | Реферат |
| `PROJECT` | Проект |
| `ESSAY` | Эссе |
| `SCIENTIFIC WORK` | Научная работа |
| `OTHER` | Другое |

## 4. Общие коды ответов Oysyn Internal API

| Код | Значение |
| --- | --- |
| `200` | Успех |
| `201` | Создано |
| `400` | Неверные параметры запроса |
| `401` | Неверный service token или credentials |
| `402` | Нет доступных проверок |
| `403` | Доступ запрещен |
| `404` | Объект не найден |
| `503` | Файл еще генерируется, повторить позже |
