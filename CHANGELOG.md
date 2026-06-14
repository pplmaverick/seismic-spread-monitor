# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-14

### Added

- Initial deployment of `SpreadMonitor` contract to Seismic Testnet (Chain ID 5124)
  - Contract: `0xBdC53E50b1167cE1199bFaD54A034f7ab1741051`
  - Network: Seismic Testnet
  - RPC: `https://gcp-2.seismictest.net/rpc`
  - Explorer: <https://seismic-testnet.socialscan.io>
- `setStrategy(saddress, suint256)` — stores encrypted trading pair and threshold on-chain
- `checkSpread(suint256)` — compares current spread against private threshold; emits `SpreadAlert(user, triggered)`
- `getMyThreshold()` — returns the caller's decrypted threshold (requires `seismic-viem` signed call)
- `isStrategyActive(address)` — public check for whether an address has an active strategy
- `deactivate(address)` — owner-only strategy deactivation
- `script/deploy.sh` with `--gas-limit 3000000` for reliable deployment on Seismic Testnet
- `script/interact.sh` for end-to-end on-chain testing (`setStrategy` → `checkSpread`)
- `.env.example` documenting all required environment variables

### Fixed

- Added explicit `--gas-limit 3000000` to `deploy.sh` after discovering `sforge`'s automatic gas estimation undershoots on Seismic Testnet, causing deployment transactions to fail with out-of-gas (gasUsed = gasLimit = 565,945)
