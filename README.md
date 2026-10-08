# Selfsteal-заглушка для Reality (nginx)

## Запуск
1. DNS в Cloudflare: A-запись `SNI_HOST` -> IP ноды, **DNS only (серое облако)**.
2. `cp .env.example .env`, заполнить домен, токен CF, email.
3. Выбрать сайт через `SITE_INDEX` в `.env` (см. ниже).
4. `docker compose up -d` (первый старт выпустит wildcard-сертификат, ~1 мин).
5. Проверка на ноде:
   `curl -vk --resolve at.example.com:9443:127.0.0.1 https://at.example.com:9443/`

## Выбор сайта-заглушки
Заглушки лежат в каталогах `./sites/<N>/` (`1`, `2`, ...). Какую показывать —
задаётся переменной `SITE_INDEX` в `.env`:

- `SITE_INDEX=1` — показывать `./sites/1`
- `SITE_INDEX=2` — показывать `./sites/2`
- `SITE_INDEX=random` — случайный каталог из `./sites` при каждом старте контейнера

После смены значения: `docker compose up -d --force-recreate nginx`.

### Как добавить новый сайт
1. Создать каталог `./sites/3/` с `index.html` (минимум), опционально `404.html`,
   `favicon.svg`, `robots.txt`, свои ассеты.
2. Указать `SITE_INDEX=3` (либо оставить `random`, тогда новый сайт попадёт в пул).
3. `docker compose up -d --force-recreate nginx`.

Монтировать/переписывать конфиг при этом не нужно — каталог `./sites` целиком
прокинут в nginx, а корень выбирается на старте.

## Xray / Remnawave (realitySettings инбаунда)
```json
"realitySettings": {
  "show": false,
  "dest": "127.0.0.1:9443",
  "xver": 0,
  "serverNames": ["at.example.com"],
  "privateKey": "...",
  "shortIds": ["", "a1b2c3d4e5f60718"]
}
```
Клиент: `serverName` = `at.example.com`, `address` = `at.example.com` или IP ноды.

Порт 443 занимает Xray, nginx на 443 не слушает. Порт 80 держит nginx (редирект на https).
