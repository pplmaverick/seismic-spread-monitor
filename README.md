# Seismic Privacy Spread Monitor

![Seismic Testnet](https://img.shields.io/badge/Seismic_Testnet-5124-blue)
![License](https://img.shields.io/badge/license-MIT-green)

A privacy-preserving spread monitoring contract deployed on Seismic Testnet. It leverages Seismic's shielded types to protect each user's strategy parameters — keeping trading pair addresses and alert thresholds encrypted on-chain, invisible to external observers.

**Deployed on Seismic Testnet**

| Field | Value |
|---|---|
| Network | Seismic Testnet |
| Chain ID | 5124 |
| RPC | `https://gcp-2.seismictest.net/rpc` |
| Contract | `0x072A3A0C04Cf8CDcaf5B4A73a4Ed4fF5A841531f` |
| Explorer | [View Contract](https://seismic-testnet.socialscan.io/address/0x072A3A0C04Cf8CDcaf5B4A73a4Ed4fF5A841531f) (`0x072A3A0C04Cf8CDcaf5B4A73a4Ed4fF5A841531f`) |

## Why Seismic-Native

On a standard EVM chain, all contract storage is publicly readable — any on-chain spread monitoring strategy leaks the user's trading pair and threshold to competitors. Seismic's shielded types encrypt this data at the VM level, with no off-chain trusted execution environment required.

| Design concern | Standard EVM approach | Seismic-native approach |
|---|---|---|
| Hide trading pair address | Store off-chain or use a centralized relayer | `saddress` — encrypted address, hidden from all external observers |
| Hide alert threshold | Commit-reveal scheme with on-chain exposure during reveal | `suint256` — encrypted uint256, readable only by the owner |
| Verify spread alert without leaking strategy | Reveal threshold publicly to compare | `checkSpread(suint256)` — compares current spread against private threshold, emits only the boolean result |
| Read own private data | Query public storage | `getMyThreshold()` — requires a signed call via `seismic-viem`; `msg.sender` is verified before decrypting |

## Core Functions

| Function | Description |
|---|---|
| `setStrategy(saddress pair, suint256 threshold)` | Register a trading pair and alert threshold; parameters are encrypted on-chain |
| `checkSpread(suint256 currentSpread)` | Compare the current spread against the private threshold and emit `SpreadAlert(user, triggered)` |
| `getMyThreshold()` | Let the strategy owner read their own threshold (requires a signed call) |
| `isStrategyActive(address)` | Check whether any address has an active strategy (public) |
| `deactivate(address)` | Owner-only: deactivate any user's strategy |

## Tech Stack

| Layer | Technology |
|---|---|
| Contract language | Seismic Solidity — EVM-compatible with native shielded type support |
| Toolchain | sFoundry (`sforge` / `scast`) — Seismic's fork of Foundry |
| Encrypted types | `suint256` — encrypted uint256; `saddress` — encrypted address |
| Client interaction | `seismic-viem` — required for signed calls to read private state |

## E2E Test Results

| Step | Call | Tx Hash | Result |
|---|---|---|---|
| 1 | `setStrategy(0xDeaDBeef..., 100)` | `0x34f74f...` | status `0x1` ✓ |
| 2 | `checkSpread(150)` | `0x55d0c0...` | `SpreadAlert(user, triggered=true)` ✓ |
| 3 | `getMyThreshold()` | signed call (off-chain) | returns `100` ✓ |

## Quick Start

```bash
# Install sFoundry
curl -L \
  -H "Accept: application/vnd.github.v3.raw" \
  "https://api.github.com/repos/SeismicSystems/seismic-foundry/contents/sfoundryup/install?ref=seismic" | bash
source ~/.zshenv && sfoundryup

# Create .env
echo "PRIVATE_KEY=0xYOUR_PRIVATE_KEY" > .env

# Compile
sforge build

# Deploy
bash script/deploy.sh
```

## Implementation Notes

**`suint256` return values**

`external` functions cannot directly return `suint256`; cast to `uint256` first before returning to the caller.

**`sbool` comparisons**

Comparing `suint256` values produces an `sbool`, which must be explicitly cast with `bool(...)` before use in control flow.

**Reading private state**

`getMyThreshold()` must be called via `seismic-viem`'s `signedCall`. Using `scast call` cannot correctly forward `msg.sender`, so the ownership check fails and the decrypted value is not returned.

## Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────┐
│                  Client                  │
│  .env (PRIVATE_KEY)                     │
│  scast / seismic-viem                   │
│  script/deploy.sh  script/interact.sh   │
└───────────────┬─────────────────────────┘
                │ JSON-RPC
                │ https://gcp-2.seismictest.net/rpc
                ▼
┌─────────────────────────────────────────┐
│        Seismic Testnet (Chain ID 5124)   │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │      SpreadMonitor Contract       │  │
│  │  0x072A3A0C...841531f             │  │
│  │                                   │  │
│  │  strategies[addr] → {             │  │
│  │    pair:      saddress (encrypted) │  │
│  │    threshold: suint256 (encrypted) │  │
│  │    isActive:  bool    (public)    │  │
│  │  }                                │  │
│  │                                   │  │
│  │  emit SpreadAlert(user, triggered) │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Seismic VM handles encryption below    │
│  the EVM execution layer                │
└─────────────────────────────────────────┘
```

### Data Flow

- **`setStrategy(saddress pair, suint256 threshold)`** — Encrypts and stores trading pair address and alert threshold on-chain; only the caller can read them back.
- **`checkSpread(suint256 currentSpread)`** — Compares current spread against encrypted threshold inside the Seismic VM; emits `SpreadAlert(user, triggered)`.
- **`getMyThreshold()`** — Returns decrypted threshold to the caller only; must use `seismic-viem` `signedCall` (plain `eth_call` returns zero for `msg.sender`).

## Known Limitations

These are known design tradeoffs in the current implementation, planned for resolution before mainnet deployment.

| Issue | Description | Fix |
|---|---|---|
| `SpreadAlert` side-channel leak | `currentSpread` is passed publicly + `triggered` is emitted publicly — an observer can binary-search to infer the private threshold | Remove public event; switch to off-chain notification (n8n listener) |
| `isStrategyActive` metadata leak | Anyone can enumerate which addresses are using the service | Add `require(msg.sender == target)` — users can only query their own status |
| `deactivate` centralization | Owner can forcibly deactivate any user's strategy | Restrict to user-only; remove owner override |

## Roadmap

**✅ M1 — Testnet Deployment (completed)**
- Privacy-preserving spread monitor with `saddress` + `suint256` shielded types
- E2E tested: setStrategy → checkSpread → getMyThreshold
- Deployed to Seismic Testnet

**⬜ M2 — Hardening (pre-mainnet)**
- Fix known limitations: side-channel leak, metadata leak, centralized deactivate
- Add `test/` directory with sforge unit tests
- Frontend UI with `seismic-viem` signed call UX
- Live DEX price feed integration (replace manual `checkSpread` input)

**⬜ M3 — Mainnet**
- Deploy to Seismic Mainnet when available
- Multi-pair strategy support per user
- Historical alert log (on-chain record of triggered spreads)

## Developer

GitHub: [pplmaverick](https://github.com/pplmaverick)
Wallet: `0xed2B...78F5` — deployed on Seismic Testnet

## License

MIT

