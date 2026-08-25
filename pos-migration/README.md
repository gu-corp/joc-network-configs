# PoA → PoS migration (draft)

**Nothing in this directory is active.** JOC runs Clique proof-of-authority on
both mainnet and testnet today. The configuration that actually drives the live
networks is in [`../joc/metadata/`](../joc/metadata/) and
[`../joct/metadata/`](../joct/metadata/).

This directory holds the working draft of the consensus-layer (beacon chain)
configuration for the planned migration to proof of stake. It is kept out of the
per-network `metadata/` directories on purpose: in the
[eth-clients](https://github.com/eth-clients/mainnet) layout this repo follows,
`metadata/config.yaml` is the *live* beacon config, and a draft in that slot
would be read as authoritative by tooling. When the migration parameters are
final, each file moves to `<network>/metadata/config.yaml`.

The upstream working copy lives in
[`gu-corp/joc-poa-posa-migration`](https://github.com/gu-corp/joc-poa-posa-migration).

## Contents

| File | Contents |
|---|---|
| [`joc/config.yaml`](joc/config.yaml) | Mainnet beacon chain config |
| [`joct/config.yaml`](joct/config.yaml) | Testnet beacon chain config |
| [`presets.md`](presets.md) | Which spec preset the configs are based on, and why |

## What is still open

Every value marked `TBD` is undecided. The ones that define the chain's identity
are all in that set:

| | `joc` | `joct` |
|---|---|---|
| `TBD` values | 7 | 15 |
| Temporary `18446744073709551615` stubs | 4 | 3 |

Mainnet: `TERMINAL_TOTAL_DIFFICULTY`, `MIN_GENESIS_TIME`,
`MIN_GENESIS_ACTIVE_VALIDATOR_COUNT`, `DEPOSIT_CONTRACT_ADDRESS`, and the Altair
/ Bellatrix / Capella fork epochs.

Testnet: the above, plus the whole set of fork versions. Mainnet encodes its
chain id in the low bytes (`0x0X000051`, `81 = 0x51`); the testnet equivalent
would be `0x0X002761` (`10081 = 0x2761`) but that has not been decided.

Also still to be produced, per network:

- `bootstrap_nodes.yaml` — consensus-layer bootnodes (ENRs)
- `deposit_contract.txt` / `deposit_contract_block.txt` — deposit contract address and deployment block
- `genesis.ssz` — beacon chain genesis state
- Genesis details: fork digest, validators root, genesis time

## Do not use

These files cannot be verified — there is no beacon chain to check them against,
which is why they sit outside the CI-verified `metadata/` directories. Do not
point a production beacon node at them.
