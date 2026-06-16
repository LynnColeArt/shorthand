#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SITE_DIR="$ROOT/apache/site"
BIN="$ROOT/zig-out/bin/short"
PORT="${PORT:-18081}"
STATE_FILE="${STATE_FILE:-/tmp/shorthand-apache-site.state}"

if [[ -f "$STATE_FILE" ]]; then
    echo "ShortHand browser site already appears to be running." >&2
    echo "State file: $STATE_FILE" >&2
    exit 1
fi

if [[ ! -x "$BIN" ]]; then
    (cd "$ROOT" && zig build)
fi

WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/shorthand-apache-site-XXXXXX")
SERVER_ROOT="$WORKDIR/server-root"
DOCROOT="$SERVER_ROOT/htdocs"
LOGDIR="$SERVER_ROOT/logs"
CONF="$SERVER_ROOT/httpd.conf"

mkdir -p "$DOCROOT" "$LOGDIR"

for source in "$SITE_DIR"/*.short; do
    [[ -e "$source" ]] || continue
    target="$DOCROOT/$(basename "$source")"
    {
        printf '#!%s run\n' "$BIN"
        cat "$source"
    } > "$target"
    chmod 755 "$target"
done

escape_sed() {
    printf '%s' "$1" | sed -e 's/[|&]/\\&/g'
}

sed \
    -e "s|__SERVER_ROOT__|$(escape_sed "$SERVER_ROOT")|g" \
    -e "s|__DOCROOT__|$(escape_sed "$DOCROOT")|g" \
    -e "s|__PORT__|$PORT|g" \
    -e "s|__USER__|$(escape_sed "$(id -un)")|g" \
    -e "s|__GROUP__|$(escape_sed "$(id -gn)")|g" \
    "$SITE_DIR/httpd.conf.in" > "$CONF"

cleanup_on_failure() {
    apache2 -k stop -f "$CONF" >/dev/null 2>"$WORKDIR/apache.err" || true
    rm -rf "$WORKDIR"
}

apache2 -k start -f "$CONF" >"$WORKDIR/apache.out" 2>"$WORKDIR/apache.err"

ready=0
for _ in $(seq 1 100); do
    if curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/" >/dev/null 2>"$WORKDIR/curl.err"; then
        ready=1
        break
    fi
    if ! [[ -f "$SERVER_ROOT/httpd.pid" ]]; then
        echo "Apache exited before it became ready." >&2
        echo "--- apache stdout ---" >&2
        cat "$WORKDIR/apache.out" >&2 || true
        echo "--- apache stderr ---" >&2
        cat "$WORKDIR/apache.err" >&2 || true
        echo "--- curl stderr ---" >&2
        cat "$WORKDIR/curl.err" >&2 || true
        cleanup_on_failure
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
    cleanup_on_failure
    exit 1
fi

PID=""
if [[ -f "$SERVER_ROOT/httpd.pid" ]]; then
    PID=$(cat "$SERVER_ROOT/httpd.pid")
fi

cat > "$STATE_FILE" <<EOF
PID=$PID
WORKDIR=$WORKDIR
CONF=$CONF
PORT=$PORT
URL=http://shorthand.localhost:$PORT/
ALT_URL=http://localhost:$PORT/
EOF

echo "ShortHand browser site started."
echo "Primary URL: http://shorthand.localhost:$PORT/"
echo "Fallback URL: http://localhost:$PORT/"
echo "Stop with: ./apache/site/stop.sh"
