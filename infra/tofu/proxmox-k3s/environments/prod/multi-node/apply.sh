#!/bin/bash
# Apply infrastructure changes for multi-node cluster (server + agent-01 + agent-02)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Applying server..."
cd server && terragrunt apply -auto-approve && cd ..

echo "Applying agent-01..."
cd agent-01 && terragrunt apply -auto-approve && cd ..

echo "Applying agent-02..."
cd agent-02 && terragrunt apply -auto-approve && cd ..

echo "Apply completed (server + agent-01 + agent-02)"
