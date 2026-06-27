#!/bin/bash
set -e

if [ -f .env ]; then
    source .env
else
    echo "Error: .env not found"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://testnet-1.seismictest.net/rpc"
CONTRACT="0xBdC53E50b1167cE1199bFaD54A034f7ab1741051"
SCAST="$HOME/.seismic/bin/scast"

echo "============================================"
echo " SpreadMonitor 多幣對互動腳本"
echo " Contract : $CONTRACT"
echo " RPC      : $RPC_URL"
echo "============================================"
echo ""

# Helper: 送出一筆 tx，確認後再繼續，hash 存入全域 TX_HASH
send_tx() {
    local desc="$1"; shift
    printf "  ▶ %s\n" "$desc"
    local raw
    raw=$("$SCAST" send \
        --rpc-url "$RPC_URL" \
        --private-key "$PRIVATE_KEY" \
        --gas-limit 200000 \
        "$@" 2>&1)
    TX_HASH=$(printf '%s' "$raw" | grep -o '"transactionHash":"0x[a-f0-9]*"' | grep -o '0x[a-f0-9]*' | head -1)
    [ -z "$TX_HASH" ] && TX_HASH=$(printf '%s' "$raw" | grep -Eo '0x[a-f0-9]{64}' | head -1)
    printf "    TX: %s\n\n" "$TX_HASH"
}

# ── ETH/USDC pair (pair=0x000...001, threshold=100 bps) ──────────────────────
echo "━━━ ETH/USDC  (threshold=100 bps) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
send_tx "setStrategy(0x000...001, 100)" \
    "$CONTRACT" "setStrategy(saddress,suint256)" \
    "0x0000000000000000000000000000000000000001" "100"
ETH_SET=$TX_HASH

send_tx "checkSpread(80)  → 80 < 100  → expect triggered=false" \
    "$CONTRACT" "checkSpread(suint256)" "80"
ETH_CHK1=$TX_HASH

send_tx "checkSpread(120) → 120 >= 100 → expect triggered=true" \
    "$CONTRACT" "checkSpread(suint256)" "120"
ETH_CHK2=$TX_HASH
echo ""

# ── BTC/USDC pair (pair=0x000...002, threshold=200 bps) ──────────────────────
echo "━━━ BTC/USDC  (threshold=200 bps) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
send_tx "setStrategy(0x000...002, 200)" \
    "$CONTRACT" "setStrategy(saddress,suint256)" \
    "0x0000000000000000000000000000000000000002" "200"
BTC_SET=$TX_HASH

send_tx "checkSpread(150) → 150 < 200  → expect triggered=false" \
    "$CONTRACT" "checkSpread(suint256)" "150"
BTC_CHK1=$TX_HASH

send_tx "checkSpread(250) → 250 >= 200 → expect triggered=true" \
    "$CONTRACT" "checkSpread(suint256)" "250"
BTC_CHK2=$TX_HASH
echo ""

# ── ARB/USDC pair (pair=0x000...003, threshold=50 bps) ───────────────────────
echo "━━━ ARB/USDC  (threshold=50 bps)  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
send_tx "setStrategy(0x000...003, 50)" \
    "$CONTRACT" "setStrategy(saddress,suint256)" \
    "0x0000000000000000000000000000000000000003" "50"
ARB_SET=$TX_HASH

send_tx "checkSpread(30)  → 30 < 50   → expect triggered=false" \
    "$CONTRACT" "checkSpread(suint256)" "30"
ARB_CHK1=$TX_HASH

send_tx "checkSpread(70)  → 70 >= 50  → expect triggered=true" \
    "$CONTRACT" "checkSpread(suint256)" "70"
ARB_CHK2=$TX_HASH
echo ""

# ── 彙整報告 ─────────────────────────────────────────────────────────────────
echo "============================================"
echo " 全部完成！TX Hash 彙整"
echo "============================================"
echo ""
echo "ETH/USDC"
echo "  setStrategy      : $ETH_SET"
echo "  checkSpread(80)  : $ETH_CHK1"
echo "  checkSpread(120) : $ETH_CHK2"
echo ""
echo "BTC/USDC"
echo "  setStrategy       : $BTC_SET"
echo "  checkSpread(150)  : $BTC_CHK1"
echo "  checkSpread(250)  : $BTC_CHK2"
echo ""
echo "ARB/USDC"
echo "  setStrategy     : $ARB_SET"
echo "  checkSpread(30) : $ARB_CHK1"
echo "  checkSpread(70) : $ARB_CHK2"
echo ""
echo "Explorer : https://seismic-testnet.socialscan.io/address/$CONTRACT"
echo "============================================"
