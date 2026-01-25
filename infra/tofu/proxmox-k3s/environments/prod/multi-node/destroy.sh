#!/bin/bash
# Destroy infrastructure for server and agent-01 only
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Original: Destroy all nodes (server, agent-01, agent-02)
# terragrunt run-all destroy -auto-approve

# Modified: Destroy only server and agent-01 (reverse order - agents first)
echo "Destroying agent-01..."
cd agent-01 && terragrunt destroy -auto-approve && cd ..

echo "Destroying server..."
cd server && terragrunt destroy -auto-approve && cd ..

echo "Destroy completed (server + agent-01)"
