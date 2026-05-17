#!/bin/bash
# Plan infrastructure changes for multi-node cluster (server + agent-01 + agent-02)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Planning server..."
cd server && terragrunt plan && cd ..

echo "Planning agent-01..."
cd agent-01 && terragrunt plan && cd ..

echo "Planning agent-02..."
cd agent-02 && terragrunt plan && cd ..

echo "Plan completed (server + agent-01 + agent-02)"
