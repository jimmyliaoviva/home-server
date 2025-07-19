# Gitea with Actions Runner

這是一個完整的 Gitea 服務設置，包含 Gitea 伺服器和 Actions Runner，提供完整的 Git 託管和 CI/CD 功能。

## 服務概述

### Gitea Server
- **功能**: 自託管的 Git 服務，類似 GitHub
- **版本**: 1.24.3-rootless (安全的非 root 運行)
- **端口**: 4000 (Web), 2222 (SSH)

### Gitea Actions Runner
- **功能**: 執行 CI/CD 工作流程
- **版本**: nightly
- **標籤**: n100

## 快速開始

### 1. 環境準備

創建 `.env` 文件：
```bash
cp .env.example .env
# 編輯 .env 文件
```

### 2. 啟動服務

```bash
# 使用啟動腳本
./start.sh

# 或直接使用 docker-compose
docker-compose up -d
```

### 3. 初始設定

1. **訪問 Gitea Web 界面**
   ```
   http://localhost:4000
   ```

2. **完成初始設定**
   - 資料庫類型：SQLite（推薦）或 PostgreSQL/MySQL
   - 服務設定：
     - SSH 服務域名：`localhost`
     - SSH 端口：`2222`
     - HTTP 端口：`3000`（容器內部）
     - 應用 URL：`http://localhost:4000/`

3. **創建管理員帳戶**
   - 設定管理員用戶名、密碼和 Email

4. **啟用 Actions 功能**
   - 進入 Site Administration → Actions
   - 啟用 "Enable Actions"

## Actions Runner 設定

### 1. 生成 Registration Token

1. 登入 Gitea 管理員帳戶
2. 進入 Site Administration → Actions → Runners
3. 點擊 "Create new Runner"
4. 複製生成的 Registration Token

### 2. 配置 Runner

1. 編輯 `.env` 文件：
   ```env
   REGISTRATION_TOKEN=your_generated_token_here
   ```

2. 重啟服務：
   ```bash
   ./start.sh
   ```

### 3. 驗證 Runner

在 Gitea Web 界面的 Actions → Runners 頁面應該能看到已連接的 Runner。

## 目錄結構

```
gitea/
├── docker-compose.yml      # Docker Compose 配置
├── start.sh               # 啟動腳本
├── .env                   # 環境變數（需要創建）
├── .env.example           # 環境變數範例
├── README.md              # 本文件
├── data/                  # Gitea 資料目錄
├── config/                # Gitea 配置目錄
└── runner/
    ├── config.yaml        # Runner 配置文件
    └── data/             # Runner 資料目錄
```

## 環境變數

創建 `.env` 文件並設定以下變數：

```env
# Gitea Actions Runner Registration Token
# 從 Gitea Web 界面的 Actions → Runners 頁面取得
REGISTRATION_TOKEN=your_registration_token_here
```

## 配置文件

### Runner Configuration (`runner/config.yaml`)

Runner 的詳細配置，包含：
- 日誌等級設定
- Runner 容量和超時設定
- 快取配置
- 容器執行選項

## 網路配置

服務使用預設的 Docker 網路進行內部通信：
- Gitea Server 容器名稱: `gitea-server`
- Actions Runner 容器名稱: `gitea-runner`
- 內部通信端口: `3000` (Gitea Server)

## 端口映射

| 服務 | 容器端口 | 主機端口 | 用途 |
|------|----------|----------|------|
| Gitea Server | 3000 | 4000 | Web 界面 |
| Gitea Server | 2222 | 2222 | SSH Git 操作 |

## 數據持久化

- **Gitea 資料**: 存儲在 `./data` 目錄
- **Gitea 配置**: 存儲在 `./config` 目錄  
- **Runner 資料**: 存儲在 `./runner/data` 目錄

## 使用示例

### 創建第一個倉庫

1. 登入 Gitea Web 界面
2. 點擊 "+" → "New Repository"
3. 設定倉庫名稱和描述
4. 選擇是否為私有倉庫

### 設定 Actions 工作流程

在倉庫中創建 `.gitea/workflows/ci.yml`：

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: n100
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          echo "Running tests..."
          # 您的測試命令
```

### SSH 操作

```bash
# 設定 Git 配置
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 克隆倉庫
git clone ssh://git@localhost:2222/username/repository.git

# 或使用 HTTPS
git clone http://localhost:4000/username/repository.git
```

## 常用命令

```bash
# 啟動所有服務
./start.sh

# 清理並重新啟動
./start.sh --clean

# 強制拉取最新映像
./start.sh --no-cache

# 查看服務狀態
docker-compose ps

# 查看日誌
docker-compose logs -f

# 查看特定服務日誌
docker-compose logs -f server
docker-compose logs -f runner

# 停止服務
docker-compose down

# 進入容器
docker-compose exec server sh
docker-compose exec runner sh

# 備份資料
tar -czf gitea-backup-$(date +%Y%m%d).tar.gz data/ config/
```

## 故障排除

### 1. Runner 無法連接到 Gitea

**症狀**: Runner 日誌顯示連接錯誤

**解決方案**:
- 檢查 `REGISTRATION_TOKEN` 是否正確
- 確認 Gitea 服務已啟動且可訪問
- 檢查 `GITEA_INSTANCE_URL` 配置

### 2. SSH 連接失敗

**症狀**: `git clone` 使用 SSH 失敗

**解決方案**:
- 確認 SSH 公鑰已添加到 Gitea 用戶設定
- 檢查端口 2222 是否開放
- 使用 `ssh -T git@localhost -p 2222` 測試連接

### 3. Web 界面無法訪問

**症狀**: 無法訪問 `http://localhost:4000`

**解決方案**:
- 檢查容器是否正常運行: `docker-compose ps`
- 檢查端口是否被占用: `netstat -an | grep 4000`
- 查看容器日誌: `docker-compose logs server`

### 4. Actions 工作流程失敗

**症狀**: Actions 無法執行或失敗

**解決方案**:
- 確認 Runner 已註冊且在線
- 檢查工作流程文件語法
- 查看 Runner 日誌: `docker-compose logs runner`

## 安全注意事項

1. **定期更新**: 定期更新 Gitea 版本以獲得安全修補
2. **備份策略**: 定期備份 `data/` 和 `config/` 目錄
3. **訪問控制**: 在生產環境中使用反向代理和 SSL/TLS
4. **密碼策略**: 使用強密碼和雙因素認證
5. **網路安全**: 限制不必要的端口訪問

## 升級指南

```bash
# 1. 備份資料
./backup.sh

# 2. 停止服務
docker-compose down

# 3. 更新映像版本
# 編輯 docker-compose.yml 中的版本號

# 4. 拉取新映像
docker-compose pull

# 5. 啟動服務
./start.sh
```

## 參考資源

- [Gitea 官方文檔](https://docs.gitea.io/)
- [Gitea Actions 文檔](https://docs.gitea.io/en-us/next/usage/actions/overview/)
- [Docker Compose 文檔](https://docs.docker.com/compose/)

## 授權

本項目遵循 Gitea 的開源授權條款。
