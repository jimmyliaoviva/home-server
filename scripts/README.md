# K3s and Rancher Installation Scripts

這個目錄包含了在 Linux 環境下安裝 K3s 和 Rancher 的腳本，基於 SUSE Rancher 官方文檔製作。

## 文件說明

### 安裝腳本

1. **`install-k3s.sh`** - 完整的 K3s 安裝腳本，包含 Rancher 準備步驟
2. **`install-k3s-simple.sh`** - 簡化版 K3s 安裝腳本，僅安裝 K3s
3. **`install-rancher.sh`** - Rancher 安裝腳本，需要先安裝 K3s

### 配置文件

4. **`k3s-config.yaml`** - K3s 配置文件範例

## 使用方法

### 方法一：完整安裝（推薦）

使用完整的安裝腳本，一次性安裝 K3s 並準備 Rancher 環境：

```bash
# 下載腳本
wget https://raw.githubusercontent.com/your-repo/scripts/install-k3s.sh
chmod +x install-k3s.sh

# 安裝最新版本的 K3s
./install-k3s.sh

# 安裝特定版本的 K3s
./install-k3s.sh --version v1.28.2+k3s1

# 跳過 Rancher 準備步驟
./install-k3s.sh --skip-rancher-prep
```

### 方法二：簡化安裝

如果只需要安裝 K3s：

```bash
# 下載腳本
wget https://raw.githubusercontent.com/your-repo/scripts/install-k3s-simple.sh
chmod +x install-k3s-simple.sh

# 安裝 K3s
./install-k3s-simple.sh
```

### 方法三：分步安裝

先安裝 K3s，再安裝 Rancher：

```bash
# 1. 安裝 K3s
./install-k3s-simple.sh

# 2. 安裝 Rancher
./install-rancher.sh --hostname rancher.example.com --password mypassword123

# 使用 sslip.io 域名（適合測試）
./install-rancher.sh --hostname 192.168.1.100.sslip.io --password mypassword123

# 安裝特定版本的 Rancher
./install-rancher.sh --hostname rancher.example.com --password mypassword123 --rancher-version 2.7.5
```

## 系統需求

### 最低硬體需求
- **記憶體**: 至少 512MB 可用記憶體
- **磁碟空間**: 至少 1GB 可用空間
- **CPU**: 1 核心

### 軟體需求
- **作業系統**: Linux (Ubuntu, CentOS, RHEL, SLES 等)
- **網路**: 能夠訪問網際網路下載安裝包
- **權限**: 具有 sudo 權限的使用者

### 必要工具
- `curl` - 用於下載安裝腳本
- `systemctl` - 用於管理服務

## 安裝後驗證

### 驗證 K3s 安裝

```bash
# 檢查 K3s 服務狀態
sudo systemctl status k3s

# 檢查節點狀態
kubectl get nodes

# 檢查系統 Pod
kubectl get pods -A

# 檢查叢集資訊
kubectl cluster-info
```

### 驗證 Rancher 安裝

```bash
# 檢查 Rancher Pod 狀態
kubectl -n cattle-system get pods

# 檢查 Rancher 服務
kubectl -n cattle-system get svc

# 檢查 Ingress
kubectl -n cattle-system get ingress

# 查看 Rancher 日誌
kubectl -n cattle-system logs -l app=rancher
```

## 常用操作

### K3s 管理

```bash
# 啟動 K3s
sudo systemctl start k3s

# 停止 K3s
sudo systemctl stop k3s

# 重啟 K3s
sudo systemctl restart k3s

# 查看 K3s 日誌
sudo journalctl -u k3s -f

# 卸載 K3s
/usr/local/bin/k3s-uninstall.sh
```

### Rancher 管理

```bash
# 重啟 Rancher
kubectl -n cattle-system rollout restart deploy/rancher

# 查看 Rancher 狀態
kubectl -n cattle-system rollout status deploy/rancher

# 更新 Rancher
helm upgrade rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=your-hostname \
  --set bootstrapPassword=your-password
```

## 自定義配置

### 使用配置文件

將 `k3s-config.yaml` 複製到 `/etc/rancher/k3s/config.yaml` 並根據需要修改：

```bash
sudo mkdir -p /etc/rancher/k3s
sudo cp k3s-config.yaml /etc/rancher/k3s/config.yaml
sudo nano /etc/rancher/k3s/config.yaml
```

### 常見配置選項

```yaml
# 禁用某些組件
disable:
  - traefik        # 禁用 Traefik Ingress Controller
  - servicelb      # 禁用 Service Load Balancer
  - metrics-server # 禁用 Metrics Server

# 自定義網路設定
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"

# 添加 TLS SAN
tls-san:
  - "your-domain.com"
  - "192.168.1.100"
```

## 故障排除

### 常見問題

1. **K3s 啟動失敗**
   ```bash
   # 檢查日誌
   sudo journalctl -u k3s -f
   
   # 檢查系統資源
   free -h
   df -h
   ```

2. **kubectl 無法連接**
   ```bash
   # 檢查 kubeconfig
   export KUBECONFIG=~/.kube/config
   kubectl get nodes
   
   # 重新配置 kubeconfig
   sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
   sudo chown $(id -u):$(id -g) ~/.kube/config
   ```

3. **Rancher 無法訪問**
   ```bash
   # 檢查 Pod 狀態
   kubectl -n cattle-system get pods
   
   # 檢查服務
   kubectl -n cattle-system get svc
   
   # 檢查 Ingress
   kubectl -n cattle-system get ingress
   ```

4. **證書問題**
   ```bash
   # 檢查 cert-manager
   kubectl -n cert-manager get pods
   
   # 重新安裝 cert-manager
   kubectl delete namespace cert-manager
   # 然後重新運行安裝腳本
   ```

### 日誌查看

```bash
# K3s 日誌
sudo journalctl -u k3s -f

# Rancher 日誌
kubectl -n cattle-system logs -l app=rancher -f

# cert-manager 日誌
kubectl -n cert-manager logs -l app.kubernetes.io/instance=cert-manager -f
```

## 安全注意事項

1. **密碼要求**
   - Rancher 管理員密碼至少 12 個字符
   - 建議使用強密碼，包含大小寫字母、數字和特殊字符

2. **網路安全**
   - 確保防火牆配置正確
   - 限制對 Kubernetes API 的訪問
   - 使用有效的 TLS 證書（生產環境）

3. **定期更新**
   - 定期更新 K3s 和 Rancher 到最新版本
   - 監控安全公告和漏洞報告

## 生產環境建議

1. **高可用性設置**
   ```bash
   # 多節點 K3s 叢集
   curl -sfL https://get.k3s.io | K3S_TOKEN=SECRET sh -s - server \
     --cluster-init \
     --tls-san your-load-balancer-ip
   ```

2. **外部資料庫**
   ```bash
   # 使用外部 MySQL/PostgreSQL
   curl -sfL https://get.k3s.io | sh -s - server \
     --datastore-endpoint="mysql://username:password@tcp(hostname:3306)/database"
   ```

3. **負載均衡器**
   - 使用 HAProxy、Nginx 或雲端負載均衡器
   - 配置健康檢查

4. **備份策略**
   ```bash
   # 備份 etcd
   sudo k3s etcd-snapshot save
   
   # 備份配置文件
   sudo cp -r /etc/rancher /backup/
   ```

## 支援的 Kubernetes 版本

根據 [Rancher 支援矩陣](https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/)，確保使用支援的 Kubernetes 版本。

常用版本：
- K3s v1.28.x
- K3s v1.27.x
- K3s v1.26.x

## 參考資源

- [SUSE Rancher 官方文檔](https://documentation.suse.com/cloudnative/rancher-manager/latest/)
- [K3s 官方文檔](https://docs.k3s.io/)
- [Helm 官方文檔](https://helm.sh/docs/)
- [cert-manager 文檔](https://cert-manager.io/docs/)

## 授權

這些腳本基於 SUSE Rancher 官方文檔製作，遵循相應的開源授權條款。
