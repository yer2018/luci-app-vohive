#!/bin/sh

set -eu

BIN="/etc/vohive/bin/vohive"
BACKUP="/etc/vohive/bin/vohive.bak"
VERSION_FILE="/etc/vohive/bin/version"

json_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

fail() {
	printf '{"ok":false,"message":"%s"}\n' "$(json_escape "$*")"
	exit 1
}

[ -s "$BACKUP" ] || fail "No backup core found"

was_running=0
/etc/init.d/vohive running >/dev/null 2>&1 && was_running=1
[ "$was_running" = "0" ] || /etc/init.d/vohive stop || true

cp -f "$BACKUP" "$BIN"
chmod +x "$BIN"
printf 'rollback\n' > "$VERSION_FILE"

if [ "$was_running" = "1" ]; then
	/etc/init.d/vohive start || fail "Rolled back core, but service failed to start"
fi

printf '{"ok":true,"message":"已回滚到上一核心"}\n'
