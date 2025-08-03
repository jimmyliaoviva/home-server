# Rancher 容器管理平台

Rancher 是一個開源的容器管理平台，提供完整的 Kubernetes 管理解決方案。

## 功能特色

- 🚀 簡化 Kubernetes 集群管理
- 🔧 多集群管理和監控
- 🛡️ 內建安全性和 RBAC
- 📊 應用程式目錄和部署
- 🔍 集群監控和日誌管理

## 快速開始

### 1. 啟動服務

```bash
# 進入 rancher 目錄
cd app/rancher

# 啟動 Rancher 服務
docker-compose up -d
```

### 2. 訪問 Web 界面

- **HTTP**: http://localhost:8081
- **HTTPS**: https://localhost:8443

### 3. 初始設置

1. 首次訪問時，系統會要求您：
   - 設置管理員密碼
   - 確認 Rancher Server URL
   - 接受使用條款

2. 完成初始設置後：
   - 配置 SSL 證書（生產環境）
   - 設置用戶權限和角色

## 配置說明

### 環境變量

目前配置不使用環境變量，所有設置將在首次訪問時通過 Web 界面完成。

如需設置初始密碼，可添加：
```yaml
environment:
  - CATTLE_BOOTSTRAP_PASSWORD=your_password_here
```

### 端口配置

| 端口 | 協議 | 說明 |
|------|------|------|
| 8081 | HTTP | Web 管理界面 |
| 8443 | HTTPS | 安全 Web 管理界面 |

### 數據持久化

- **rancher-data**: 存儲 Rancher 的配置和數據
- 位置: Docker volume `rancher-data`

## 安全建議

### 🔒 生產環境配置

1. **設置強密碼**
   - 首次設置時使用強密碼（至少 12 字符，包含大小寫字母、數字和特殊字符）
   - 定期更換管理員密碼

2. **使用 HTTPS**
   - 配置有效的 SSL 證書
   - 禁用 HTTP 端口（移除 8081 端口映射）

3. **網路安全**
   - 使用防火牆限制訪問
   - 配置反向代理（如 Nginx）

4. **定期備份**
   ```bash
   # 備份 Rancher 數據
   docker run --rm -v rancher-data:/data -v $(pwd):/backup alpine tar czf /backup/rancher-backup-$(date +%Y%m%d).tar.gz -C /data .
   ```

## 常用命令

### 服務管理

```bash
# 啟動服務
docker-compose up -d

# 停止服務
docker-compose down

# 查看日誌
docker-compose logs -f rancher

# 重啟服務
docker-compose restart rancher
```

### 數據管理

```bash
# 查看數據卷
docker volume ls | grep rancher

# 備份數據
docker run --rm -v rancher-data:/data -v $(pwd):/backup alpine tar czf /backup/rancher-backup.tar.gz -C /data .

# 恢復數據
docker run --rm -v rancher-data:/data -v $(pwd):/backup alpine tar xzf /backup/rancher-backup.tar.gz -C /data
```

## 故障排除

### 常見問題

1. **無法訪問 Web 界面**
   - 檢查容器是否正常運行：`docker-compose ps`
   - 檢查端口是否被占用：`netstat -tulpn | grep 8081`

2. **忘記管理員密碼**
   - 停止容器並重新設置 `CATTLE_BOOTSTRAP_PASSWORD`
   - 刪除數據卷重新開始（會丟失所有數據）

3. **容器啟動失敗**
   - 檢查日誌：`docker-compose logs rancher`
   - 確保有足夠的系統資源

### 系統要求

- **最低配置**: 4GB RAM, 2 CPU cores
- **推薦配置**: 8GB RAM, 4 CPU cores
- **Docker**: 版本 20.10.x 或更高
- **Docker Compose**: 版本 1.29.x 或更高

## 更新升級

```bash
# 停止服務
docker-compose down

# 拉取最新鏡像
docker-compose pull

# 重新啟動
docker-compose up -d
```

## 相關連結

- [Rancher 官方文檔](https://rancher.com/docs/)
- [Rancher GitHub](https://github.com/rancher/rancher)
- [Kubernetes 文檔](https://kubernetes.io/docs/)

## 注意事項

⚠️ **重要提醒**:
- 首次設置時請使用強密碼
- 建議使用 HTTPS 並配置有效證書
- 定期備份 Rancher 數據
- 監控系統資源使用情況
