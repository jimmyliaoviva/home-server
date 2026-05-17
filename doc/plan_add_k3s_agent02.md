# Plan: Add k3s-prod-agent-02 to Production Multi-Node Cluster

## Overview

Add a new K3s worker node (k3s-prod-agent-02) to the existing production multi-node cluster by deploying a new Proxmox VM on Cluster 2 (shiro).

## Current Cluster State

| Node | IP | Proxmox Cluster | Role |
|------|-----|-----------------|------|
| k3s-prod-server | 192.168.68.210 | Cluster 2 (n100r) | Control Plane |
| k3s-prod-agent-01 | 192.168.68.211 | Cluster 2 (n100r) | Worker |

## Target Configuration

| Parameter | Value |
|-----------|-------|
| Node Name | k3s-prod-agent-02 |
| IP Address | 192.168.68.213 |
| Proxmox Node | Cluster 1 (shiro) |
| Memory | 16GB |
| Disk | 800GB |
| Cores | 4 |
| K3s Role | Worker (Agent) |

## Cluster Variable Mapping (Updated)

The CLUSTER variables were swapped for clarity:

| Variable | Maps To | Nodes Using |
|----------|---------|-------------|
| CLUSTER1 | shiro | agent-02 |
| CLUSTER2 | n100r | server, agent-01 |

This change is reflected in both the workflow file and terragrunt configurations.

## Completed Changes

### 1. Updated agent-02 Configuration

File: `infra/tofu/proxmox-k3s/environments/prod/multi-node/agent-02/terragrunt.hcl`

Changes applied:
- Memory: 8192 → 16384 (16GB)
- Disk: 200G → 800G
- IP: 192.168.68.212 → 192.168.68.213

### 2. Updated apply.sh

File: `infra/tofu/proxmox-k3s/environments/prod/multi-node/apply.sh`

Added agent-02 deployment step.

### 3. Updated plan.sh

File: `infra/tofu/proxmox-k3s/environments/prod/multi-node/plan.sh`

Added agent-02 planning step.

### 4. Updated CLUSTER Variable Mapping

Files modified:
- `.gitea/workflows/deploy_homelab_infra.yaml`
- `server/terragrunt.hcl` → CLUSTER2 (n100r)
- `agent-01/terragrunt.hcl` → CLUSTER2 (n100r)
- `agent-02/terragrunt.hcl` → CLUSTER1 (shiro)

## Execution Steps

### Step 1: User Updates apply.sh

Manually edit `apply.sh` to include agent-02 deployment.

### Step 2: Run deploy_homelab_infra Workflow

Trigger workflow with:
- Environment: `prod`
- Deployment Type: `multi-node`
- Action: `apply`

### Step 3: Verify Cluster

```bash
# SSH to server
ssh jimmy@192.168.68.210

# Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml

# Check nodes
kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes -o wide
```

Expected output:
```
NAME                 STATUS   ROLES          AGE   VERSION
k3s-prod-server      Ready    control-plane  ...   v1.28.x+k3s1
k3s-prod-agent-01   Ready    <none>         ...   v1.28.x+k3s1
k3s-prod-agent-02   Ready    <none>         ...   v1.28.x+k3s1
```

## K3s Installation Note

The cloud-init.tpl already supports agent mode. When deploying agent-02, the VM will:
1. Boot with cloud-init
2. Automatically install K3s agent and join existing cluster using K3S_TOKEN and K3S_SERVER_IP from environment variables

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Proxmox storage capacity | Medium | Verify shiro node has 800GB available |
| Network conflict | Low | Confirm 192.168.68.213 is available |
| K3s token mismatch | High | Ensure K3S_TOKEN matches server token |

## Estimated Time

- Configuration update: 5 minutes
- Workflow execution: 15-20 minutes
- K3s installation: 5-10 minutes
- Verification: 5 minutes
- **Total: ~35-40 minutes**

## Rollback Plan

If deployment fails:
1. Run `terragrunt destroy` in agent-02 directory
2. Check logs: `ssh jimmy@192.168.68.213 "sudo journalctl -u k3s -n 100"`
3. Fix configuration and re-run workflow

---

**Status**: Development completed. Ready for deployment.