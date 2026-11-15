#!/usr/bin/env bash
set -Eeuo pipefail

deploy_root="${TINKU_DEPLOY_ROOT:-/var/www/tinku/monorepo/deploy}"
release_root="$deploy_root/releases"
inbox="$deploy_root/inbox"
shared_env="$deploy_root/shared/api.env"
release_id="${1:-}"

if [[ ! "$release_id" =~ ^[0-9a-f]{40}-[0-9]+$ ]]; then
  echo "Release ID invalido." >&2
  exit 2
fi
if [[ ! -d "$inbox" || ! -d "$release_root" || ! -r "$shared_env" ]]; then
  echo "Falta la estructura inicial de despliegue o deploy/shared/api.env." >&2
  exit 2
fi

archive="$inbox/tinku-api-$release_id.tar.gz"
checksum="$archive.sha256"
if [[ ! -f "$archive" || ! -f "$checksum" ]]; then
  echo "No se encuentra el paquete o su checksum." >&2
  exit 2
fi
trap 'rm -f -- "$archive" "$checksum" "${BASH_SOURCE[0]}"' EXIT

exec 9>"$deploy_root/api-deploy.lock"
if ! flock -n 9; then
  echo "Ya hay otro despliegue de API en curso." >&2
  exit 1
fi

if ! (cd "$inbox" && sha256sum -c "$(basename "$checksum")"); then
  echo "El checksum del release no coincide." >&2
  exit 1
fi
if tar -tzf "$archive" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
  echo "El paquete contiene una ruta insegura." >&2
  exit 1
fi

release="$release_root/api-$release_id"
if [[ -e "$release" ]]; then
  echo "El release ya existe; no se reemplaza." >&2
  exit 1
fi
staging="$(mktemp -d "$release_root/.api-$release_id.XXXXXX")"
cleanup() { rm -rf -- "$staging"; }
trap cleanup EXIT
tar --no-same-owner -xzf "$archive" -C "$staging"
if [[ ! -f "$staging/Api/dist/index.js" || ! -f "$staging/Api/deploy-migrations.cjs" ]]; then
  echo "El paquete no contiene el build API esperado." >&2
  exit 1
fi

cd "$staging/Api"
npm ci --omit=dev --no-audit --no-fund
node --env-file="$shared_env" deploy-migrations.cjs
mv -- "$staging" "$release"
trap - EXIT

current="$deploy_root/current-api"
previous=""
if [[ -L "$current" ]]; then previous="$(readlink -f "$current")"; fi
candidate="$deploy_root/.current-api-$release_id"
ln -s -- "$release/Api" "$candidate"
mv -Tf -- "$candidate" "$current"

restore_previous() {
  echo "No paso el healthcheck; se restaura la release previa." >&2
  if [[ -n "$previous" && -d "$previous" ]]; then
    candidate="$deploy_root/.current-api-rollback"
    ln -sfn -- "$previous" "$candidate"
    mv -Tf -- "$candidate" "$current"
    PM2_HOME="$deploy_root/pm2" pm2 startOrReload "$previous/ecosystem.config.cjs" --update-env || true
  else
    rm -f -- "$current"
    PM2_HOME="$deploy_root/pm2" pm2 delete tinku-api-monorepo || true
  fi
}

if ! PM2_HOME="$deploy_root/pm2" pm2 startOrReload "$release/Api/ecosystem.config.cjs" --update-env; then
  restore_previous
  exit 1
fi

healthy=false
for attempt in $(seq 1 12); do
  if curl --fail --silent --show-error --max-time 8 http://127.0.0.1:3300/health/ready; then
    healthy=true
    break
  fi
  sleep 3
done
if [[ "$healthy" != true ]]; then
  restore_previous
  exit 1
fi

printf 'API activa: %s\n' "$release_id"
