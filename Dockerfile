FROM node:20-bookworm

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

# Install Claude Code via official installer
RUN curl -fsSL https://claude.ai/install.sh | bash

# Create Docker marker file so Homebrew knows it's in a container
RUN touch /.dockerenv

# Install Homebrew (Linuxbrew) - create non-root user for brew commands
RUN mkdir -p /root/.linuxbrew && \
    curl -fsSL https://github.com/Homebrew/brew/archive/refs/tags/4.4.0.tar.gz > /tmp/brew.tar.gz && \
    tar -xzf /tmp/brew.tar.gz -C /root/.linuxbrew --strip-components=1 && \
    rm /tmp/brew.tar.gz && \
    mkdir -p /root/.linuxbrew/bin /root/.linuxbrew/sbin /root/.linuxbrew/cache && \
    useradd -m -s /bin/bash brewuser && \
    chown -R brewuser:brewuser /root/.linuxbrew && \
    chmod -R a+rx /root/.linuxbrew && \
    chmod 755 /root/.linuxbrew/bin/brew

ENV HOMEBREW_PREFIX=/root/.linuxbrew
ENV HOMEBREW_CACHE=/data/linuxbrew/cache
ENV HOMEBREW_HOME=/data/linuxbrew
ENV HOMEBREW_CELLAR=/data/linuxbrew/Cellar
ENV HOMEBREW_LOCAL=/data/linuxbrew/homebrew
ENV PATH="/root/.linuxbrew/bin:/root/.linuxbrew/sbin:$PATH"

# Install Bun to /root/.bun (persistent via /data/.bun symlink)
ENV BUN_INSTALL=/root/.bun
RUN curl -fsSL https://bun.sh/install | bash

# Ensure npm global packages are in PATH
ENV PATH="/root/.bun/bin:/data/npm-global/bin:$PATH"

# Install Happy CLI to persistent volume
RUN mkdir -p /data/npm-global && npm config set prefix /data/npm-global && npm install -g happy

# Harden SSH config - disable password auth, allow root login
RUN sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /run/sshd

# Ensure /run/sshd exists for SSH daemon
RUN touch /run/sshd/sshd.ready

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22 3005
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]