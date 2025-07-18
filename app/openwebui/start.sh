#!/bin/bash

# Open WebUI with MCPO - 啟動腳本
# 此腳本用於啟動 Open WebUI 和 MCPO 服務

echo "🚀 正在啟動 Open WebUI 和 MCPO 服務..."

# 檢查 Docker 是否運行
if ! docker info > /dev/null 2>&1; then
    echo "❌ 錯誤：Docker 未運行，請先啟動 Docker"
    exit 1
fi

# 檢查 docker-compose.yml 是否存在
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 錯誤：找不到 docker-compose.yml 文件"
    exit 1
fi

# 檢查 mcpo-config.json 是否存在
if [ ! -f "mcpo-config.json" ]; then
    echo "❌ 錯誤：找不到 mcpo-config.json 文件"
    exit 1
fi

# 檢查 Dockerfile 是否存在
if [ ! -f "Dockerfile" ]; then
    echo "❌ 錯誤：找不到 Dockerfile 文件"
    exit 1
fi

# 創建必要的目錄
echo "📁 創建必要的目錄..."
mkdir -p ./data

# 停止現有容器（如果有）
echo "⏹️  停止現有容器..."
docker-compose down

# 清理舊的映像（可選）
if [ "$1" = "--clean" ]; then
    echo "🧹 清理舊的映像..."
    docker-compose down --rmi all
    docker system prune -f
fi

# 重新 build 並啟動服務
echo "🔨 Build 並啟動服務..."
if [ "$1" = "--no-cache" ]; then
    echo "📦 使用 --no-cache 重新 build..."
    docker-compose build --no-cache
    docker-compose up -d
else
    docker-compose up -d --build
fi

# 等待服務啟動
echo "⏳ 等待服務啟動..."
sleep 10

# 檢查服務狀態
echo "🔍 檢查服務狀態..."
docker-compose ps

# 檢查服務是否正常運行
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "✅ 服務啟動成功！"
    echo ""
    echo "🌐 訪問連結："
    echo "   Open WebUI:          http://localhost:3000"
    echo "   MCPO API:            http://localhost:8000"
    echo "   MCPO 文檔:           http://localhost:8000/docs"
    echo ""
    echo "📋 可用的 MCP 服務："
    echo "   Memory Server:       http://localhost:8000/memory"
    echo "   Time Server:         http://localhost:8000/time"
    echo "   AWS Documentation:   http://localhost:8000/awslabs.aws-documentation-mcp-server"
    echo "   Terraform Server:    http://localhost:8000/terraform"
    echo ""
    echo "📖 使用說明："
    echo "   1. 打開 http://localhost:3000 訪問 Open WebUI"
    echo "   2. 在設定中配置 API keys"
    echo "   3. 在 Functions 中添加 MCPO 服務"
    echo ""
    echo "🔧 管理命令："
    echo "   查看日誌: docker-compose logs -f"
    echo "   停止服務: docker-compose down"
    echo "   重啟服務: ./start.sh"
    echo ""
else
    echo "❌ 服務啟動失敗！"
    echo "📋 查看日誌："
    docker-compose logs
    exit 1
fi
