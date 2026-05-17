#!/bin/bash
# Destroy infrastructure for multi-node cluster (reverse order - agents first)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Destroying agent-02 (CLUSTER1 - shiro)..."
cd agent-02 && terragrunt destroy -auto-approve && cd ..

echo "Destroying agent-01 (CLUSTER2 - n100r)..."
cd agent-01 && terragrunt destroy -auto-approve && cd ..

echo "Destroying server (CLUSTER2 - n100r)..."
cd server && terragrunt destroy -auto-approve && cd ..

echo "Destroy completed (agent-02 + agent-01 + server)"
