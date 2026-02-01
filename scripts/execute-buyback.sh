#!/bin/bash
# Execute automated buyback: USDC → KELLYCLAUDE via Uniswap

set -e

# Load environment
source .env 2>/dev/null || true

KELLYCLAUDE_TOKEN="${KELLYCLAUDE_TOKEN:-0x50D2280441372486BeecdD328c1854743EBaCb07}"
USDC_ADDRESS="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"  # Ethereum mainnet
UNISWAP_ROUTER="0xE592427A0AEce92De3Edee1F18E0157C05861564"  # Uniswap V3

# Get current USDC balance
USDC_BALANCE=$(node scripts/get-balance.js "$PAYMENT_WALLET_ADDRESS" "$USDC_ADDRESS")

echo "💰 Current USDC balance: $USDC_BALANCE"

# Minimum threshold
MIN_THRESHOLD=${1:-100}

if (( $(echo "$USDC_BALANCE < $MIN_THRESHOLD" | bc -l) )); then
  echo "⏸️  Balance below threshold ($MIN_THRESHOLD USDC). Skipping buyback."
  exit 0
fi

echo "🔄 Executing buyback..."
echo "Amount: $USDC_BALANCE USDC"
echo "Target: $kellyclaude_TOKEN"
echo ""

# Execute swap via Uniswap
RESULT=$(node scripts/uniswap-swap.js \
  --from "$USDC_ADDRESS" \
  --to "$kellyclaude_TOKEN" \
  --amount "$USDC_BALANCE" \
  --slippage 2)

# Parse results
TX_HASH=$(echo "$RESULT" | jq -r '.txHash')
KELLYCLAUDE_BOUGHT=$(echo "$RESULT" | jq -r '.amountOut')
PRICE=$(echo "$RESULT" | jq -r '.price')

echo "✅ Buyback successful!"
echo "Transaction: $TX_HASH"
echo "KELLYCLAUDE bought: $kellyclaude_BOUGHT tokens"
echo "Price: \$$PRICE per KELLYCLAUDE"
echo ""

# Log to history
echo "$(date +'%Y-%m-%d %H:%M:%S'),$USDC_BALANCE,$kellyclaude_BOUGHT,$PRICE,$TX_HASH" >> data/buyback-history.csv

# Optional: Burn or distribute
if [[ "$BUYBACK_ACTION" == "burn" ]]; then
  echo "🔥 Burning $kellyclaude_BOUGHT KELLYCLAUDE..."
  node scripts/burn-tokens.js "$kellyclaude_TOKEN" "$kellyclaude_BOUGHT"
elif [[ "$BUYBACK_ACTION" == "distribute" ]]; then
  echo "📤 Distributing $kellyclaude_BOUGHT KELLYCLAUDE to holders..."
  node scripts/distribute-to-holders.js "$kellyclaude_BOUGHT"
else
  echo "💎 Holding $kellyclaude_BOUGHT KELLYCLAUDE in treasury"
fi

echo ""
echo "Buyback complete! 🚀"
