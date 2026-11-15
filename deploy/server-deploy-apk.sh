#!/usr/bin/env bash
set -Eeuo pipefail

deploy_root="${TINKU_DEPLOY_ROOT:-/var/www/tinku/monorepo/deploy}"
apk_root="$deploy_root/apks"
release_root="$apk_root/releases"
inbox="$deploy_root/inbox"
release_id="${1:-}"

if [[ ! "$release_id" =~ ^[0-9a-f]{40}-[0-9]+$ ]]; then echo "Release ID invalido." >&2; exit 2; fi
if [[ ! -d "$inbox" || ! -d "$release_root" ]]; then echo "Falta la estructura deploy/inbox o deploy/apks/releases." >&2; exit 2; fi

apk="$inbox/Tinku.apk"
metadata="$inbox/release.json"
checksum="$inbox/Tinku.apk.sha256"
helper="${BASH_SOURCE[0]}"
cleanup_files() { rm -f -- "$apk" "$metadata" "$checksum" "$helper"; }
trap cleanup_files EXIT
for file in "$apk" "$metadata" "$checksum"; do [[ -f "$file" && ! -L "$file" ]] || { echo "Falta o es invalido: $file" >&2; exit 1; }; done

exec 9>"$apk_root/deploy.lock"
if ! flock -n 9; then echo "Ya hay otro despliegue APK en curso." >&2; exit 1; fi
(cd "$inbox" && sha256sum -c Tinku.apk.sha256)
node - "$metadata" "$release_id" "$(sha256sum "$apk" | cut -d ' ' -f 1)" "$(stat -c '%s' "$apk")" <<'NODE'
const fs = require('node:fs');
const [file, expectedId, expectedHash, actualSize] = process.argv.slice(2);
const release = JSON.parse(fs.readFileSync(file, 'utf8'));
if (release.releaseId !== expectedId || release.applicationId !== 'com.tinku.tinkuapp') throw Error('Metadata del APK no coincide con el release esperado.');
if (!Number.isSafeInteger(release.versionCode) || release.versionCode < 1 || !/^\d+\.\d+\.\d+$/.test(release.versionName || '')) throw Error('Version del APK invalida.');
if (release.sha256 !== expectedHash || !Number.isSafeInteger(release.sizeBytes) || release.sizeBytes < 1000000 || release.sizeBytes !== Number(actualSize)) throw Error('Checksum o tamaño del APK invalido.');
NODE

release="$release_root/$release_id"
if [[ -e "$release" ]]; then echo "El release ya existe; no se reemplaza." >&2; exit 1; fi
staging="$(mktemp -d "$release_root/.$release_id.XXXXXX")"
cleanup_staging() { rm -rf -- "$staging"; }
trap 'cleanup_staging; cleanup_files' EXIT
install -m 0644 "$apk" "$staging/Tinku.apk"
install -m 0644 "$metadata" "$staging/release.json"
install -m 0644 "$checksum" "$staging/Tinku.apk.sha256"
# Nginx serves APK releases directly, so it must be able to traverse this directory.
chmod 0755 "$staging"
mv -- "$staging" "$release"
trap cleanup_files EXIT

candidate="$apk_root/.current-$release_id"
ln -s -- "$release" "$candidate"
mv -Tf -- "$candidate" "$apk_root/current"
printf 'Release APK activa: %s\n' "$release_id"
