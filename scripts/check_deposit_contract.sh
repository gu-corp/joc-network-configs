#!/usr/bin/env bash
# For any network that publishes a consensus-layer config, check that its
# deposit contract really is deployed at the advertised address and that the
# chain/network ids in the config agree with the live execution node.
#
# Networks with no metadata/config.yaml are skipped — joc and joct run Clique
# PoA and their beacon config is still a draft in ../pos-migration/.
#
# Usage: scripts/check_deposit_contract.sh [<network>|all]   (default: all)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"
NETWORKS="joc joct sandbox1"

fail=0
note() { printf '  %-22s %s\n' "$1" "$2"; }
ok()   { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=1; }

# DEPOSIT_CONTRACT_ADDRESS is an unquoted hex literal, which a YAML parser turns
# into an integer. Read the raw line instead so the checksummed form survives.
cfg_get() { sed -n "s/^$2:[[:space:]]*\([^[:space:]#]*\).*$/\1/p" "$1" | head -n1; }

rpc_call() {
  curl -sS -m 20 -X POST -H 'Content-Type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$2\",\"params\":$3}" "$1"
}

check() {
  local net="$1"
  local meta="$ROOT/$net/metadata"
  local config="$meta/config.yaml"

  echo "== $net =="
  if [ ! -f "$config" ]; then
    note "skipped" "no metadata/config.yaml (still PoA; draft in pos-migration/)"
    return 0
  fi

  local addr chain_id net_id rpc
  addr="$(cfg_get "$config" DEPOSIT_CONTRACT_ADDRESS)"
  chain_id="$(cfg_get "$config" DEPOSIT_CHAIN_ID)"
  net_id="$(cfg_get "$config" DEPOSIT_NETWORK_ID)"
  rpc="$(jq -r '.rpc[0]' "$meta/chain.json")"

  # deposit_contract.txt, when present, must not disagree with the config.
  if [ -f "$meta/deposit_contract.txt" ]; then
    local txt; txt="$(tr -d '[:space:]' < "$meta/deposit_contract.txt")"
    if [ "$txt" = "$addr" ]; then
      ok "deposit_contract.txt matches config.yaml"
    else
      bad "deposit_contract.txt=$txt but config.yaml=$addr"
    fi
  fi

  case "$addr" in
    0x*) ;;
    *) bad "DEPOSIT_CONTRACT_ADDRESS is not set to an address ($addr)"; return 0 ;;
  esac

  # The contract must actually exist on the chain the config points at.
  local code size
  code="$(rpc_call "$rpc" eth_getCode "[\"$addr\",\"latest\"]" | jq -r '.result // empty')"
  size=$(( (${#code} - 2) / 2 ))
  if [ -z "$code" ] || [ "$code" = "0x" ]; then
    bad "no contract deployed at $addr on $rpc"
  else
    ok "deposit contract deployed at $addr ($size bytes)"
  fi

  # ...and the ids in the config must be the ids that node reports.
  local live_chain live_net
  live_chain="$(rpc_call "$rpc" eth_chainId '[]' | jq -r '.result // empty')"
  live_net="$(rpc_call "$rpc" net_version '[]' | jq -r '.result // empty')"

  if [ -n "$live_chain" ] && [ "$((live_chain))" -eq "$chain_id" ]; then
    ok "DEPOSIT_CHAIN_ID $chain_id matches the node"
  else
    bad "DEPOSIT_CHAIN_ID=$chain_id but $rpc reports $((${live_chain:-0}))"
  fi

  if [ "$live_net" = "$net_id" ]; then
    ok "DEPOSIT_NETWORK_ID $net_id matches the node"
  else
    bad "DEPOSIT_NETWORK_ID=$net_id but $rpc reports ${live_net:-none}"
  fi
}

case "$TARGET" in
  all)
    rc=0; first=1
    for n in $NETWORKS; do
      [ $first -eq 1 ] || echo; first=0
      check "$n" || rc=1
    done
    exit $rc
    ;;
  *)
    for n in $NETWORKS; do
      [ "$n" = "$TARGET" ] && { check "$TARGET"; exit $fail; }
    done
    echo "usage: $0 [$(echo $NETWORKS | tr ' ' '|')|all]" >&2; exit 2
    ;;
esac
