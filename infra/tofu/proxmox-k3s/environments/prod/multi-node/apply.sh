#!/bin/bash
# Apply infrastructure changes for all nodes
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Applying infrastructure changes for all nodes..."
terragrunt run-all apply -auto-approve

echo "Apply completed"
