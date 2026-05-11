# Claude Code Zeabur Image

A Docker image for deploying Claude Code CLI on Zeabur with SSH access.

## Features

- **Debian Bookworm Slim** base (~80MB)
- **OpenSSH Server** bundled (key auth only, root login enabled)
- **Claude Code CLI** via official installer
- **Development tools**: git, build-essential, jq, vim, nano, bash
- **Root user** for SSH sessions
- **Named volume** at `/data` for persistent data
- **MiniMax API** support (international endpoint)

## Important: SSH Environment Variable Issue

When accessing the container via SSH, Zeabur filters certain environment variables from the SSH session as a security measure. This includes `ANTHROPIC_AUTH_TOKEN` (and other credentials like `PASSWORD`, `SSH_AUTHORIZED_KEYS`).

**Workaround**: Create a `.env` file in `/data` with your credentials. SSH login will automatically source this file.

## Setup for SSH Access

### Step 1: Create `/data/.env` file

After deploying the container, use Zeabur's built-in terminal to create the credentials file:

```bash
cat > /data/.env << 'EOF'
ANTHROPIC_AUTH_TOKEN=your-minimax-api-key-here
EOF
```

### Step 2: SSH into the container

```bash
ssh -i ~/.ssh/your_key.pem root@<zeabur-ip>
```

The credentials will be automatically loaded from `/data/.env` on every SSH login.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SSH_AUTHORIZED_KEYS` | Yes | SSH public key for authentication |
| `ANTHROPIC_AUTH_TOKEN` | Via `/data/.env` | MiniMax API key |
| `ANTHROPIC_BASE_URL` | Yes | `https://api.minimax.io/anthropic` |
| `ANTHROPIC_MODEL` | Yes | `MiniMax-M2.7` |
| `API_TIMEOUT_MS` | No | API timeout (default: 300000) |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | No | Set to `1` to reduce traffic |

## Quick Start

### Local Testing with Docker Compose

```bash
# Create .env file
cp .env.example .env
# Edit .env with your SSH public key and MiniMax API key

# Build and start
docker compose up -d

# SSH into container as root
ssh -i ~/.ssh/id_rsa root@localhost -p 2222
```

### Manual Docker Run

```bash
docker run -d \
  --name claude-code \
  -p 2222:22 \
  -e SSH_AUTHORIZED_KEYS="ssh-rsa AAAA..." \
  -e ANTHROPIC_BASE_URL="https://api.minimax.io/anthropic" \
  -e ANTHROPIC_MODEL="MiniMax-M2.7" \
  -v claude-data:/data \
  claude-code-zeabur
```

## Persistence

The `/data` directory is persisted via named volume. This stores:
- Claude Code settings and cache (`~/.claude`)
- Git repositories
- Project files
- `.env` credentials file

## Security

- Password authentication disabled
- Key-only authentication via `SSH_AUTHORIZED_KEYS`
- Root login enabled (for convenience in containerized environments)
- Credentials stored in `/data/.env` bypass SSH environment filtering

## Build

```bash
docker build -t claude-code-zeabur .
```