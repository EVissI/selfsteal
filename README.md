# Selfsteal-заглушка для Reality (nginx)

Сертификат выпускается Let's Encrypt через **HTTP-01** — без Cloudflare-токена.
Нужен лишь публично доступный **порт 80** на ноде. Серт выпускается на один
`SNI_HOST` (без wildcard), чего для selfsteal достаточно.

## Быстрый запуск (одной командой)
После клонирования и настройки DNS/портов:
```bash
./install.sh
```
Скрипт спросит `SNI_HOST`, `LE_EMAIL`, `SITE_INDEX`, создаст `.env` и поднимет контейнеры.
Без интерактива:
```bash
SNI_HOST=at.example.com LE_EMAIL=you@example.com SITE_INDEX=1 ./install.sh
```
Полностью с нуля на чистом сервере (Docker уже стоит):
```bash
git clone <URL-репозитория> selfsteal && cd selfsteal && ./install.sh
```
Существующий `.env` не перезаписывается; пересоздать — `FORCE_ENV=1 ./install.sh`.

## Запуск (вручную)
1. DNS: A-запись `SNI_HOST` -> IP ноды, **DNS only / без проксирования**
   (если домен в Cloudflare — серое облако; оранжевое ломает HTTP-01).
2. Открыть **порт 80** (ACME) и **443** (Xray) на ноде наружу.
3. `cp .env.example .env`, заполнить `SNI_HOST` и `LE_EMAIL`.
4. Выбрать сайт через `SITE_INDEX` в `.env` (см. ниже).
5. `docker compose up -d` (первый старт выпустит сертификат, ~30–60 c).
6. Проверка на ноде:
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

Порт 443 занимает Xray, nginx на 443 не слушает. Порт 80 держит nginx: отдаёт
ACME-challenge для продления серта и редиректит остальное на https.

## Сертификат (Let's Encrypt, HTTP-01)
- Первичный выпуск — контейнер `certbot-init` (standalone на порту 80, пока nginx
  не поднят), только если серта ещё нет.
- Продление — контейнер `certbot-renew` раз в 12 ч через webroot
  (`./certbot-www`), который nginx отдаёт на `/.well-known/acme-challenge/`.
  Downtime при продлении нет — порт 80 остаётся за nginx.
- Сертификаты лежат в `./certs` (в git не коммитятся).
