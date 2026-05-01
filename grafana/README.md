# Grafana Dashboards

此目錄包含 Grafana 儀表板的 JSON 導出檔案。

## 儀表板列表

| Dashboard | UID | 描述 |
|-----------|-----|------|
| Node Exporter Full | `rYdddlPWk` | Linux 系統監控（CPU、記憶體、磁碟、網路） |
| Ovpn-Admin | `Z7qmFI0Gk` | OpenVPN 伺服器監控 |

## 如何匯入

### 方法 1: 使用 Grafana UI
1. 登入 Grafana
2. 點擊左側選單 → **Dashboards** → **Import**
3. 上傳 JSON 檔案
4. 點擊 **Import**

### 方法 2: 使用 API
```bash
curl -X POST -H "Authorization: Bearer $GRAFANA_API_KEY" \
  -H "Content-Type: application/json" \
  -d @dashboard-rYdddlPWk.json \
  https://grafana.jimmylab.duckdns.org/api/dashboards/db
```

## 自動同步

使用 provisioning 自動載入：
```yaml
# grafana/provisioning/dashboards/dashboards.yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
```

## 最後更新

**2026-05-02** - 初始版本，包含 2 個 dashboards
