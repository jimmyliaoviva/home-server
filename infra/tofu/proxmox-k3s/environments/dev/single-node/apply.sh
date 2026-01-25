#!/bin/bash
# Apply infrastructure changes
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Applying infrastructure changes..."
terragrunt apply -auto-approve

echo "Apply completed"
