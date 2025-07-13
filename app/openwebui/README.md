# Open WebUI with M2. **Access the Interfaces**
   - Open WebUI: http://localhost:3000
   - MCPO API: http://localhost:8000
   - MCPO Documentation: http://localhost:8000/docs

3. **Configure API Keys in Open WebUI**
   - Open http://localhost:3000 in your browser
   - Go to Settings (gear icon) → Admin Panel → Settings → Models
   - Add your OpenAI API key or other model provider API keys directly in the interface

4. **Configure Open WebUI to connect to MCPO**
This setup includes both Open WebUI and MCPO (MCP-to-OpenAPI proxy) services.

## Services

### Open WebUI
Open WebUI is a user-friendly web interface for AI language models, providing an intuitive chat experience similar to ChatGPT.

### MCPO
MCPO is a simple, secure MCP-to-OpenAPI proxy server that exposes any MCP tool as an OpenAPI-compatible HTTP server.

## Quick Start

1. **Start the Services**
   ```bash
   docker-compose up -d
   ```

3. **Access the Interfaces**
   - Open WebUI: http://localhost:3000
   - MCPO API: http://localhost:8000
   - MCPO Documentation: http://localhost:8000/docs

4. **Configure Open WebUI to connect to MCPO**
   - Go to Settings (gear icon) → Admin Panel → Settings → Functions
   - Enable "Enable Function Calling"
   - Go to Settings → Functions → Add Function
   - Add the following OpenAPI servers:

## MCPO Integration with Open WebUI

### Method 1: Using OpenAPI Functions

1. **在 Open WebUI 中添加 OpenAPI 功能**：
   - 登入 Open WebUI (http://localhost:3000)
   - 點擊右上角的設定圖示
   - 進入 "Admin Panel" → "Settings" → "Functions"
   - 啟用 "Enable Function Calling"

2. **添加 MCPO 服務**：
   - 進入 "Functions" 頁面
   - 點擊 "Add Function"
   - 選擇 "Import from OpenAPI"
   - 輸入以下 URL：

   ```
   Memory Server: http://mcpo:8000/memory
   Time Server: http://mcpo:8000/time
   ```

   **注意**：在 Docker 網路中，使用容器名稱 `mcpo` 而不是 `localhost`

3. **設定 API 金鑰**：
   - 在每個函數設定中，添加 Authentication
   - 選擇 "API Key" 認證類型
   - Header Name: `Authorization`
   - API Key: `Bearer top-secret` (使用預設的 MCPO API key)

### Method 2: Using OpenAPI Servers

1. **在 Open WebUI 中添加 OpenAPI 伺服器**：
   - 進入 Settings → Admin Panel → Settings → Connections
   - 找到 "OpenAPI Servers" 部分
   - 點擊 "Add OpenAPI Server"
   - 添加以下伺服器：

   ```
   Name: MCPO Memory
   URL: http://mcpo:8000/memory
   API Key: Bearer top-secret
   
   Name: MCPO Time  
   URL: http://mcpo:8000/time
   API Key: Bearer top-secret
   ```

## Configuration

### MCPO Features

- **MCP-to-OpenAPI Proxy**: Converts MCP servers to OpenAPI-compatible HTTP endpoints
- **Auto-generated Documentation**: Interactive API docs available at `/docs`
- **Security**: Built-in API key authentication
- **Multiple Server Support**: Can proxy multiple MCP servers simultaneously

### Default MCP Servers

The configuration includes multiple MCP servers:

1. **Memory Server** (`/memory`) - Provides persistent memory capabilities
2. **Time Server** (`/time`) - Provides time-related tools with Asia/Taipei timezone

Each server is accessible at:
- http://localhost:8000/memory
- http://localhost:8000/time

Interactive documentation for each server:
- http://localhost:8000/memory/docs
- http://localhost:8000/time/docs

### MCP Configuration

The MCP servers are configured in `mcpo-config.json`. You can modify this file to add, remove, or configure different MCP servers according to your needs.

## Supported Models

Open WebUI supports various AI models including:
- OpenAI GPT models (GPT-3.5, GPT-4, etc.)
- Local models via Ollama
- Other OpenAI-compatible APIs

## Data Persistence

- **Open WebUI**: All user data, chat history, and configurations are stored in the `open-webui` Docker volume
- **MCPO**: Runs stateless, no data persistence required

## Useful Commands

```bash
# Start all services
docker-compose up -d

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f open-webui
docker-compose logs -f mcpo

# Stop all services
docker-compose down

# Rebuild and start services
docker-compose up -d --build

# Update to latest versions
docker-compose pull
docker-compose up -d --build
```

## MCPO Usage Examples

### Basic Usage
```bash
# Access MCPO API
curl -H "Authorization: Bearer your_mcpo_api_key" http://localhost:8000/

# View interactive documentation
# Open http://localhost:8000/docs in your browser
```

### Custom MCP Server Configuration

To modify MCP servers, edit the `mcpo-config.json` file:

```json
{
  "mcpServers": {
    "your-server-name": {
      "command": "your-command",
      "args": ["arg1", "arg2"]
    }
  }
}
```

After modifying the configuration, restart the services:

```bash
docker-compose down
docker-compose up -d --build
```

### Available MCP Servers

Popular MCP servers you can add to your configuration:

- `@modelcontextprotocol/server-memory` - Persistent memory
- `@modelcontextprotocol/server-filesystem` - File operations
- `@modelcontextprotocol/server-brave-search` - Web search
- `@modelcontextprotocol/server-sqlite` - Database operations
- `@modelcontextprotocol/server-github` - GitHub integration
- `@modelcontextprotocol/server-slack` - Slack integration
- `mcp-server-time` - Time and date utilities

## Troubleshooting

1. **Cannot connect to API**: Configure your API keys directly in Open WebUI Settings → Admin Panel → Settings → Models
2. **Port conflict**: Change the port mapping in `docker-compose.yml` if port 3000 is already in use
3. **Data loss**: Ensure the volume is properly configured and not accidentally deleted

## Security Notes

- API keys are configured directly in Open WebUI interface for better security
- Use strong passwords for admin accounts
- Consider using a reverse proxy with SSL/TLS for production deployments

## Links

- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Official Documentation](https://docs.openwebui.com/)
