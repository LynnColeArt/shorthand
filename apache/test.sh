#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BIN="$ROOT/zig-out/bin/short"
PORT="${PORT:-18080}"
WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/shorthand-apache-XXXXXX")
SERVER_ROOT="$WORKDIR/server-root"
DOCROOT="$SERVER_ROOT/htdocs"
LOGDIR="$SERVER_ROOT/logs"
CONF="$SERVER_ROOT/httpd.conf"
SCRIPT="$DOCROOT/index.short"
URL="http://127.0.0.1:${PORT}/index.short"

cleanup() {
    if [[ -n "${APACHE_PID:-}" ]] && kill -0 "$APACHE_PID" 2>/dev/null; then
        kill "$APACHE_PID" 2>/dev/null || true
        wait "$APACHE_PID" 2>/dev/null || true
    fi
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

if [[ ! -x "$BIN" ]]; then
    (cd "$ROOT" && zig build)
fi

mkdir -p "$DOCROOT" "$LOGDIR"

{
    printf '#!%s run\n' "$BIN"
    cat "$ROOT/apache/hello.short"
} > "$SCRIPT"
chmod 755 "$SCRIPT"

escape_sed() {
    printf '%s' "$1" | sed -e 's/[|&]/\\&/g'
}

sed \
    -e "s|__SERVER_ROOT__|$(escape_sed "$SERVER_ROOT")|g" \
    -e "s|__DOCROOT__|$(escape_sed "$DOCROOT")|g" \
    -e "s|__PORT__|$PORT|g" \
    -e "s|__USER__|$(escape_sed "$(id -un)")|g" \
    -e "s|__GROUP__|$(escape_sed "$(id -gn)")|g" \
    "$ROOT/apache/httpd.conf.in" > "$CONF"

apache2 -X -f "$CONF" >"$WORKDIR/apache.out" 2>"$WORKDIR/apache.err" &
APACHE_PID=$!

ready=0
for _ in $(seq 1 100); do
    if curl -fsS --max-time 1 "$URL" >/dev/null 2>"$WORKDIR/curl.err"; then
        ready=1
        break
    fi
    if ! kill -0 "$APACHE_PID" 2>/dev/null; then
        echo "Apache exited before it became ready." >&2
        echo "--- apache stdout ---" >&2
        cat "$WORKDIR/apache.out" >&2 || true
        echo "--- apache stderr ---" >&2
        cat "$WORKDIR/apache.err" >&2 || true
        echo "--- curl stderr ---" >&2
        cat "$WORKDIR/curl.err" >&2 || true
        exit 1
    fi
    sleep 0.1
done

if [[ "$ready" -ne 1 ]]; then
    echo "Apache did not become ready in time." >&2
    echo "--- apache stdout ---" >&2
    cat "$WORKDIR/apache.out" >&2 || true
    echo "--- apache stderr ---" >&2
    cat "$WORKDIR/apache.err" >&2 || true
    echo "--- curl stderr ---" >&2
    cat "$WORKDIR/curl.err" >&2 || true
    exit 1
fi

curl -fsS -D "$WORKDIR/headers.txt" -o "$WORKDIR/body.txt" "$URL"

tr -d '\r' < "$WORKDIR/headers.txt" | grep -Fq "X-ShortHand: apache"
grep -Fxq "Hello from Apache and ShortHand" "$WORKDIR/body.txt"

printf 'Apache integration OK\n'
