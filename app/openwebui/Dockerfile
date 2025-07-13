# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package management
RUN pip install uv

# Install mcpo directly from PyPI
RUN pip install mcpo

# Install Node.js packages globally for MCP servers
RUN npm install -g @modelcontextprotocol/server-memory 

# Copy custom MCP servers
COPY mcp-servers/ /app/mcp-servers/

# Make Python scripts executable
RUN chmod +x /app/mcp-servers/naver-map/*.py

# Install Python dependencies for custom MCP servers (optional)
# RUN cd /app/mcp-servers/naver-map && pip install -r requirements.txt 

# Create a non-root user for security
RUN useradd -m -u 1000 mcpo && chown -R mcpo:mcpo /app
USER mcpo

# Expose the default port
EXPOSE 8000

# Set default environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Default command - can be overridden
ENTRYPOINT ["mcpo"]
CMD ["--port", "8000", "--help"]
