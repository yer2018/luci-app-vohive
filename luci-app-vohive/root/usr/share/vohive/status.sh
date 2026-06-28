#!/bin/sh

BIN="/etc/vohive/bin/vohive"
VERSION_FILE="/etc/vohive/bin/version"
ARCH_FILE="/etc/vohive/bin/arch"
BACKUP_VERSION_FILE="/etc/vohive/bin/version.bak"

json_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

uci_get() {
	local key="$1"
	local default="$2"
	local value

	value="$(uci -q get "vohive.main.$key" 2>/dev/null || true)"
	[ -n "$value" ] && printf '%s' "$value" || printf '%s' "$default"
}

resolve_asset_arch() {
	local configured="$1"
	local machine

	case "$configured" in
		'')
			machine="$(uname -m)"
			case "$machine" in
				aarch64|arm64) printf 'arm64' ;;
				x86_64|amd64) printf 'amd64' ;;
				armv7l|armv7) printf 'armv7' ;;
				*) printf 'unknown' ;;
			esac
			;;
		arm64|amd64|armv7)
			printf '%s' "$configured"
			;;
		*)
			printf 'unknown'
			;;
	esac
}

is_running=0
/etc/init.d/vohive running >/dev/null 2>&1 && is_running=1

enabled="$(uci_get enabled '0')"
host="$(uci_get host '0.0.0.0')"
port="$(uci_get port '7575')"
data_path="$(uci_get data_path '/etc/vohive/data')"
core_arch_config="$(uci_get core_arch '')"
core_arch_effective="$(resolve_asset_arch "$core_arch_config")"

core_installed=0
core_version=""
core_arch=""
backup_version=""
if [ -x "$BIN" ]; then
	core_installed=1
	core_version="$(cat "$VERSION_FILE" 2>/dev/null || true)"
	[ -n "$core_version" ] || core_version="已安装，版本未知"
	core_arch="$(cat "$ARCH_FILE" 2>/dev/null || true)"
	[ -n "$core_arch" ] || core_arch="$core_arch_effective"
fi
if [ -s "$BACKUP_VERSION_FILE" ]; then
	backup_version="$(cat "$BACKUP_VERSION_FILE" 2>/dev/null || true)"
fi

default_password=0
[ "$(uci_get username 'admin')" = "admin" ] && [ "$(uci_get password 'admin')" = "admin" ] && default_password=1

port_status="unknown"
if command -v ss >/dev/null 2>&1; then
	if ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]$port$"; then
		port_status="listening"
	else
		port_status="free"
	fi
elif command -v netstat >/dev/null 2>&1; then
	if netstat -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]$port$"; then
		port_status="listening"
	else
		port_status="free"
	fi
fi

df_json_fields() {
	local prefix="$1"
	local path="$2"
	local line total used avail percent mount

	line="$(df -kP "$path" 2>/dev/null | awk 'NR==2 {print $2 " " $3 " " $4 " " $5 " " $6}' || true)"
	if [ -n "$line" ]; then
		set -- $line
		total="$1"
		used="$2"
		avail="$3"
		percent="${4%%%}"
		mount="$5"
	else
		total=0
		used=0
		avail=0
		percent=0
		mount=""
	fi

	printf '"%s_total_kb":%s,' "$prefix" "$total"
	printf '"%s_used_kb":%s,' "$prefix" "$used"
	printf '"%s_avail_kb":%s,' "$prefix" "$avail"
	printf '"%s_percent":%s,' "$prefix" "$percent"
	printf '"%s_mount":"%s",' "$prefix" "$(json_escape "$mount")"
}

printf '{'
printf '"running":%s,' "$is_running"
printf '"enabled":%s,' "$enabled"
printf '"core_installed":%s,' "$core_installed"
printf '"core_version":"%s",' "$(json_escape "$core_version")"
printf '"core_arch":"%s",' "$(json_escape "$core_arch")"
printf '"core_arch_config":"%s",' "$(json_escape "$core_arch_config")"
printf '"core_arch_effective":"%s",' "$(json_escape "$core_arch_effective")"
printf '"backup_version":"%s",' "$(json_escape "$backup_version")"
printf '"host":"%s",' "$(json_escape "$host")"
printf '"port":"%s",' "$(json_escape "$port")"
printf '"data_path":"%s",' "$(json_escape "$data_path")"
printf '"default_password":%s,' "$default_password"
printf '"port_status":"%s",' "$port_status"
df_json_fields root /
df_json_fields data "$data_path"
printf '"root_space":"%s",' "$(json_escape "${root_avail_kb:-}")"
printf '"data_space":"%s"' "$(json_escape "${data_avail_kb:-}")"
printf '}\n'
