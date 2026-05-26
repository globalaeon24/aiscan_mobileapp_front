# Oysyn / AI Scan Mobile Backend: справочник конфигурации

Этот файл фиксирует технические реквизиты production-развертывания backend для мобильного приложения Oysyn / AI Scan.

Реальные пароли, JWT-секреты, токены и другие секреты нельзя коммитить в GitHub. Они должны храниться только в `.env` на сервере.

## Репозиторий

| Параметр | Значение |
| --- | --- |
| Git repository | `https://github.com/globalaeon24/aiscan_mobileapp_back.git` |
| Сервер проекта | `192.168.75.103` |
| Hostname | `oysyn-mobile-back` |
| Путь проекта | `/opt/oysyn-mobile-backend` |
| Python venv | `/opt/oysyn-mobile-backend/venv` |
| Production domain | `https://api-mobile.oysyn.asia` |
| Файл окружения | `/opt/oysyn-mobile-backend/.env` |

## Сетевая схема

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

Важные ограничения:

- pfSense не трогать.
- Внешний Nginx `192.168.75.100` уже настроен и проксирует `api-mobile.oysyn.asia` на `192.168.75.103:80`.
- SSL выпущен на внешнем Nginx `192.168.75.100`.
- На внутреннем сервере `192.168.75.103` Nginx должен проксировать `:80` на `127.0.0.1:8000`.
- FastAPI backend должен слушать только `127.0.0.1:8000`, не `0.0.0.0`.

## Установлено на сервере `192.168.75.103`

- Python 3.12
- venv
- pip
- Git
- Nginx
- PostgreSQL
- Redis

## PostgreSQL

Для mobile backend используется отдельная база данных.

Mobile Backend DB не должна становиться копией основной БД Oysyn. Пользователи, организации, роли и права являются источником истины в Oysyn Core.

В mobile DB хранятся только локальные мобильные сущности:

- устройства;
- сессии;
- push-токены;
- QR-login;
- 2FA;
- мобильные уведомления;
- статусы мобильных проверок;
- делегированные действия;
- админские действия;
- аудит.

Если в legacy backend-коде есть таблицы или модели `users`, `organizations`, роли или права, их нельзя считать production source of truth. Для production mobile API эти данные должны запрашиваться из Oysyn Core через internal/service-to-service API, а mobile DB должна хранить только мобильный контекст и техническое состояние.

| Переменная | Значение |
| --- | --- |
| `DB_NAME` | `aiscan_mobile_db` |
| `DB_USER` | `aiscan_mobile_user` |
| `DB_HOST` | `127.0.0.1` |
| `DB_PORT` | `5432` |

Production `DATABASE_URL` должен лежать только в `/opt/oysyn-mobile-backend/.env`:

```env
DATABASE_URL=postgresql://aiscan_mobile_user:<REAL_PASSWORD>@127.0.0.1:5432/aiscan_mobile_db
```

## Redis

```env
REDIS_URL=redis://127.0.0.1:6379/0
```

Redis должен слушать только localhost:

```text
127.0.0.1:6379
[::1]:6379
```

## Минимальный `.env`

Файл:

```text
/opt/oysyn-mobile-backend/.env
```

Шаблон без реальных секретов:

```env
ENVIRONMENT=production
DATABASE_URL=postgresql://aiscan_mobile_user:<REAL_PASSWORD>@127.0.0.1:5432/aiscan_mobile_db
REDIS_URL=redis://127.0.0.1:6379/0

JWT_SECRET_KEY=<REAL_LONG_RANDOM_SECRET>
# Compatibility with current backend code if auth_service.py expects SECRET_KEY.
SECRET_KEY=<REAL_LONG_RANDOM_SECRET>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

SMS_CODE_TTL_SECONDS=300
SMS_RESEND_COOLDOWN_SECONDS=60
SMS_MAX_ATTEMPTS=5
SMS_ATTEMPT_WINDOW_SECONDS=600
```

## Ручной запуск

```bash
cd /opt/oysyn-mobile-backend
source venv/bin/activate
uvicorn main:app --host 127.0.0.1 --port 8000
```

Если точка входа проекта отличается от `main:app`, нужно проверить FastAPI app в структуре backend и заменить команду `uvicorn`.

## Известные ошибки запуска

### `sqlalchemy.exc.ArgumentError: Expected string or URL object, got None`

Причина: `DATABASE_URL` не был загружен или отсутствовал в окружении.

Что проверить:

- существует `/opt/oysyn-mobile-backend/.env`;
- в `.env` есть `DATABASE_URL`;
- backend загружает `.env`, например через `python-dotenv`;
- при отсутствии `DATABASE_URL` код явно падает с понятной ошибкой:

```python
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set")
```

### `ModuleNotFoundError: No module named 'jose'`

Причина: не установлена зависимость для JWT.

Нужно добавить в `requirements.txt`:

```text
python-jose[cryptography]
```

### `RuntimeError: SECRET_KEY is not set or too short (min 32 chars)`

Причина: текущий backend-код в `auth_service.py` ожидает переменную `SECRET_KEY`, а production-шаблон может содержать только `JWT_SECRET_KEY`.

Быстрое исправление на сервере: добавить в `/opt/oysyn-mobile-backend/.env` переменную `SECRET_KEY` длиной минимум 32 символа. Значение может совпадать с `JWT_SECRET_KEY`.

```env
JWT_SECRET_KEY=<REAL_LONG_RANDOM_SECRET>
SECRET_KEY=<SAME_REAL_LONG_RANDOM_SECRET>
```

Более аккуратное исправление в коде: сделать backward-compatible чтение секрета, например `SECRET_KEY = os.getenv("JWT_SECRET_KEY") or os.getenv("SECRET_KEY")`, если это не ломает текущую архитектуру.

### `Form data requires "python-multipart" to be installed`

Причина: в routes используются form-data параметры, например `Form(...)`, `File(...)`, `UploadFile` или OAuth2 password form.

Исправление:

```bash
cd /opt/oysyn-mobile-backend
source venv/bin/activate
pip install python-multipart
```

После установки добавить зависимость в `requirements.txt`:

```text
python-multipart
```

### `ModuleNotFoundError: No module named 'pdfminer'`

Причина: `services/document_parser.py` импортирует `pdfminer.high_level`.

Исправление:

```bash
cd /opt/oysyn-mobile-backend
source venv/bin/activate
pip install pdfminer.six
```

После установки добавить зависимость в `requirements.txt`:

```text
pdfminer.six
```

### `ModuleNotFoundError: No module named 'docx2txt'`

Причина: `services/document_parser.py` импортирует `docx2txt`.

Исправление:

```bash
cd /opt/oysyn-mobile-backend
source venv/bin/activate
pip install docx2txt
```

После установки добавить зависимость в `requirements.txt`:

```text
docx2txt
```

## Зависимости, которые нужно проверить в backend

Перед production-запуском проанализировать реальные импорты проекта и зафиксировать все нужные пакеты в `requirements.txt`.

Минимальный список кандидатов:

```text
python-jose[cryptography]
passlib[bcrypt]
bcrypt
python-dotenv
psycopg2-binary
redis
python-multipart
pdfminer.six
docx2txt
```

Добавлять только те зависимости, которые реально используются кодом или нужны для подключения к PostgreSQL, Redis, `.env`, JWT, паролям, form-data upload/login и парсингу документов.

## Healthcheck

Если endpoint отсутствует, добавить:

```http
GET /health
```

Ожидаемый ответ:

```json
{"status":"ok"}
```

## systemd service

Файл:

```text
/etc/systemd/system/oysyn-mobile-backend.service
```

Ожидаемый service:

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

Если реальная точка входа FastAPI не `main:app`, заменить `ExecStart` на правильную команду.

Команды после создания или изменения service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable oysyn-mobile-backend
sudo systemctl restart oysyn-mobile-backend
sudo systemctl status oysyn-mobile-backend
```

## Внутренний Nginx `192.168.75.103`

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
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

Проверка и reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Проверки после запуска

На сервере `192.168.75.103`:

```bash
sudo systemctl status oysyn-mobile-backend
curl http://127.0.0.1:8000/health
curl http://192.168.75.103/health
curl https://api-mobile.oysyn.asia/health
```

Ожидаемый внешний ответ:

```json
{"status":"ok"}
```

## Рабочий чеклист backend-задачи

1. Проанализировать структуру backend-проекта.
2. Проверить `requirements.txt`.
3. Добавить недостающие зависимости по реальным импортам.
4. Проверить загрузку `.env`.
5. Добавить явную ошибку `RuntimeError("DATABASE_URL is not set")`, если `DATABASE_URL` отсутствует.
6. Проверить точку входа FastAPI и команду `uvicorn`.
7. Добавить `/health`, если endpoint отсутствует.
8. Проверить подключение к PostgreSQL через `DATABASE_URL`.
9. Не добавлять Alembic без необходимости, если в проекте нет миграций.
10. Добиться стабильного ручного запуска.
11. Подготовить и запустить systemd service.
12. Настроить внутренний Nginx `192.168.75.103`.
13. Не менять pfSense и внешний Nginx `192.168.75.100`, если HTTPS уже работает.

## Финальная цель

- FastAPI backend стабильно запущен через systemd.
- Backend слушает `127.0.0.1:8000`.
- Внутренний Nginx `192.168.75.103` проксирует на `127.0.0.1:8000`.
- `https://api-mobile.oysyn.asia/health` возвращает `{"status":"ok"}`.
- Все зависимости зафиксированы в `requirements.txt`.
- Секреты не попадают в GitHub.
