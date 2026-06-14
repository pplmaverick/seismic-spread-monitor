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

RPC_URL="https://gcp-2.seismictest.net/rpc"
CONTRACT="0xBdC53E50b1167cE1199bFaD54A034f7ab1741051"
SCAST="$HOME/.seismic/bin/scast"

# 用一個假的 pair address（私密欄位，對鏈上不可見）
PAIR_ADDR="0x0000000000000000000000000000000000000001"
# threshold = 100 bps
THRESHOLD=100

echo "============================================"
echo " SpreadMonitor 互動腳本"
echo " Contract : $CONTRACT"
echo " RPC      : $RPC_URL"
echo "============================================"
echo ""

# ── Step 1: setStrategy ──────────────────────────────────────────────────────
echo "[1/4] setStrategy(pair=$PAIR_ADDR, threshold=$THRESHOLD)"
TX1=$("$SCAST" send \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 200000 \
    "$CONTRACT" \
    "setStrategy(saddress,suint256)" \
    "$PAIR_ADDR" \
    "$THRESHOLD" 2>&1)
echo "TX : $TX1"
echo ""

# ── Step 2: checkSpread(50) → spread < threshold → triggered=false ───────────
echo "[2/4] checkSpread(currentSpread=50)  → 50 < 100 → expect triggered=false"
TX2=$("$SCAST" send \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 200000 \
    "$CONTRACT" \
    "checkSpread(suint256)" \
    "50" 2>&1)
echo "TX : $(echo "$TX2" | grep transactionHash | head -1 | awk -F'"' '{print $4}')"
echo "triggered : $(echo "$TX2" | grep '"data":' | head -1 | grep -o '000[01]$')"
echo ""

# ── Step 3: checkSpread(100) → spread == threshold → triggered=true ──────────
echo "[3/4] checkSpread(currentSpread=100) → 100 >= 100 → expect triggered=true"
TX3=$("$SCAST" send \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 200000 \
    "$CONTRACT" \
    "checkSpread(suint256)" \
    "100" 2>&1)
echo "TX : $(echo "$TX3" | grep transactionHash | head -1 | awk -F'"' '{print $4}')"
echo "triggered : $(echo "$TX3" | grep '"data":' | head -1 | grep -o '000[01]$')"
echo ""

# ── Step 4: checkSpread(200) → spread > threshold → triggered=true ───────────
echo "[4/4] checkSpread(currentSpread=200) → 200 >= 100 → expect triggered=true"
TX4=$("$SCAST" send \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 200000 \
    "$CONTRACT" \
    "checkSpread(suint256)" \
    "200" 2>&1)
echo "TX : $(echo "$TX4" | grep transactionHash | head -1 | awk -F'"' '{print $4}')"
echo "triggered : $(echo "$TX4" | grep '"data":' | head -1 | grep -o '000[01]$')"
echo ""

echo "============================================"
echo " 全部完成！"
echo " Explorer : https://seismic-testnet.socialscan.io/address/$CONTRACT"
echo "============================================"
