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

# Install Claude Code via official installer
RUN curl -fsSL https://claude.ai/install.sh | bash

# Harden SSH config - disable password auth, allow root login
RUN sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /run/sshd

# Ensure /run/sshd exists for SSH daemon
RUN touch /run/sshd/sshd.ready

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]