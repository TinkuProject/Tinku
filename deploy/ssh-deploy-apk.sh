#!/usr/bin/env bash
set -Eeuo pipefail

release_dir="${1:-}"
release_id="${2:-}"
for name in VPS_HOST VPS_PORT VPS_USER VPS_SSH_KEY VPS_KNOWN_HOSTS; do
  [[ -n "${!name:-}" ]] || { echo "Falta el secret $name." >&2; exit 2; }
done
[[ "$release_id" =~ ^[0-9a-f]{40}-[0-9]+$ && -d "$release_dir" ]] || { echo "Release APK invalido." >&2; exit 2; }
for file in Tinku.apk release.json Tinku.apk.sha256; do
  [[ -f "$release_dir/$file" && ! -L "$release_dir/$file" ]] || { echo "Falta $file." >&2; exit 2; }
done
[[ "$VPS_HOST" =~ ^[A-Za-z0-9.-]+$ && "$VPS_USER" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ && "$VPS_PORT" =~ ^[0-9]{1,5}$ ]] || { echo "Host, usuario o puerto SSH invalido." >&2; exit 2; }
(( VPS_PORT > 0 && VPS_PORT < 65536 )) || { echo "Puerto SSH invalido." >&2; exit 2; }

temp="$(mktemp -d)"
trap 'rm -rf -- "$temp"' EXIT
chmod 700 "$temp"
printf '%s\n' "$VPS_SSH_KEY" > "$temp/id_ed25519"
printf '%s\n' "$VPS_KNOWN_HOSTS" > "$temp/known_hosts"
chmod 600 "$temp/id_ed25519" "$temp/known_hosts"
ssh_options=(-i "$temp/id_ed25519" -p "$VPS_PORT" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$temp/known_hosts" -o ConnectTimeout=20)
scp_options=(-i "$temp/id_ed25519" -P "$VPS_PORT" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$temp/known_hosts" -o ConnectTimeout=20)
destination="$VPS_USER@$VPS_HOST"
remote_inbox="/var/www/tinku/monorepo/deploy/inbox"
remote_helper="$remote_inbox/deploy-apk-$release_id.sh"

ssh "${ssh_options[@]}" "$destination" "test -d '$remote_inbox' && test -d /var/www/tinku/monorepo/deploy/apks/releases"
scp "${scp_options[@]}" "$release_dir/Tinku.apk" "$release_dir/release.json" "$release_dir/Tinku.apk.sha256" deploy/server-deploy-apk.sh "$destination:$remote_inbox/"
ssh "${ssh_options[@]}" "$destination" "mv '$remote_inbox/server-deploy-apk.sh' '$remote_helper' && bash '$remote_helper' '$release_id'"
printf 'Release APK %s verificado y activado en el VPS.\n' "$release_id"
