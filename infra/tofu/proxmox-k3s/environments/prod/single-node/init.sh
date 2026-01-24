#!/bin/bash
# Initialize Terragrunt
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Initializing Terragrunt..."
terragrunt init

echo "Initialization completed"
