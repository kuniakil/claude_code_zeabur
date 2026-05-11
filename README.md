# Claude Code Zeabur Image

A Docker image for deploying Claude Code CLI on Zeabur with SSH access.

<!-- force rebuild -->

## Features

- **Node.js 20 on Debian Bookworm** base
- **OpenSSH Server** bundled (key auth only, root login enabled)
- **Claude Code CLI** via official installer
- **Happy CLI** for mobile/browser remote control (port 3005)
- **Development tools**: git, build-essential, jq, vim, nano, bash
- **Root user** for SSH sessions
- **Named volume** at `/data` for persistent data
- **Homebrew** pre-installed to `/root/.linuxbrew` for package management
- **npm global packages** pre-installed to `/data/npm-global` for persistent npm packages
- **Bun** pre-installed to `/data/bun` for persistent Bun runtime
- **MiniMax API** support (international endpoint)

## Ports

| Port | Service |
|------|---------|
| 22 | SSH |
| 3005 | Happy CLI (mobile/web remote control) |

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

## Using Happy (Mobile Remote Control)

### Step 1: Expose port 3005 in Zeabur

In Zeabur dashboard, expose port 3005 for the Happy CLI.

### Step 2: Start Happy session

SSH into the container and run:

```bash
happy claude
```

This will display a QR code. Scan it with the Happy mobile app to connect.

### Step 3: Alternative - Normal Claude Code

If you don't want mobile control, just use Claude Code directly via SSH:

```bash
claude
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SSH_AUTHORIZED_KEYS` | Yes | SSH public key for authentication |
| `ANTHROPIC_AUTH_TOKEN` | Via `/data/.env` | MiniMax API key |
| `ANTHROPIC_BASE_URL` | Yes | `https://api.minimax.io/anthropic` |
| `ANTHROPIC_MODEL` | Yes | `MiniMax-M2.7` |
| `API_TIMEOUT_MS` | No | API timeout (default: 300000) |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | No | Set to `1` to reduce traffic |

## Using Homebrew

Homebrew is installed to `/data/linuxbrew` so packages persist across container restarts.

```bash
# Install a package
brew install wget

# List installed packages
brew list

# Update packages
brew update
```

Packages installed via Homebrew will be available in SSH sessions and persist across redeployments.

## Using npm Global Packages

npm global packages are installed to `/data/npm-global` so they persist across container restarts.

```bash
# Install a global npm package
npm install -g happy

# List global npm packages
npm list -g

# Update packages
npm update -g
```

## Using Bun

Bun is installed to `/data/bun` so it persists across container restarts.

```bash
# Check Bun version
bun --version

# Run a script
bun run script.ts

# Install dependencies
bun install
```

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
  -p 3005:3005 \
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