# Open WebUI 連接 MCPO 快速設定指南

## 步驟 1: 啟動服務

```bash
# 確保 .env 文件中有以下設定
OPENAI_API_KEY=your_openai_api_key
MCPO_API_KEY=top-secret

# 啟動服務
docker-compose up -d --build
```

## 步驟 2: 驗證 MCPO 運行正常

1. 打開瀏覽器訪問 http://localhost:8000
2. 檢查是否能看到 MCPO 的歡迎頁面
3. 訪問 http://localhost:8000/memory/docs 檢查 Memory 服務
4. 訪問 http://localhost:8000/time/docs 檢查 Time 服務

## 步驟 3: 在 Open WebUI 中配置 MCPO

1. **打開 Open WebUI**
   - 訪問 http://localhost:3000
   - 如果是第一次使用，創建管理員帳戶

2. **進入設定頁面**
   - 點擊右上角的設定圖示 (齒輪)
   - 選擇 "Admin Panel"

3. **啟用 Function Calling**
   - 進入 "Settings" → "Functions"
   - 開啟 "Enable Function Calling"
   - 點擊 "Save"

4. **添加 OpenAPI 伺服器**
   - 進入 "Settings" → "Connections"
   - 滾動到 "OpenAPI Servers" 部分
   - 點擊 "Add OpenAPI Server"

5. **配置 Memory 服務**
   ```
   Name: MCPO Memory
   URL: http://mcpo:8000/memory
   API Key: Bearer top-secret
   ```
   點擊 "Save"

6. **配置 Time 服務**
   ```
   Name: MCPO Time
   URL: http://mcpo:8000/time
   API Key: Bearer top-secret
   ```
   點擊 "Save"

7. **配置 Naver Map 服務**
   ```
   Name: MCPO Naver Map
   URL: http://mcpo:8000/naver-map
   API Key: Bearer top-secret
   ```
   點擊 "Save"

## 步驟 4: 測試連接

1. **創建新對話**
   - 在 Open WebUI 中開始新對話
   - 確認在模型選擇器中能看到 MCPO 的功能

2. **測試 Memory 功能**
   ```
   請幫我記住這個資訊：我的名字是 Jimmy，我喜歡寫程式。
   ```

3. **測試 Time 功能**
   ```
   現在是幾點？今天是星期幾？
   ```

4. **測試 Naver Map 功能**
   ```
   서울역에서 강남역까지 지하철로 가는 길을 알려주세요.
   ```
   
   ```
   홍대 맛집을 찾아주세요.
   ```
   
   ```
   강남역 주변 카페를 찾아주세요.
   ```

## 故障排除

### 問題 1: 無法連接到 MCPO
- 檢查容器是否正在運行：`docker-compose ps`
- 檢查容器日誌：`docker-compose logs mcpo`
- 確認兩個服務在同一個網路中

### 問題 2: API 金鑰錯誤
- 檢查 .env 文件中的 MCPO_API_KEY 設定
- 確認在 Open WebUI 中使用的是 `Bearer top-secret` 格式

### 問題 3: 功能無法使用
- 檢查 Open WebUI 的 Function Calling 是否已啟用
- 確認 OpenAPI 伺服器的 URL 使用 `http://mcpo:8000` 而不是 `localhost:8000`

## 重要提示

1. **容器網路**：在 Docker 網路中，使用容器名稱 `mcpo` 而不是 `localhost`
2. **API 金鑰**：確保格式為 `Bearer your_api_key`
3. **服務依賴**：Open WebUI 設定為依賴 MCPO，會等待 MCPO 啟動完成
