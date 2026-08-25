# joc-network-configs

Public network configuration for [Japan Open Chain](https://www.japanopenchain.org/) —
chain metadata, genesis information and bootnodes for JOC mainnet and the JOCT
testnet.

Laid out like [`eth-clients/mainnet`](https://github.com/eth-clients/mainnet):
one `metadata/` directory per network, holding the files a node operator or
client team needs. Everything is verified against the live networks by
[CI](.github/workflows/verify.yml) on every change and once a week.

## Networks

| | [`joc/`](joc/) — mainnet | [`joct/`](joct/) — testnet |
|---|---|---|
| Token | JOC | JOCT |
| Chain ID | `81` | `10081` |
| Geth `--networkid` | `81` | **`361257328`** |
| Consensus | Clique PoA, 5s blocks | Clique PoA, 5s blocks |
| Genesis hash | `0x1b54bfa6…c566733` | `0x0fb7b477…17df1d06` |
| Explorer | [explorer.japanopenchain.org](https://explorer.japanopenchain.org) | [explorer.testnet.japanopenchain.org](https://explorer.testnet.japanopenchain.org) |

> On testnet the p2p network id is **not** the chain id. Geth must be started
> with `--networkid 361257328` or it will not find peers.

## Layout

```
joc/                            joct/
  README.md                       README.md          genesis information
  metadata/                       metadata/
    genesis.json                    genesis.json     execution-layer genesis
    genesis_details.yaml            …                genesis hash, clique params, fork blocks
    enodes.yaml                     …                execution-layer bootnodes
    chain.json                      …                EIP-155 chain metadata

pos-migration/                  beacon chain config for the planned PoA -> PoS
  joc/config.yaml               migration — DRAFT, nothing here is active
  joct/config.yaml
  presets.md

scripts/
  verify_genesis.sh             genesis.json vs. genesis_details.yaml vs. live RPC
  check_bootnodes.sh            enode syntax, duplicates, reachability
```

`joc/` and `joct/` contain only what the live networks are actually running, and
every file in them is checked against those networks by CI.

Stable raw URLs, e.g.:

```
https://raw.githubusercontent.com/gu-corp/joc-network-configs/main/joc/metadata/genesis.json
https://raw.githubusercontent.com/gu-corp/joc-network-configs/main/joct/metadata/genesis.json
```

## Running a node

```bash
# Mainnet
geth init --datadir ~/.joc joc/metadata/genesis.json
geth --datadir ~/.joc --networkid 81 --syncmode full \
     --bootnodes "$(sed -n 's/^-[[:space:]]*\(enode:\/\/[^[:space:]#]*\).*$/\1/p' \
                    joc/metadata/enodes.yaml | paste -sd, -)"

# Testnet — note the network id
geth init --datadir ~/.joct joct/metadata/genesis.json
geth --datadir ~/.joct --networkid 361257328 --syncmode full \
     --bootnodes "$(sed -n 's/^-[[:space:]]*\(enode:\/\/[^[:space:]#]*\).*$/\1/p' \
                    joct/metadata/enodes.yaml | paste -sd, -)"
```

Geth `v1.13.5` is the version JOC tests against. For a batteries-included
Docker setup see [`gu-corp/joc-node-quickstart`](https://github.com/gu-corp/joc-node-quickstart).

## Verifying

```bash
./scripts/verify_genesis.sh      # needs docker + jq; recomputes the genesis hash
./scripts/check_bootnodes.sh     # needs nc
```

`verify_genesis.sh` runs `geth init` on the checked-in `genesis.json`, compares
the resulting hash with `genesis_details.yaml`, then compares both against block
0 as served by the network's public RPC. Without Docker it skips the local
recompute and still does the RPC comparison.

## Proof of stake

JOC runs Clique proof-of-authority on both networks today.
[`pos-migration/`](pos-migration/) holds the working draft of the beacon-chain
config for the planned PoA → PoS migration. **Every value there marked `TBD` is
still open and no production node should use it.**

It sits outside the per-network directories on purpose: in the eth-clients
layout, `metadata/config.yaml` is the *live* beacon config, so a draft in that
slot would be read as authoritative. When the migration parameters are final,
each file moves to `<network>/metadata/config.yaml`.

## Contributing

Bootnode changes and new RPC endpoints are welcome as pull requests. CI checks
that enodes are well-formed, unique and reachable, and that no change alters the
genesis the live networks are running. Genesis files themselves are immutable —
a PR that changes one will fail.

## License

[CC0 1.0 Universal](LICENSE). Public domain.
