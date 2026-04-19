# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies including Go
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    nodejs \
    npm \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Go
ENV GO_VERSION=1.21.5
RUN wget -O go.tar.gz "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"

# Install uv for fast Python package management
RUN pip install uv

# Install mcpo directly from PyPI
RUN pip install mcpo

# Install Node.js packages globally for MCP servers
RUN npm install -g @modelcontextprotocol/server-memory

# Create a non-root user for security
RUN useradd -m -u 1000 mcpo

# Terraform MCP server skipped - has replace directive issues
# Install manually if needed:
# RUN go install github.com/hashicorp/terraform-mcp-server/cmd/terraform-mcp-server@v0.4.0

# Copy custom MCP servers and set ownership
COPY mcp-servers/ /app/mcp-servers/
RUN chown -R mcpo:mcpo /app

# Install Python MCP servers using uvx (which comes with uv) for the mcpo user
# Pre-install commonly used MCP servers to avoid runtime installation delays
USER mcpo
RUN uv tool install mcp-server-time
RUN uv tool install awslabs.aws-documentation-mcp-server

# Ensure uvx is available in PATH for the mcpo user
ENV PATH="/home/mcpo/.local/bin:$PATH"

# Switch back to mcpo user
USER mcpo

# Expose the default port
EXPOSE 8000

# Set default environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Default command - can be overridden
ENTRYPOINT ["mcpo"]
CMD ["--port", "8000", "--help"]
