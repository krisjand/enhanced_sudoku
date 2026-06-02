#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"

echo "=== Generating puzzle ==="
response=$(curl -sf "$BASE_URL/puzzle")
echo "$response" | jq .

puzzle=$(echo "$response" | jq '.puzzle')

echo ""
echo "=== Solving puzzle ==="
curl -sf -X POST "$BASE_URL/puzzle/solve" \
  -H "Content-Type: application/json" \
  -d "{\"puzzle\": $puzzle}" | jq .
