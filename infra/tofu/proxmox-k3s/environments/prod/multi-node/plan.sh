#!/bin/bash
# Plan infrastructure changes for server and agent-01 only
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Original: Plan all nodes (server, agent-01, agent-02)
# terragrunt run-all plan

# Modified: Plan only server and agent-01
echo "Planning server..."
cd server && terragrunt plan && cd ..

echo "Planning agent-01..."
cd agent-01 && terragrunt plan && cd ..

echo "Plan completed (server + agent-01)"
