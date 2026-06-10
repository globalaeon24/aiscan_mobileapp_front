# Oysyn / AI Scan Mobile Backend: production config reference

Актуально на 2026-06-01. Этот документ фиксирует deployment-контекст backend `aiscan_mobileapp_back`.

Реальные пароли, JWT-секреты, service tokens и private URLs нельзя коммитить. В репозитории хранить только шаблоны.

## Репозиторий и сервер

| Параметр | Значение |
| --- | --- |
| Backend repository | `https://github.com/globalaeon24/aiscan_mobileapp_back.git` |
| Backend local path | `/Users/asyl/FLUTTER/scanAI/ai_scan_text_back` |
| Production server | `192.168.75.103` |
| Hostname | `oysyn-mobile-back` |
| Project path | `/opt/oysyn-mobile-backend` |
| Python venv | `/opt/oysyn-mobile-backend/venv` |
| Production domain | `https://api-mobile.oysyn.asia` |
| Production env file | `/opt/oysyn-mobile-backend/.env` |
| FastAPI entrypoint | `main:app` |
| FastAPI bind | `127.0.0.1:8000` |

## Network схема

```text
Internet
  |
  v
api-mobile.oysyn.asia / 194.146.43.206
  |
  v
pfSense
  |
  v
External Nginx 192.168.75.100
  |
  v
Internal mobile backend server 192.168.75.103
  |
  v
Nginx :80
  |
  v
FastAPI 127.0.0.1:8000
```

Ограничения:

- pfSense не менять в рамках обычных backend-задач.
- Внешний Nginx `192.168.75.100` уже держит SSL и проксирует `api-mobile.oysyn.asia` на `192.168.75.103:80`.
- На `192.168.75.103` Nginx должен проксировать `:80` на `127.0.0.1:8000`.
- FastAPI должен слушать localhost, не внешний интерфейс.

## Установленные компоненты на `192.168.75.103`

- Python 3.12
- venv / pip
- Git
- Nginx
- PostgreSQL
- Redis

## PostgreSQL

Mobile Backend использует отдельную PostgreSQL DB:

| Переменная | Значение |
| --- | --- |
| `DB_NAME` | `aiscan_mobile_db` |
| `DB_USER` | `aiscan_mobile_user` |
| `DB_HOST` | `127.0.0.1` |
| `DB_PORT` | `5432` |

`DATABASE_URL` должен быть только в `/opt/oysyn-mobile-backend/.env`:

```env
DATABASE_URL=postgresql://aiscan_mobile_user:<REAL_PASSWORD>@127.0.0.1:5432/aiscan_mobile_db
```

Mobile DB хранит только mobile infrastructure state. Она не является копией Core DB и не должна быть source of truth по пользователям, организациям, ролям или паролям.

Миграции Alembic уже есть:

```bash
cd /opt/oysyn-mobile-backend
source venv/bin/activate
alembic upgrade head
```

## Redis

Redis планируется для short-lived runtime state:

```env
REDIS_URL=redis://127.0.0.1:6379/0
```

Redis должен слушать только localhost:

```text
127.0.0.1:6379
[::1]:6379
```

На текущий момент публичный `/api/v1` proxy-flow Redis не использует, но env уже заложен под QR/2FA/rate-limit/push flows.

## Минимальный `.env`

Файл:

```text
/opt/oysyn-mobile-backend/.env
```

Шаблон:

```env
ENVIRONMENT=production
DATABASE_URL=postgresql://aiscan_mobile_user:<REAL_PASSWORD>@127.0.0.1:5432/aiscan_mobile_db
REDIS_URL=redis://127.0.0.1:6379/0

SECRET_KEY=<jwt-secret-min-32-chars>
JWT_SECRET_KEY=<same-or-new-jwt-secret-min-32-chars>
ALGORITHM=HS256
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

OYSYN_CORE_API_URL=<oysyn-core-internal-api-url>
OYSYN_CORE_SERVICE_TOKEN=<oysyn-core-service-token>
OYSYN_CORE_API_TIMEOUT=30

# Legacy-compatible aliases still supported by current code:
MOBILE_BACKEND_SECRET=<same-service-token-if-needed>
OYSYN_INTERNAL_API_BASE_URL=<same-core-url-if-needed>
OYSYN_INTERNAL_API_TIMEOUT=30
```

Текущий код читает:

- `JWT_SECRET_KEY` или `SECRET_KEY`;
- `JWT_ALGORITHM` или `ALGORITHM`;
- `OYSYN_CORE_API_URL` или `OYSYN_INTERNAL_API_BASE_URL`;
- `OYSYN_CORE_SERVICE_TOKEN` или `MOBILE_BACKEND_SECRET`;
- `OYSYN_CORE_API_TIMEOUT` или `OYSYN_INTERNAL_API_TIMEOUT`.

## Backend dependencies

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

Не добавлять старые parser/OCR зависимости (`pdfminer.six`, `docx2txt`, Tesseract wrappers) без новой задачи: текущий backend не парсит документы сам, а проксирует upload в Oysyn Core.

## Ручной запуск на сервере

```bash
cd /opt/oysyn-mobile-backend
source venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
uvicorn main:app --host 127.0.0.1 --port 8000
```

Проверки:

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/api/docs
```

Ожидаемый health:

```json
{"status":"ok"}
```

## systemd service

Файл:

```text
/etc/systemd/system/oysyn-mobile-backend.service
```

Рекомендуемый service:

```ini
[Unit]
Description=Oysyn Mobile Backend API
After=network.target

[Service]
User=oysyn
Group=oysyn
WorkingDirectory=/opt/oysyn-mobile-backend
EnvironmentFile=/opt/oysyn-mobile-backend/.env
ExecStart=/opt/oysyn-mobile-backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Команды:

```bash
sudo systemctl daemon-reload
sudo systemctl enable oysyn-mobile-backend
sudo systemctl restart oysyn-mobile-backend
sudo systemctl status oysyn-mobile-backend
```

## Internal Nginx на `192.168.75.103`

Файл:

```text
/etc/nginx/sites-available/api-mobile.oysyn.asia
```

Конфиг:

```nginx
server {
    listen 80;
    server_name api-mobile.oysyn.asia;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

Проверка:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Проверки после deploy

На сервере:

```bash
sudo systemctl status oysyn-mobile-backend
curl http://127.0.0.1:8000/health
curl http://192.168.75.103/health
```

Снаружи:

```bash
curl https://api-mobile.oysyn.asia/health
curl https://api-mobile.oysyn.asia/api/docs
```

Минимальная функциональная проверка:

```bash
curl -sS -X POST https://api-mobile.oysyn.asia/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"<REAL_USER_EMAIL>","password":"<REAL_PASSWORD>"}'
```

Не вставлять реальные credentials в docs, shell history shared logs или git.

## Частые ошибки

### `RuntimeError: DATABASE_URL is not set`

Причина: `DATABASE_URL` не загружен.

Проверить:

- существует `/opt/oysyn-mobile-backend/.env`;
- systemd service использует `EnvironmentFile`;
- в `.env` нет кавычек/невидимых символов;
- процесс перезапущен после изменения env.

### `SECRET_KEY is not set or too short`

Текущий backend требует secret минимум 32 символа. Можно задать оба имени:

```env
JWT_SECRET_KEY=<REAL_LONG_RANDOM_SECRET>
SECRET_KEY=<REAL_LONG_RANDOM_SECRET>
```

### `Oysyn Core API env variables are missing`

Не настроены Core URL/token.

Проверить:

```env
OYSYN_CORE_API_URL=<oysyn-core-internal-api-url>
OYSYN_CORE_SERVICE_TOKEN=<service-token>
```

или legacy aliases:

```env
OYSYN_INTERNAL_API_BASE_URL=<oysyn-core-internal-api-url>
MOBILE_BACKEND_SECRET=<service-token>
```

### `Form data requires "python-multipart" to be installed`

Установить и зафиксировать зависимость:

```bash
pip install python-multipart
```

Сейчас `python-multipart` уже есть в `requirements.txt`.

### `No module named 'jose'`

Установить:

```bash
pip install 'python-jose[cryptography]'
```

Сейчас зависимость уже есть в `requirements.txt`.

### Core API возвращает 401/403

Проверить service token и заголовки:

```http
Authorization: Bearer <OYSYN_CORE_SERVICE_TOKEN>
X-Mobile-User-Id: <core-user-id>
```

Для login `X-Mobile-User-Id` не нужен.

## Deploy checklist

1. Pull backend repo on `192.168.75.103`.
2. Activate venv.
3. `pip install -r requirements.txt`.
4. Проверить `/opt/oysyn-mobile-backend/.env`.
5. `alembic upgrade head`.
6. `sudo systemctl restart oysyn-mobile-backend`.
7. `sudo systemctl status oysyn-mobile-backend`.
8. Проверить local health.
9. Проверить Nginx health.
10. Проверить external health.
11. Проверить `/api/docs`.
12. Проверить login реальным Core-пользователем.

## Что не делать без отдельного решения

- Не менять pfSense.
- Не менять внешний Nginx `192.168.75.100`, если HTTPS уже работает.
- Не открывать FastAPI на `0.0.0.0`.
- Не хранить Core users/passwords/roles как source of truth в mobile DB.
- Не коммитить `.env`.
- Не вшивать service token во Flutter.
