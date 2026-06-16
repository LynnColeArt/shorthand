#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${STATE_FILE:-/tmp/shorthand-apache-site.state}"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "No running ShortHand browser site state file found." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$STATE_FILE"

if [[ -n "${CONF:-}" ]]; then
    apache2 -k stop -f "$CONF" >/dev/null 2>&1 || true
fi

if [[ -n "${PID:-}" ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
fi

if [[ -n "${WORKDIR:-}" ]] && [[ -d "$WORKDIR" ]]; then
    rm -rf "$WORKDIR"
fi

rm -f "$STATE_FILE"
echo "ShortHand browser site stopped."
