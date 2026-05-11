FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /tmp

# Install SSH + development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    git \
    curl \
    wget \
    build-essential \
    ca-certificates \
    tzdata \
    jq \
    bash \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Add Claude Code apt repository + install
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    && curl -fsSL https://downloads.claude.ai/keys/claude-code.asc \
       -o /etc/apt/keyrings/claude-code.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt stable main" \
       > /etc/apt/sources.list.d/claude-code.list \
    && apt-get update && apt-get install -y claude-code \
    && rm -rf /var/lib/apt/lists/*

# Harden SSH config - disable password auth, allow root login
RUN sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]