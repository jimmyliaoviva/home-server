# Gitea Actions Workflows

## Deploy Homelab Infrastructure

自動化部署 K3s 基礎設施到 Proxmox，支援 Terragrunt 和多種部署類型。

### 功能

- ✅ 支援 **Single-Node** 和 **Multi-Node** 部署
- ✅ 支援 **Dev** 和 **Prod** 環境
- ✅ 使用 **Terragrunt** 進行依賴管理
- ✅ 自動處理節點依賴順序（Server → Agents）
- ✅ 支援 **plan**, **apply**, **destroy** 操作
- ✅ 使用 **Gitea Secrets** 安全管理敏感資訊

### 前置需求

#### 必須設定的 Secrets

在使用此 workflow 之前，請先在 Gitea Repository 中設定以下 Secrets：

1. 進入 Repository → **Settings** → **Secrets**
2. 新增 Secret:
   - **Name**: `TF_STATE_CONN_STR`
   - **Value**: PostgreSQL 連接字串
     ```
     postgres://jimmy:your-password@192.168.68.120:5432/tofu_state?sslmode=disable
     ```

**詳細說明請參考**: [SECRETS.md](./SECRETS.md)

### 使用方式

#### 在 Gitea UI 中觸發

1. 進入 Repository → Actions
2. 選擇 "Deploy homelab infrastructure"
3. 點擊 "Run workflow"
4. 選擇參數：
   - **Environment**: `dev` 或 `prod`
   - **Deployment Type**: `single-node` 或 `multi-node`
   - **Action**: `plan`, `apply`, 或 `destroy`
5. 點擊 "Run workflow"

#### 參數說明

| 參數 | 選項 | 說明 |
|------|------|------|
| `environment` | dev / prod | 部署環境 |
| `deployment_type` | single-node / multi-node | 部署類型 |
| `action` | plan / apply / destroy | 執行動作 |

### 部署類型

#### Single-Node

部署單一 K3s 節點（All-in-one）

- **路徑**: `environments/{env}/single-node/`
- **節點數**: 1
- **適用**: 開發、測試、小型環境

**執行命令**:
```bash
# Plan
terragrunt plan

# Apply
terragrunt apply -auto-approve

# Destroy
terragrunt destroy -auto-approve
```

#### Multi-Node

部署 K3s 叢集（1 Server + 2 Agents）

- **路徑**: `environments/{env}/multi-node/`
- **節點數**: 3 (1 server + 2 agents)
- **適用**: 生產環境、高可用需求

**執行命令**:
```bash
# Plan all nodes
terragrunt run-all plan

# Apply all nodes (Server first, then Agents)
terragrunt run-all apply -auto-approve

# Destroy all nodes
terragrunt run-all destroy -auto-approve
```

### Workflow 步驟

1. **Provision Runner** - 啟動 on-demand runner 容器
2. **Checkout code** - 拉取最新代碼
3. **Setup SSH key** - 配置 SSH 私鑰用於連接 VM
4. **Verify tools** - 驗證 Terragrunt 和 OpenTofu 安裝
5. **Set deployment path** - 根據參數設定部署路徑
6. **Generate env-vars.hcl** - 從 secrets/variables 生成配置檔案
7. **Initialize** - 初始化 Terragrunt/OpenTofu
8. **Validate** - 驗證配置
9. **Plan** (if action=plan/apply) - 顯示變更計劃
10. **Apply** (if action=apply) - 執行部署
11. **Destroy** (if action=destroy) - 銷毀基礎設施
12. **Show status** - 顯示部署狀態和輸出
13. **Installation instructions** - 顯示 K3s 安裝指令
14. **Destroy Runner** - 清理 runner 容器

### 部署後步驟

Workflow 會自動部署 VM，但 **K3s 需要手動安裝**。

#### Single-Node 安裝 K3s

```bash
# 1. 獲取 VM IP
cd infra/tofu/proxmox-k3s/environments/dev/single-node
VM_IP=$(terragrunt output -raw vm_ip)

# 2. SSH 連接
ssh -i ~/.ssh/home_server jimmy@$VM_IP

# 3. 安裝 K3s
curl -sfL https://get.k3s.io | K3S_TOKEN="your-token" sh -s - \
  --disable=traefik \
  --disable=servicelb

# 4. 驗證
kubectl get nodes
```

#### Multi-Node 安裝 K3s

```bash
# 1. 獲取所有節點 IP
cd infra/tofu/proxmox-k3s/environments/dev/multi-node
SERVER_IP=$(cd server && terragrunt output -raw vm_ip)
AGENT1_IP=$(cd agent-01 && terragrunt output -raw vm_ip)
AGENT2_IP=$(cd agent-02 && terragrunt output -raw vm_ip)

# 2. 在 Server 安裝 K3s
ssh -i ~/.ssh/home_server jimmy@$SERVER_IP
curl -sfL https://get.k3s.io | K3S_TOKEN="your-token" sh -s - server \
  --cluster-init \
  --disable=traefik \
  --disable=servicelb
# 等待 Server 啟動完成

# 3. 在 Agent 1 安裝 K3s
ssh -i ~/.ssh/home_server jimmy@$AGENT1_IP
curl -sfL https://get.k3s.io | \
  K3S_URL=https://$SERVER_IP:6443 \
  K3S_TOKEN="your-token" sh -

# 4. 在 Agent 2 安裝 K3s
ssh -i ~/.ssh/home_server jimmy@$AGENT2_IP
curl -sfL https://get.k3s.io | \
  K3S_URL=https://$SERVER_IP:6443 \
  K3S_TOKEN="your-token" sh -

# 5. 驗證叢集（在 Server 上）
ssh -i ~/.ssh/home_server jimmy@$SERVER_IP
kubectl get nodes
```

### 範例場景

#### 場景 1: 部署開發環境 Single-Node

1. 選擇:
   - Environment: `dev`
   - Deployment Type: `single-node`
   - Action: `apply`
2. 等待部署完成
3. 手動安裝 K3s（參考上方指令）

#### 場景 2: 部署生產環境 Multi-Node 叢集

1. 先 plan 檢查:
   - Environment: `prod`
   - Deployment Type: `multi-node`
   - Action: `plan`
2. 確認無誤後 apply:
   - Environment: `prod`
   - Deployment Type: `multi-node`
   - Action: `apply`
3. 依序在各節點安裝 K3s（參考上方指令）

#### 場景 3: 銷毀開發環境

1. 選擇:
   - Environment: `dev`
   - Deployment Type: `single-node` 或 `multi-node`
   - Action: `destroy`
2. 確認銷毀

### 依賴關係

Multi-Node 部署時，Terragrunt 會自動處理依賴:

```
Server (部署順序: 1)
  ↓
Agent-01 (部署順序: 2)
  ↓
Agent-02 (部署順序: 3)
```

銷毀時順序相反:

```
Agent-02 (銷毀順序: 1)
  ↓
Agent-01 (銷毀順序: 2)
  ↓
Server (銷毀順序: 3)
```

### 故障排除

#### 錯誤: "Terragrunt is not installed"

```bash
# 在 runner 上安裝 Terragrunt
wget https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

#### 錯誤: "Deployment path does not exist"

確認選擇的環境和部署類型組合存在:
- `environments/dev/single-node/` ✅
- `environments/dev/multi-node/` ✅
- `environments/prod/single-node/` ✅
- `environments/prod/multi-node/` ❌ (需要創建)

#### Multi-Node 部署失敗

檢查:
1. Server 節點是否部署成功
2. Agent 節點是否能訪問 Server IP
3. K3s token 是否一致

### Workflow Architecture

此 workflow 使用 **reusable workflows** 模式：

```
deploy_homelab_infra.yaml (主 workflow)
  ├─→ provision_runner.yaml (啟動 runner)
  ├─→ deploy-k3s-infra (主要部署 job)
  └─→ destory_runner.yaml (清理 runner)
```

#### Secrets 傳遞

當使用 `workflow_call` 調用其他 workflow 時，必須**明確傳遞 secrets**：

```yaml
jobs:
  provision-runner:
    uses: ./.gitea/workflows/provision_runner.yaml
    with:
      container_name: "k3s-deploy-${{ github.run_id }}"
    secrets:
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
      GITHUB_KEY: ${{ secrets.GITHUB_KEY }}
      RUNNER_TOKEN: ${{ secrets.RUNNER_TOKEN }}
      TOKEN: ${{ secrets.TOKEN }}
```

**重要**: 被調用的 workflow 必須在 `workflow_call` 事件中定義 `secrets` 輸入：

```yaml
on:
  workflow_call:
    inputs:
      container_name:
        required: true
        type: string
    secrets:
      SSH_PRIVATE_KEY:
        required: true
      RUNNER_TOKEN:
        required: true
```

### 相關檔案

- **主 Workflow**: [deploy_homelab_infra.yaml](./deploy_homelab_infra.yaml)
- **Runner Workflows**:
  - [provision_runner.yaml](./provision_runner.yaml)
  - [destory_runner.yaml](./destory_runner.yaml)
- **Secrets 配置**: [SECRETS.md](./SECRETS.md)
- **Single-Node 配置**: `../../infra/tofu/proxmox-k3s/environments/{env}/single-node/`
- **Multi-Node 配置**: `../../infra/tofu/proxmox-k3s/environments/{env}/multi-node/`
- **Multi-Node README**: `../../infra/tofu/proxmox-k3s/environments/dev/multi-node/README.md`
