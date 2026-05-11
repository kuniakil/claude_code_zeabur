#!/bin/bash
set -e

# Inject SSH public key from environment variable (Zeabur Dashboard)
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    mkdir -p /root/.ssh
    echo "$SSH_AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
fi

# Create brewuser if it doesn't exist (for Homebrew commands)
if ! id brewuser &>/dev/null; then
    useradd -m -s /bin/bash brewuser
fi

# Persist Claude Code data to named volume
mkdir -p /data/.claude
mkdir -p /data/npm-global
mkdir -p /data/linuxbrew/Cellar
mkdir -p /data/linuxbrew/homebrew
mkdir -p /data/linuxbrew/cache
mkdir -p /data/.bun
export CLAUDE_DATA_DIR=/data/.claude

# Set ownership and permissions for brew
chown -R brewuser:brewuser /root/.linuxbrew 2>/dev/null || true
chown -R brewuser:brewuser /data/linuxbrew 2>/dev/null || true
chmod -R a+rx /root/.linuxbrew 2>/dev/null || true
chmod -R a+rx /data/linuxbrew 2>/dev/null || true
chmod 755 /root/.linuxbrew /data/linuxbrew 2>/dev/null || true
chmod 755 /root/.linuxbrew/bin/brew 2>/dev/null || true

# Create wrapper for brew command (runs as brewuser)
rm -f /usr/local/bin/brew 2>/dev/null || true
cat > /usr/local/bin/brew << 'BREW_WRAPPER'
#!/bin/bash
exec su - brewuser -c "export HOMEBREW_PREFIX=/root/.linuxbrew && export HOMEBREW_CACHE=/data/linuxbrew/cache && export HOMEBREW_CELLAR=/data/linuxbrew/Cellar && export HOMEBREW_LOCAL=/data/linuxbrew/homebrew && cd /root && /root/.linuxbrew/bin/brew $@"
BREW_WRAPPER
chmod 755 /usr/local/bin/brew

# Ensure brewuser owns the linuxbrew directories
chown -R brewuser:brewuser /root/.linuxbrew /data/linuxbrew 2>/dev/null || true

# Copy Bun from image to /data/.bun if not already there (first run)
if [ -d /root/.bun ] && [ ! -L /data/.bun ] && [ ! -f /data/.bun/bun ]; then
    cp -r /root/.bun/* /data/.bun/ 2>/dev/null || true
fi

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

# Set Homebrew environment - use /data for user-installed packages (persistent)
export HOMEBREW_PREFIX="/root/.linuxbrew"
export HOMEBREW_CACHE="/data/linuxbrew/cache"
export HOMEBREW_HOME="/data/linuxbrew"
export HOMEBREW_CELLAR="/data/linuxbrew/Cellar"
export HOMEBREW_LOCAL="/data/linuxbrew/homebrew"
export BUN_INSTALL="/data/.bun"
export PATH="/usr/local/bin:/data/.bun/bin:/root/.linuxbrew/bin:/root/.linuxbrew/sbin:/data/npm-global/bin:/root/.local/bin:$PATH"
[ -f /root/.linuxbrew/bin/brew ] && eval "$(/root/.linuxbrew/bin/brew shellenv)"

# Set npm global packages path
export npm_config_prefix="/data/npm-global"
export PATH="/data/npm-global/bin:$PATH"

# Set defaults
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.minimax.io/anthropic}"
export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-MiniMax-M2.7}"
export API_TIMEOUT_MS="${API_TIMEOUT_MS:-300000}"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:-1}"
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