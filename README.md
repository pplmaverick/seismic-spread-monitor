# Seismic Privacy Spread Monitor

A privacy-preserving spread monitoring contract deployed on Seismic devnet. It leverages Seismic's shielded types to protect each user's strategy parameters — keeping trading pair addresses and alert thresholds private on-chain.

## Core Functions

| Function | Description |
|----------|-------------|
| `setStrategy(saddress pair, suint256 threshold)` | Register a trading pair and alert threshold; parameters are encrypted on-chain |
| `checkSpread(suint256 currentSpread)` | Compare the current spread against the private threshold and emit `SpreadAlert(user, triggered)` |
| `getMyThreshold()` | Let the strategy owner read their own threshold (requires a signed call) |
| `isStrategyActive(address)` | Check whether any address has an active strategy (public) |
| `deactivate(address)` | Owner-only: deactivate any user's strategy |

## Tech Stack

- **Seismic Solidity** — EVM-compatible contract language with native shielded type support
- **sFoundry (sforge / scast)** — Seismic's fork of the Foundry toolkit
- **`suint256`** — An encrypted uint256 readable only by its owner
- **`saddress`** — An encrypted address hidden from external observers

## Deployment

| Field | Value |
|-------|-------|
| Network | Seismic devnet |
| RPC | `https://node-2.seismicdev.net/rpc` |
| Chain ID | 5124 |
| Contract | `0xE7e8863d840fcE15C40B68C21518fb5bDeF2d0c4` |
| Explorer | [View Contract](https://explorer-2.seismicdev.net/address/0xE7e8863d840fcE15C40B68C21518fb5bDeF2d0c4) |

## E2E Test Results

| Step | Call | Tx Hash | Result |
|------|------|---------|--------|
| 1 | `setStrategy(0xDeaDBeef..., 100)` | [0x34f74f...](https://explorer-2.seismicdev.net/tx/0x34f74fbddf33b86bc30ef79e3d6c88f8dd3627d10f14b78fb4047b93b745cd95) | status 0x1 ✓ |
| 2 | `checkSpread(150)` | [0x55d0c0...](https://explorer-2.seismicdev.net/tx/0x55d0c0fca7ed293b014afcd3eeef436a5a0a55c90d46f2ad15d0f13334118bae) | `SpreadAlert(user, triggered=true)` ✓ |
| 3 | `getMyThreshold()` | signed call (off-chain) | returns `100` ✓ |

## Local Deployment

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

## Notes

- `external` functions cannot directly return `suint256`; cast to `uint256` first
- Comparing `suint256` values produces an `sbool`, which must be explicitly cast with `bool(...)`
- `getMyThreshold()` must be called via `seismic-viem`'s `signedCall`; `scast call` cannot correctly forward `msg.sender`
