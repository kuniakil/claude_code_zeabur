#!/bin/bash
set -e

# Inject SSH public key from environment variable (Zeabur Dashboard)
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    mkdir -p /root/.ssh
    echo "$SSH_AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
fi

# Persist Claude Code data to named volume
mkdir -p /data/.claude
export CLAUDE_DATA_DIR=/data/.claude

# Add Claude Code to PATH
export PATH="/root/.local/bin:$PATH"

# Source .env from persistent volume if it exists
if [ -f /data/.env ]; then
    set -a
    source /data/.env
    set +a
fi

# Write SSH environment setup - sources /data/.env on every login
cat > /root/.bashrc_env << 'BASHRC_EOF'
# Source .env from persistent volume
if [ -f /data/.env ]; then
    set -a
    source /data/.env
    set +a
fi

# Set defaults
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.minimax.io/anthropic}"
export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-MiniMax-M2.7}"
export API_TIMEOUT_MS="${API_TIMEOUT_MS:-300000}"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:-1}"
export PATH="/root/.local/bin:$PATH"
BASHRC_EOF

# Prepend to .bashrc
if ! grep -q ".bashrc_env" /root/.bashrc 2>/dev/null; then
    echo "source /root/.bashrc_env" >> /root/.bashrc
fi

# Write settings.json with token if ANTHROPIC_AUTH_TOKEN is set
if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
    mkdir -p /root/.claude
    cat > /root/.claude/settings.json << SETTINGS_EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ANTHROPIC_AUTH_TOKEN}",
    "ANTHROPIC_BASE_URL": "https://api.minimax.io/anthropic",
    "ANTHROPIC_MODEL": "MiniMax-M2.7",
    "API_TIMEOUT_MS": "300000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
SETTINGS_EOF
fi

# Start SSH daemon
exec /usr/sbin/sshd -D -e