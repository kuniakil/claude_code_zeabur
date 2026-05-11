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

# Start SSH daemon
exec /usr/sbin/sshd -D -e