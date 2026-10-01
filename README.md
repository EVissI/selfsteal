# Selfsteal-заглушка для Reality (nginx)

## Запуск
1. DNS в Cloudflare: A-запись `SNI_HOST` -> IP ноды, **DNS only (серое облако)**.
2. `cp .env.example .env`, заполнить домен, токен CF, email.
3. `docker compose up -d` (первый старт выпустит wildcard-сертификат, ~1 мин).
4. Проверка на ноде:
   `curl -vk --resolve at.example.com:9443:127.0.0.1 https://at.example.com:9443/`

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
