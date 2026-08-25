#!/usr/bin/env bash
# Check every enode listed in */metadata/enodes.yaml: well-formed URL, unique
# node id, and a TCP connection to its advertised port.
#
# X   (default: all)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"
TIMEOUT="${TIMEOUT:-8}"

fail=0
ok()  { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=1; }

check() {
  local net="$1"
  local file="$ROOT/$net/metadata/enodes.yaml"
  echo "== $net =="

  # A network may not publish bootnodes yet; that is not a failure.
  if [ ! -f "$file" ]; then
    printf '  %-22s %s\n' "skipped" "no metadata/enodes.yaml (no bootnodes published)"
    return 0
  fi

  local seen=""
  local count=0
  while IFS= read -r enode; do
    count=$((count + 1))
    if ! [[ "$enode" =~ ^enode://([0-9a-f]{128})@([0-9a-zA-Z.:-]+):([0-9]+)$ ]]; then
      bad "malformed enode: $enode"
      continue
    fi
    local id="${BASH_REMATCH[1]}" host="${BASH_REMATCH[2]}" port="${BASH_REMATCH[3]}"

    case " $seen " in
      *" $id "*) bad "duplicate node id ${id:0:16}…"; continue ;;
    esac
    seen="$seen $id"

    if nc -z -w "$TIMEOUT" "$host" "$port" >/dev/null 2>&1; then
      ok "$host:$port reachable (${id:0:16}…)"
    else
      bad "$host:$port unreachable (${id:0:16}…)"
    fi
  done < <(sed -n 's/^-[[:space:]]*\(enode:\/\/[^[:space:]#]*\).*$/\1/p' "$file")

  [ "$count" -gt 0 ] || bad "no enodes found in $file"
}

case "$TARGET" in
  all) check joc; echo; check joct; echo; check sandbox1 ;;
  joc|joct|sandbox1) check "$TARGET" ;;
  *) echo "usage: $0 [joc|joct|sandbox1|all]" >&2; exit 2 ;;
esac

exit $fail
