#!/usr/bin/env bash
set -euo pipefail

GATEWAY=${GATEWAY_URL:-http://localhost:4000}

echo "Waiting for gateway to become healthy..."
for i in {1..30}; do
  if curl -s ${GATEWAY}/api/health | grep -q ok; then
    echo "Gateway healthy"
    break
  fi
  sleep 2
done

echo "Registering test user..."
REG=$(curl -s -X POST ${GATEWAY}/api/auth/register -H 'Content-Type: application/json' -d '{"name":"e2e","email":"e2e@example.com","password":"secret"}')
echo "Register response: $REG"

TOKEN=$(echo "$REG" | jq -r .token)
if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "Registration failed or token missing" >&2
  exit 1
fi

echo "Creating a task..."
CREATE=$(curl -s -X POST ${GATEWAY}/api/tasks -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"title":"E2E Task"}')
echo "Create task response: $CREATE"

echo "E2E flow completed"
