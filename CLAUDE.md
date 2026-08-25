# CLAUDE.md

Guidance for Claude Code working in this repository.

## Working agreements

**Never commit or push without being asked.** Ask before every commit and every
push, even if a commit was approved earlier in the same session — approval is
per-action, not standing. Doing the work, running the checks and reporting the
result is the deliverable; committing is a separate decision.

## What this repo is

Published network configuration for Japan Open Chain — data, not code. The one
promise it makes is that **every file describes what a network is actually
running, and CI proves it.** Any change that weakens that promise is a
regression, however convenient.

Laid out like [`eth-clients/mainnet`](https://github.com/eth-clients/mainnet).

## Layout rules

One directory per network at the top level: `joc/`, `joct/`, `sandbox1/`. Inside
each, everything machine-readable lives in `metadata/`.

- **`<network>/metadata/<file>` must stay uniform across networks.** Consumers
  build paths from the network name. Do not introduce a grouping tier —
  `mainnet/`, `testnet/`, `dev-net/` were all considered and rejected. Tier is a
  column in the root README table, not a directory level.
- **`metadata/config.yaml` is the *live* beacon config slot**, matching
  eth-clients. Only put a config there if that network actually runs it — a
  draft in that slot gets read as authoritative by tooling.
- Draft PoS config for joc and joct lives in `pos-migration/`. sandbox1's config
  is real (deployed deposit contract, concrete fork epochs) so it sits in
  `sandbox1/metadata/`.

## Genesis files are immutable

`<network>/metadata/genesis.json` describes a chain that has been running since
2018. It cannot change. `scripts/verify_genesis.sh` runs `geth init` on the file
and compares the resulting hash against both `genesis_details.yaml` and block 0
from the live RPC — edit a byte and CI fails. That is intended; do not work
around it.

The same applies to `pos-migration/<net>/genesis.json`, which must equal the
live genesis plus exactly five merge keys (`terminalTotalDifficulty`,
`shanghaiTime`, `cancunTime`, `pragueTime`, `depositContractAddress`).
`scripts/check_pos_migration.sh` enforces it.

## Things that will bite you

**The genesis hash does not cover `config`.** It commits to the allocation and
the header fields only. Fork blocks and `clique.epoch` can be wrong and every
check will still pass. Values that were not verified are marked `INFERRED` in
`genesis_details.yaml` — do not silently promote them.

**`networkId` is not `chainId` on two of the three networks.** joct is chain
`10081` / network `361257328`; sandbox1 is chain `1337` / network `1456260212`.
Geth defaults `--networkid` to the genesis `chainId`, so a node started without
an explicit `--networkid` never finds peers. `chain.json` carries the
chainlist-convention value; `genesis_details.yaml` carries the one geth needs.

**sandbox1 uses chain ID 1337**, the Ganache/Hardhat/Anvil default. Expect
collisions with local dev tooling.

**geth abbreviates hashes in terminal logs** (`hash=1b54bf..566733`). Parse
`--log.format json` output for the full 32 bytes; `verify_genesis.sh` does this
and keeps an abbreviated-form fallback.

**`DEPOSIT_CONTRACT_ADDRESS` is an unquoted hex literal** and a YAML parser
turns it into an integer. Read it from the raw line, as
`check_deposit_contract.sh` does.

**Docker is usually unavailable locally**, so `verify_genesis.sh` skips the
`geth init` step and only does the RPC comparison. The CI run is the real check
— do not claim a genesis is verified based on a local run alone.

## Scripts

| Script | What it proves |
|---|---|
| `verify_genesis.sh` | `genesis.json` reproduces the hash the live chain serves |
| `check_bootnodes.sh` | enodes are well-formed, unique, reachable (skips networks with no `enodes.yaml`) |
| `check_pos_migration.sh` | the PoS draft genesis has not drifted from the live genesis |
| `check_deposit_contract.sh` | the deposit contract is deployed; chain/network ids match the node |

All take `[<network>|all]` and are wired into `.github/workflows/verify.yml`,
which also runs weekly so bootnode rot surfaces without a PR.

## Adding a network

1. `mkdir -p <net>/metadata`, add `genesis.json`, `chain.json`.
2. Write `genesis_details.yaml`. Mark anything not derived from the chain
   `INFERRED` and say so in the provenance section.
3. Add the network to the `NETWORKS` list / `case` blocks in every script and to
   the root README table.
4. Add `enodes.yaml` if bootnodes exist. If not, leave it out rather than
   inventing entries — the checker skips missing files.
5. Run all four scripts, then let CI do the `geth init` check.

Prefer deriving facts from the chain over copying them from documentation. The
sandbox1 entry in `gu-sandbox-chain-docs` and `gu-ethereum-sdk` lists chain ID
99999 and a hostname that no longer resolves; the real values came from RPC.

## Known gaps

- sandbox1 publishes no bootnodes, and its `berlinBlock`, `clique.epoch` and
  pre-London fork blocks are `INFERRED`.
- sandbox1's native currency name comes from `gu-sandbox-chain-docs`, which is
  stale in other respects.
- No `chainspec.json` / `besu.json` (eth-clients ships both). Generating them
  means converting the clique config to another format; only add them if they
  can be verified by running Nethermind/Besu, the way geth verifies the rest.
- `pos-migration/` has no `genesis.ssz` and should not get a placeholder — see
  `pos-migration/README.md` for why.
