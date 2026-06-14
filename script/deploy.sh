#!/bin/bash
set -e

# 載入 .env
if [ -f .env ]; then
    source .env
else
    echo "Error: .env not found. Please create .env with PRIVATE_KEY=0x..."
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

RPC_URL="https://testnet-1.seismictest.net/rpc"
CONTRACT_PATH="src/SpreadMonitor.sol:SpreadMonitor"

echo "Deploying SpreadMonitor to Seismic Testnet..."

DEPLOY_OUTPUT=$(sforge create \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast \
    "$CONTRACT_PATH")

CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
TX_HASH=$(echo "$DEPLOY_OUTPUT" | grep "Transaction hash:" | awk '{print $3}')

echo ""
echo "Contract Address : $CONTRACT_ADDRESS"
echo "Transaction Hash : $TX_HASH"
echo "Explorer         : https://seismic-testnet.socialscan.io/address/$CONTRACT_ADDRESS"

# 儲存合約地址
echo "$CONTRACT_ADDRESS" > out/deployed_address.txt
echo "Address saved to out/deployed_address.txt"
