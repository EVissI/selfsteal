#!/usr/bin/env bash
# Создаёт .env и поднимает selfsteal-заглушку одной командой.
#
#   ./install.sh                         # спросит значения интерактивно
#   SNI_HOST=at.example.com LE_EMAIL=you@example.com ./install.sh   # без вопросов
#   SITE_INDEX=random ./install.sh       # выбрать сайт (1|2|3|random), по умолчанию 1
#
# Существующий .env не перезаписывается (используется как есть), если не задан FORCE_ENV=1.
set -euo pipefail
cd "$(dirname "$0")"

say() { printf '\033[1;36m[selfsteal]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[selfsteal] %s\033[0m\n' "$*" >&2; exit 1; }

# --- проверки окружения ---
command -v docker >/dev/null 2>&1 || die "docker не найден в PATH"
if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DC="docker-compose"
else
  die "не найден 'docker compose' (v2) или 'docker-compose'"
fi

# --- .env ---
if [ -f .env ] && [ "${FORCE_ENV:-0}" != "1" ]; then
  say "Использую существующий .env (FORCE_ENV=1 чтобы пересоздать)"
else
  SNI_HOST="${SNI_HOST:-}"
  LE_EMAIL="${LE_EMAIL:-}"
  SITE_INDEX="${SITE_INDEX:-1}"
  NGINX_PORT="${NGINX_PORT:-9443}"

  if [ -z "$SNI_HOST" ]; then
    [ -t 0 ] || die "SNI_HOST не задан и нет интерактивного ввода. Запустите с SNI_HOST=..."
    read -r -p "SNI_HOST (хост-заглушка, напр. at.example.com): " SNI_HOST
  fi
  [ -n "$SNI_HOST" ] || die "SNI_HOST пустой"

  if [ -z "$LE_EMAIL" ]; then
    [ -t 0 ] || die "LE_EMAIL не задан и нет интерактивного ввода. Запустите с LE_EMAIL=..."
    read -r -p "LE_EMAIL (email для Let's Encrypt): " LE_EMAIL
  fi
  [ -n "$LE_EMAIL" ] || die "LE_EMAIL пустой"

  if [ -t 0 ]; then
    read -r -p "SITE_INDEX [1|2|3|random] (Enter = ${SITE_INDEX}): " _in || true
    [ -n "${_in:-}" ] && SITE_INDEX="$_in"
  fi

  umask 077
  cat > .env <<EOF
SNI_HOST=${SNI_HOST}
LE_EMAIL=${LE_EMAIL}
NGINX_PORT=${NGINX_PORT}
SITE_INDEX=${SITE_INDEX}
EOF
  say ".env создан (SNI_HOST=${SNI_HOST}, SITE_INDEX=${SITE_INDEX})"
fi

# shellcheck disable=SC1091
. ./.env

# --- запуск ---
say "Поднимаю контейнеры (первый старт выпустит сертификат, ~30-60 c)..."
$DC up -d

say "Статус certbot-init:"
$DC logs --no-log-prefix certbot-init 2>/dev/null | tail -n 5 || true

cat <<EOF

$(say "Готово.")
Проверка на ноде:
  curl -vk --resolve ${SNI_HOST}:${NGINX_PORT:-9443}:127.0.0.1 https://${SNI_HOST}:${NGINX_PORT:-9443}/

Какой сайт отдаётся:   $DC logs nginx | grep selfsteal
Логи выпуска серта:    $DC logs certbot-init
Сменить сайт:          отредактируйте SITE_INDEX в .env, затем:
                       $DC up -d --force-recreate nginx
EOF
