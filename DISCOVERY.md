# Discovery Log

## Issue: ANTHROPIC_AUTH_TOKEN not available in SSH session

**Date**: 2026-05-11

**Problem**:
When accessing the container via SSH, the `ANTHROPIC_AUTH_TOKEN` environment variable was empty, even though it was correctly set in Zeabur Dashboard and visible in Zeabur's built-in terminal.

**Root Cause**:
Zeabur filters environment variables for SSH sessions as a security measure. When an SSH session is created, Zeabur's SSH daemon strips certain "sensitive" variables from the environment that are injected at container startup. This filtering removes:
- Infrastructure-related variables (KUBERNETES_*, ZEABUR_*)
- Credential-related variables (PASSWORD, SSH_AUTHORIZED_KEYS)

The `ANTHROPIC_AUTH_TOKEN` was also filtered out because it contains "AUTH" and "TOKEN" keywords that Zeabur's security filter flags.

**Solution**:
Instead of relying on environment variables injected by Zeabur, create a `/data/.env` file with the required credentials. The `entrypoint.sh` and `.bashrc_env` are configured to source this file on every SSH login, effectively bypassing the environment variable filtering.

**Steps to set up**:
1. Create `/data/.env` with content:
   ```
   ANTHROPIC_AUTH_TOKEN=your-token-here
   ```
2. SSH login will automatically source this file via `/root/.bashrc_env`

**Note**:
This behavior may change with Zeabur updates. The `/data/.env` workaround is the most reliable method as of 2026-05-11.