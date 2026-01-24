#!/bin/bash
# Plan infrastructure changes
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Planning infrastructure changes..."
terragrunt plan

echo "Plan completed"
