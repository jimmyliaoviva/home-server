#!/bin/bash
# Initialize Terragrunt for all nodes
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Initializing Terragrunt for all nodes..."
terragrunt run-all init

echo "Initialization completed"
