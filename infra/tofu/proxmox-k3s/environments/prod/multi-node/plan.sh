#!/bin/bash
# Plan infrastructure changes for all nodes
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Planning infrastructure changes for all nodes..."
terragrunt run-all plan

echo "Plan completed"
