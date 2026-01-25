#!/bin/bash
# Apply infrastructure changes for server and agent-01 only
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Original: Apply all nodes (server, agent-01, agent-02)
# terragrunt run-all apply -auto-approve

# Modified: Apply only server and agent-01 (respects dependency order)
echo "Applying server..."
cd server && terragrunt apply -auto-approve && cd ..

echo "Applying agent-01..."
cd agent-01 && terragrunt apply -auto-approve && cd ..

echo "Apply completed (server + agent-01)"
