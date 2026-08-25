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
| `<net>/config.yaml` | Beacon chain config ([joc](joc/config.yaml), [joct](joct/config.yaml)) |
| `<net>/genesis.json` | Execution-layer genesis with the merge fields added ([joc](joc/genesis.json), [joct](joct/genesis.json)) |
| `<net>/deposit_contract_block.txt` | Block the deposit contract is deployed at ([joc](joc/deposit_contract_block.txt), [joct](joct/deposit_contract_block.txt)) |
| [`presets.md`](presets.md) | Which spec preset the configs are based on, and why |

### `genesis.json`

The merge does not change the genesis block — it only adds fork-activation
fields to `config`. Each file here is therefore the live
`<net>/metadata/genesis.json` plus exactly five keys:

```
terminalTotalDifficulty   shanghaiTime   cancunTime   pragueTime   depositContractAddress
```

`../scripts/check_pos_migration.sh` enforces that invariant in CI: if the draft
ever diverges from the genesis the chain is actually running — a changed
`alloc`, a moved fork block, an unexpected config key — the build fails.

The placeholders are the string `"TBD"` rather than `null` on purpose. It keeps
the file valid JSON, and geth hard-fails parsing a string into `*big.Int` /
`*uint64` instead of quietly reading `null` as "terminal total difficulty zero",
which would mean *merge immediately*.

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
- `deposit_contract.txt` — deposit contract address (also `DEPOSIT_CONTRACT_ADDRESS` in `config.yaml`)
- `genesis.ssz` — beacon chain genesis state
- Genesis details: fork digest, validators root, genesis time

### Why there is no `genesis.ssz`

`genesis.ssz` is the beacon chain genesis state, derived from the deposit
contract's contents at a chosen block. None of its inputs exist yet:
`MIN_GENESIS_TIME`, `MIN_GENESIS_ACTIVE_VALIDATOR_COUNT`, `GENESIS_FORK_VERSION`
and `DEPOSIT_CONTRACT_ADDRESS` are all `TBD`, and no validator has deposited.

A generated stand-in would carry a `genesis_validators_root` that is pure
fiction — and that value is what every signature on the network is domain-
separated by. Shipping one publicly is worse than shipping nothing: clients
would compute fork digests that match no peer, and anything signed against it
would be signed under the wrong domain. It gets committed when the migration
parameters are real, not before.

## Do not use

These files cannot be verified — there is no beacon chain to check them against,
which is why they sit outside the CI-verified `metadata/` directories. Do not
point a production beacon node at them.
