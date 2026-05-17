# Seismic Privacy Spread Monitor

在 Seismic devnet 上部署的隱私版價差監控合約，利用 Seismic 的 shielded 型別保護每位用戶的策略參數，避免交易對地址與閾值洩漏至鏈上。

## 核心功能

| 函式 | 說明 |
|------|------|
| `setStrategy(saddress pair, suint256 threshold)` | 設定監控的交易對與觸發閾值，參數加密上鏈 |
| `checkSpread(suint256 currentSpread)` | 傳入當前價差，與私密閾值比對，emit `SpreadAlert(user, triggered)` |
| `getMyThreshold()` | 策略擁有者讀取自己的閾值（需 signed call） |
| `isStrategyActive(address)` | 查詢任意用戶的策略啟動狀態（公開） |
| `deactivate(address)` | Owner 停用任意用戶的策略 |

## 技術

- **Seismic Solidity** — 支援 shielded 型別的 EVM 相容合約語言
- **sFoundry（sforge / scast）** — Seismic 版 Foundry 工具鏈
- **`suint256`** — 加密的 uint256，只有擁有者可讀取
- **`saddress`** — 加密的 address，對外不可見

## 部署資訊

| 項目 | 值 |
|------|-----|
| 網路 | Seismic devnet |
| RPC | `https://node-2.seismicdev.net/rpc` |
| Chain ID | 5124 |
| 合約地址 | `0xE7e8863d840fcE15C40B68C21518fb5bDeF2d0c4` |
| Explorer | [查看合約](https://explorer-2.seismicdev.net/address/0xE7e8863d840fcE15C40B68C21518fb5bDeF2d0c4) |

## E2E 測試結果

| 步驟 | 呼叫 | Tx Hash | 結果 |
|------|------|---------|------|
| 1 | `setStrategy(0xDeaDBeef..., 100)` | [0x34f74f...](https://explorer-2.seismicdev.net/tx/0x34f74fbddf33b86bc30ef79e3d6c88f8dd3627d10f14b78fb4047b93b745cd95) | status 0x1 ✓ |
| 2 | `checkSpread(150)` | [0x55d0c0...](https://explorer-2.seismicdev.net/tx/0x55d0c0fca7ed293b014afcd3eeef436a5a0a55c90d46f2ad15d0f13334118bae) | `SpreadAlert(user, triggered=true)` ✓ |
| 3 | `getMyThreshold()` | signed call（不上鏈） | 回傳 `100` ✓ |

## 本地部署

```bash
# 安裝 sFoundry
curl -L \
  -H "Accept: application/vnd.github.v3.raw" \
  "https://api.github.com/repos/SeismicSystems/seismic-foundry/contents/sfoundryup/install?ref=seismic" | bash
source ~/.zshenv && sfoundryup

# 建立 .env
echo "PRIVATE_KEY=0x你的私鑰" > .env

# 編譯
sforge build

# 部署
bash script/deploy.sh
```

## 注意事項

- `external` 函式不能直接回傳 `suint256`，須 cast 成 `uint256`
- `suint256` 比較產生 `sbool`，需明確轉型 `bool(...)`
- `getMyThreshold()` 須透過 `seismic-viem` 的 `signedCall` 呼叫，`scast call` 無法正確傳遞 `msg.sender`
