# Pull/Clone Repository Action

這是一個可重複使用的 Gitea Action，用於通過 SSH 將 repository 拉取或克隆到目標實例。

## 功能特性

- 🔄 支援三種操作模式：`pull`、`fresh_clone`、`force_update`
- 💾 可選擇性創建備份
- 🔐 自動設置文件權限
- 🚀 支援執行後置腳本
- 📊 提供詳細的輸出信息
- 🔗 自動 SSH 連接測試

## 輸入參數

| 參數 | 描述 | 必需 | 預設值 |
|------|------|------|--------|
| `target_server` | 目標伺服器 IP 地址或主機名 | ✅ | - |
| `repository_url` | 要克隆的 repository URL（留空使用當前 repo） | ❌ | `''` |
| `target_directory` | 遠端伺服器上的目標目錄 | ❌ | `~/repositories` |
| `branch` | 要檢出的分支 | ❌ | `main` |
| `clone_method` | 克隆方法 | ❌ | `pull` |
| `ssh_user` | SSH 用戶名 | ❌ | `jimmy` |
| `create_backup` | 更新前是否創建備份 | ❌ | `true` |
| `post_clone_script` | 克隆/拉取後執行的腳本 | ❌ | `''` |
| `permissions` | 設置目錄權限 | ❌ | `755` |
| `ssh_private_key` | SSH 私鑰 | ✅ | - |

## 克隆方法說明

### `pull`
- 適用於已存在的 repository
- 執行 `git pull` 更新現有代碼
- 如果 repository 不存在會失敗

### `fresh_clone`
- 完全重新克隆 repository
- 會刪除現有目錄（如果存在）
- 適用於首次部署或需要完全重置

### `force_update`
- 強制更新，丟棄本地更改
- 執行 `git reset --hard` 和 `git clean -fd`
- 適用於有本地修改需要強制覆蓋的情況

## 輸出參數

| 參數 | 描述 |
|------|------|
| `repository_path` | 克隆/拉取的 repository 完整路徑 |
| `repository_name` | Repository 名稱 |
| `commit_hash` | 最新提交的 hash |
| `branch_name` | 當前分支名稱 |

## 使用範例

### 基本使用

```yaml
- name: Pull repository to target server
  uses: ./.gitea/workflows/actions/pull_repo.yaml
  with:
    target_server: '192.168.1.100'
    ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
```

### 完整配置

```yaml
- name: Deploy to production server
  id: deploy
  uses: ./.gitea/workflows/actions/pull_repo.yaml
  with:
    target_server: 'prod.example.com'
    target_directory: '/var/www/html'
    branch: 'production'
    clone_method: 'force_update'
    ssh_user: 'deploy'
    create_backup: 'true'
    permissions: '644'
    ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
    post_clone_script: |
      npm install
      npm run build
      sudo systemctl restart nginx

- name: Show deployment info
  run: |
    echo "Deployed to: ${{ steps.deploy.outputs.repository_path }}"
    echo "Commit: ${{ steps.deploy.outputs.commit_hash }}"
```

### 克隆外部 repository

```yaml
- name: Clone external repository
  uses: ./.gitea/workflows/actions/pull_repo.yaml
  with:
    target_server: '192.168.1.100'
    repository_url: 'https://github.com/user/repo.git'
    target_directory: '/opt/external-repos'
    branch: 'develop'
    clone_method: 'fresh_clone'
    ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
```

## 必要設置

### 1. SSH 私鑰設置

在 Gitea repository 的 Settings > Secrets 中添加：
- `SSH_PRIVATE_KEY`: SSH 私鑰內容

### 2. 目標伺服器設置

確保目標伺服器：
- 已安裝 Git
- SSH 服務正在運行
- 用戶有適當的權限訪問目標目錄
- 公鑰已添加到 `~/.ssh/authorized_keys`

### 3. 網路連接

確保 Gitea runner 可以通過 SSH 連接到目標伺服器。

## 故障排除

### SSH 連接失敗
- 檢查 SSH 私鑰是否正確
- 確認目標伺服器 SSH 服務狀態
- 驗證網路連接

### Git 操作失敗
- 確認目標伺服器已安裝 Git
- 檢查 repository URL 是否正確
- 驗證分支名稱是否存在

### 權限問題
- 確認 SSH 用戶有目標目錄的寫入權限
- 檢查 `permissions` 參數設置

## 安全注意事項

- 🔐 SSH 私鑰應存儲在 Gitea Secrets 中
- 🛡️ 建議使用專用的部署用戶，限制其權限
- 🔒 定期輪換 SSH 密鑰
- 📝 審查 `post_clone_script` 內容，避免執行危險命令

## 版本歷史

- v1.0.0: 初始版本，支援基本的拉取和克隆功能
