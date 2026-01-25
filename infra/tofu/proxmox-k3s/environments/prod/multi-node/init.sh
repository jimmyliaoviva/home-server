#!/bin/bash
# Initialize Terragrunt for server and agent-01 only
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Original: Initialize all nodes (server, agent-01, agent-02)
# terragrunt run-all init

# Modified: Initialize only server and agent-01
echo "Initializing server..."
cd server && terragrunt init && cd ..

echo "Initializing agent-01..."
cd agent-01 && terragrunt init && cd ..

echo "Initialization completed (server + agent-01)"
