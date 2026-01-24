#!/bin/bash
# Destroy infrastructure for all nodes
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Destroying infrastructure for all nodes..."
terragrunt run-all destroy -auto-approve

echo "Destroy completed"
