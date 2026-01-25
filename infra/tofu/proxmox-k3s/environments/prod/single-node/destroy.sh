#!/bin/bash
# Destroy infrastructure
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Destroying infrastructure..."
terragrunt destroy -auto-approve

echo "Destroy completed"
