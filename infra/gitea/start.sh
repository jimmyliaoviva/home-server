#!/bin/bash

# Gitea with Actions Runner - 啟動腳本
# 此腳本用於啟動 Gitea 伺服器和 Actions Runner

# 檢查參數
if [ "$1" = "--restart-runner" ]; then
    echo "🔄 正在重啟 Actions Runner（保持 Gitea 運行）..."
    
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
    
    # 檢查 Gitea 是否正在運行
    if ! docker-compose ps | grep -q "server.*Up"; then
        echo "❌ 錯誤：Gitea 服務未運行，請先啟動完整服務"
        echo "使用: ./start.sh"
        exit 1
    fi
    
    # 停止並重啟 runner 服務
    echo "⏹️  停止 Actions Runner..."
    docker-compose stop runner
    docker-compose rm -f runner
    
    echo "🚀 重新啟動 Actions Runner..."
    docker-compose up -d runner
    
    # 等待服務啟動
    echo "⏳ 等待 Runner 啟動..."
    sleep 10
    
    # 檢查 Actions Runner 狀態
    echo "🤖 檢查 Actions Runner 狀態..."
    if docker-compose logs runner | grep -q "Connect to Gitea instance"; then
        echo "✅ Actions Runner 重啟成功並已連接到 Gitea"
    elif docker-compose logs runner | grep -q "registration token"; then
        echo "⚠️  Actions Runner 需要 Registration Token"
        echo "請檢查 .env 文件中的 REGISTRATION_TOKEN 設定"
    else
        echo "ℹ️  Actions Runner 狀態檢查中..."
        echo "如有問題，請查看日誌: docker-compose logs runner"
    fi
    echo "清理未使用的舊映像檔"
    docker image prune -f

    echo ""
    echo "🔧 管理命令："
    echo "   查看 Runner 日誌: docker-compose logs -f runner"
    echo "   查看所有日誌: docker-compose logs -f"
    echo "   重啟 Runner: ./start.sh --restart-runner"
    echo "   完整重啟: ./start.sh"
    echo ""
    
    exit 0
fi

echo "🚀 正在啟動 Gitea 和 Actions Runner 服務..."

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

# 檢查 .env 文件是否存在
if [ ! -f ".env" ]; then
    echo "⚠️  警告：找不到 .env 文件，請確保設定了 REGISTRATION_TOKEN"
    echo "建議創建 .env 文件並設定："
    echo "REGISTRATION_TOKEN=your_registration_token_here"
    read -p "是否繼續啟動？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 檢查必要目錄
echo "📁 檢查必要目錄..."
mkdir -p ./data
mkdir -p ./config
mkdir -p ./runner/data

# 檢查 runner/config.yaml 是否存在
if [ ! -f "./runner/config.yaml" ]; then
    echo "📝 創建 runner/config.yaml..."
    mkdir -p ./runner
    cat > ./runner/config.yaml << EOF
# Gitea Actions Runner Configuration
log:
  level: info

runner:
  file: .runner
  capacity: 1
  timeout: 3h
  insecure: false
  fetch_timeout: 5s
  fetch_interval: 2s

cache:
  enabled: true
  dir: ""
  host: ""
  port: 0

container:
  network: ""
  privileged: false
  options: ""
  workdir_parent: ""
  valid_volumes: []
  docker_host: ""

host:
  workdir_parent: ""
EOF
fi

# 停止現有容器（如果有）
echo "⏹️  停止現有容器..."
docker-compose down

# 清理舊的映像（可選）
if [ "$1" = "--clean" ]; then
    echo "🧹 清理舊的映像..."
    docker-compose down --rmi all
    docker system prune -f
fi

# 拉取最新映像並啟動服務
echo "📦 拉取最新映像並啟動服務..."
if [ "$1" = "--no-cache" ]; then
    echo "🔄 強制拉取最新映像..."
    docker-compose pull
fi

docker-compose up -d

# 等待服務啟動
echo "⏳ 等待服務啟動..."
sleep 15

# 檢查服務狀態
echo "🔍 檢查服務狀態..."
docker-compose ps

# 檢查 Gitea 服務是否正常運行
if docker-compose ps | grep -q "gitea.*Up"; then
    echo ""
    echo "✅ Gitea 服務啟動成功！"
    echo ""
    echo "🌐 訪問連結："
    echo "   Gitea Web:           http://localhost:4000"
    echo "   Gitea SSH:           ssh://git@localhost:2222"
    echo ""
    echo "📋 初始設定："
    echo "   1. 打開 http://localhost:4000 進行初始設定"
    echo "   2. 設定資料庫（建議使用 SQLite）"
    echo "   3. 創建管理員帳戶"
    echo "   4. 啟用 Actions 功能"
    echo ""
    echo "🔧 Actions Runner 設定："
    echo "   1. 進入 Gitea 管理面板 → Actions → Runners"
    echo "   2. 生成 Registration Token"
    echo "   3. 更新 .env 文件中的 REGISTRATION_TOKEN"
    echo "   4. 重啟服務: ./start.sh"
    echo ""
    echo "📖 更多資訊請參考 README.md"
    echo ""
else
    echo "❌ 服務啟動失敗！"
    echo "📋 查看日誌："
    docker-compose logs
    exit 1
fi

# 檢查 Actions Runner 狀態
echo "🤖 檢查 Actions Runner 狀態..."
sleep 5
if docker-compose logs runner | grep -q "Connect to Gitea instance"; then
    echo "✅ Actions Runner 已連接到 Gitea"
elif docker-compose logs runner | grep -q "registration token"; then
    echo "⚠️  Actions Runner 需要 Registration Token"
    echo "請參考上述說明設定 Registration Token"
else
    echo "ℹ️  Actions Runner 狀態檢查中..."
    echo "如有問題，請查看日誌: docker-compose logs runner"
fi

echo ""
echo "🔧 管理命令："
echo "   查看日誌: docker-compose logs -f"
echo "   停止服務: docker-compose down"
echo "   重啟服務: ./start.sh"
echo "   重啟 Runner: ./start.sh --restart-runner"
echo "   清理重啟: ./start.sh --clean"
echo ""
