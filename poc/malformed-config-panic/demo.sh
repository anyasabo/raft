#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-append}"             # append | snapshot
ADDR="${2:-127.0.0.1:13000}"
OUT_DIR="${3:-/tmp/raft-malformed-config-poc-$(date +%Y%m%d-%H%M%S)}"

mkdir -p "${OUT_DIR}"
FOLLOWER_LOG="${OUT_DIR}/follower.log"
INJECT_LOG="${OUT_DIR}/inject.log"

case "${MODE}" in
  append) INJECT_CMD="inject-append" ;;
  snapshot) INJECT_CMD="inject-snapshot" ;;
  *)
    echo "invalid mode: ${MODE} (expected append|snapshot)" >&2
    exit 2
    ;;
esac

cleanup() {
  if [[ -n "${FOLLOWER_PID:-}" ]] && kill -0 "${FOLLOWER_PID}" 2>/dev/null; then
    kill "${FOLLOWER_PID}" 2>/dev/null || true
    wait "${FOLLOWER_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

"${SCRIPT_DIR}/poc" follower "${ADDR}" >"${FOLLOWER_LOG}" 2>&1 &
FOLLOWER_PID=$!

sleep 1.5
"${SCRIPT_DIR}/poc" "${INJECT_CMD}" "${ADDR}" >"${INJECT_LOG}" 2>&1 || true
sleep 1

if kill -0 "${FOLLOWER_PID}" 2>/dev/null; then
  FOLLOWER_STATE="alive"
else
  FOLLOWER_STATE="exited"
fi

if rg -n "panic:" "${FOLLOWER_LOG}" >/dev/null 2>&1; then
  PANIC_STATE="yes"
else
  PANIC_STATE="no"
fi

echo "out_dir=${OUT_DIR}"
echo "mode=${MODE}"
echo "follower_state=${FOLLOWER_STATE}"
echo "panic_seen=${PANIC_STATE}"
echo "follower_log=${FOLLOWER_LOG}"
echo "inject_log=${INJECT_LOG}"
