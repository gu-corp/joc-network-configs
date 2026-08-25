# sandbox1 metadata

G.U. Sandbox Chain — the development network. Chain ID `1337`, Clique
proof-of-authority, 5-second blocks. This is where the PoA → PoS migration is
being rehearsed: unlike joc and joct, sandbox1 has a deployed deposit contract
and a real consensus-layer config.

> **The p2p network id is `1456260212`, not the chain ID `1337`.** Geth defaults
> `--networkid` to the genesis `chainId`, so it must be passed explicitly.
>
> **Chain ID `1337` is also the default for Ganache, Hardhat and Anvil.** Wallets
> and tooling configured for a local dev chain can collide with this network.

## Status

The execution layer is live and producing blocks. **The beacon chain has not
reached genesis.** As of 2026-08-25:

| | |
|---|---|
| `MIN_GENESIS_TIME` | `1787652600` — 2026-08-25T10:10:00Z, already passed |
| `MIN_GENESIS_ACTIVE_VALIDATOR_COUNT` | `5` |
| Deposits in the contract | **0** (`get_deposit_count()` returns 0) |
| `get_deposit_root()` | `0xd70a2347…7e5e` — the empty-tree root |

Genesis triggers once both conditions hold, so it waits on 5 validators
depositing. `TERMINAL_TOTAL_DIFFICULTY` is set to `2**64-1`, which is
unreachable, so the merge will not trigger on difficulty as configured.

## Genesis information

```yaml
chain_id: 1337
network_id: 1456260212        # geth --networkid — differs from chain_id
genesis_time: 1543235253      # 2018-11-26T12:27:33Z, same as joc and joct
genesis_hash: 0xb9f3edbea733300355a191e5f7fa9e39603abddd8a31bc63d6bbb1987d36ca3f
genesis_state_root: 0xc821f27902b258391f993d2953ab4956fb51ff3ba3be06e7a49f27611512a39e
gas_limit: 470000000
clique:
  period: 5
  epoch: 30000                # inferred, see below
  genesis_signers:
    - 0xba82df33044b90a6d76591aef9fb4870d6b53c20
berlin_block: 17553835        # inferred, see below
london_block: 17553835        # measured — first block carrying baseFeePerGas
```

## How much of this is verified

No official `genesis.json` for sandbox1 was available, so
[`metadata/genesis.json`](metadata/genesis.json) is reconstructed. Every header
field is copied verbatim from the live block 0; the 256 placeholder accounts
were each confirmed at 1 wei via `eth_getBalance` at block 0; the funded account
was traced from the chain's earliest transfers.

CI runs `geth init` on the file and compares the result with the genesis hash
above. Because the state root commits to the whole allocation, that check being
green **proves the allocation and every header field are exactly right**.

What the genesis hash does *not* cover is the `config` block. `berlin_block`,
`clique.epoch` and the pre-London fork blocks are marked `INFERRED` in
[`metadata/genesis_details.yaml`](metadata/genesis_details.yaml) — they follow
the convention joc and joct use and should be replaced from the authoritative
genesis file when it is available.

Two more things are unverified: **no bootnodes are published** (there is no
`metadata/enodes.yaml`), and the native currency name in
[`metadata/chain.json`](metadata/chain.json) comes from
`gu-corp/gu-sandbox-chain-docs`, which also lists a stale chain ID of 99999.

## Files

| File | Contents |
|---|---|
| [`metadata/genesis.json`](metadata/genesis.json) | Execution-layer genesis. Feed to `geth init`. |
| [`metadata/genesis_details.yaml`](metadata/genesis_details.yaml) | Genesis hash, state root, clique params, fork blocks, provenance |
| [`metadata/config.yaml`](metadata/config.yaml) | Consensus-layer (beacon chain) config |
| [`metadata/deposit_contract.txt`](metadata/deposit_contract.txt) | Deposit contract address |
| [`metadata/chain.json`](metadata/chain.json) | EIP-155 chain metadata — id, RPC endpoint, native currency, explorer |

## Endpoints

| | |
|---|---|
| RPC | `https://rpc-1.sandbox1.japanopenchain.org:8545` |
| Explorer | https://rpc-1.sandbox1.japanopenchain.org (Blockscout, same host, port 443) |

The endpoint documented in `gu-corp/gu-sandbox-chain-docs` and in
`gu-ethereum-sdk`'s chain constants — `https://sandbox1.japanopenchain.org:8545/`
with chain ID 99999 — does not resolve. Both should be updated.

## Run a node

```bash
geth init --datadir ~/.sandbox1 metadata/genesis.json
geth --datadir ~/.sandbox1 --networkid 1456260212 --syncmode full
```

No `--bootnodes` value can be given until bootnodes are published; peer with a
known node directly in the meantime.

Verify the config matches the live chain with `../scripts/verify_genesis.sh sandbox1`
and `../scripts/check_deposit_contract.sh sandbox1`.

## License

CC0 1.0 Universal. See [`../LICENSE`](../LICENSE).
