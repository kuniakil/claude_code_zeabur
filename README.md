# Claude Code Zeabur Image

A Docker image for deploying Claude Code CLI on Zeabur with SSH access.

## Features

- **Debian Bookworm Slim** base (~80MB)
- **OpenSSH Server** bundled (passwordless key auth only)
- **Claude Code CLI** via official apt repository
- **Development tools**: git, build-essential, jq, vim, nano, bash
- **Non-root user** (claude) for SSH sessions
- **Named volume** at `/data` for persistent data

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SSH_AUTHORIZED_KEYS` | Yes | SSH public key for authentication |
| `ANTHROPIC_API_KEY` | Yes | Claude API key |

## Quick Start

### Local Testing with Docker Compose

```bash
# Create .env file
echo "SSH_AUTHORIZED_KEYS=$(cat ~/.ssh/id_rsa.pub)" > .env
echo "ANTHROPIC_API_KEY=your-key-here" >> .env

# Build and start
docker compose up -d

# SSH into container
ssh -i ~/.ssh/id_rsa claude@localhost -p 2222
```

### Manual Docker Run

```bash
docker run -d \
  --name claude-code \
  -p 2222:22 \
  -e SSH_AUTHORIZED_KEYS="ssh-rsa AAAA..." \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -v claude-data:/data \
  claude-code-zeabur
```

## Persistence

The `/data` directory is persisted via named volume. This stores:
- Claude Code settings and cache (`~/.claude`)
- Git repositories
- Project files

## Security

- Root SSH login disabled
- Password authentication disabled
- Key-only authentication via `SSH_AUTHORIZED_KEYS`

## Build

```bash
docker build -t claude-code-zeabur .