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

# Read ANTHROPIC_AUTH_TOKEN directly from /proc/1/environ (Zeabur injects vars this way)
# This bypasses the SSH session inheritance issue
read_env_from_proc1() {
    if [ -f /proc/1/environ ]; then
        cat /proc/1/environ | tr '\0' '\n' | grep -E "^(ANTHROPIC_AUTH_TOKEN|MINIMAX_TOKEN|PASSWORD)=" | while read line; do
            key="${line%%=*}"
            value="${line#*=}"
            export "$key"="$value"
        done
    fi
}

# Try multiple sources for ANTHROPIC_AUTH_TOKEN
get_token() {
    # Try ANTHROPIC_AUTH_TOKEN directly
    local token="$ANTHROPIC_AUTH_TOKEN"

    # Try MINIMAX_TOKEN (workaround for Zeabur)
    if [ -z "$token" ] && [ -n "$MINIMAX_TOKEN" ]; then
        token="$MINIMAX_TOKEN"
    fi

    # Try PASSWORD (Zeabur may store it here)
    if [ -z "$token" ] && [ -n "$PASSWORD" ]; then
        token="$PASSWORD"
    fi

    echo "$token"
}

# Read from /proc/1/environ at startup
read_env_from_proc1

# Get token
TOKEN=$(get_token)

# Write SSH environment setup script - reads from /proc/1/environ each time
cat > /root/.bashrc_env << 'BASHRC_EOF'
# Read current environment from /proc/1/environ (Zeabur injects vars here)
if [ -f /proc/1/environ ]; then
    while IFS='=' read -r key value; do
        case "$key" in
            ANTHROPIC_AUTH_TOKEN) export ANTHROPIC_AUTH_TOKEN="$value" ;;
            MINIMAX_TOKEN) export MINIMAX_TOKEN="$value" ;;
            PASSWORD) export PASSWORD="$value" ;;
            ANTHROPIC_BASE_URL) export ANTHROPIC_BASE_URL="$value" ;;
            ANTHROPIC_MODEL) export ANTHROPIC_MODEL="$value" ;;
            API_TIMEOUT_MS) export API_TIMEOUT_MS="$value" ;;
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC) export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="$value" ;;
        esac
    done < <(tr '\0' '\n' < /proc/1/environ 2>/dev/null)
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

# Write settings.json with token from /proc/1/environ
if [ -n "$TOKEN" ]; then
    mkdir -p /root/.claude
    cat > /root/.claude/settings.json << SETTINGS_EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${TOKEN}",
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