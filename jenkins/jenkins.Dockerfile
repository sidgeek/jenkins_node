FROM jenkins/jenkins:lts-jdk17

# Switch to root to install packages
USER root

# Install Docker CLI (Debian's docker.io) and curl for healthchecks and diagnostics
# If you prefer the latest Docker CLI, you can swap to docker-ce-cli via Docker's apt repo.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add Docker official apt repo for CLI and install docker-ce-cli
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian trixie stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && chmod a+r /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x $(. /etc/os-release && echo $VERSION_CODENAME) main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && corepack prepare pnpm@latest --activate \
    && rm -rf /var/lib/apt/lists/*

# Force Docker CLI to use the host unix socket by default
ENV DOCKER_HOST=unix:///var/run/docker.sock

# Optional: preload GitHub host keys to ease SSH known_hosts verification
RUN mkdir -p /root/.ssh \
    && touch /root/.ssh/known_hosts \
    && ssh-keyscan -T 5 -H -t rsa,ecdsa,ed25519 github.com >> /root/.ssh/known_hosts || true

# Drop back to jenkins user for running Jenkins
USER jenkins