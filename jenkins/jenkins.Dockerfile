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

# Optional: preload GitHub host keys to ease SSH known_hosts verification
RUN mkdir -p /root/.ssh \
    && touch /root/.ssh/known_hosts \
    && ssh-keyscan -T 5 -H -t rsa,ecdsa,ed25519 github.com >> /root/.ssh/known_hosts || true

# Drop back to jenkins user for running Jenkins
USER jenkins