FROM jenkins/jenkins:lts-jdk17

# Switch to root to install packages
USER root

# Install Docker CLI (Debian's docker.io) and curl for healthchecks and diagnostics
# If you prefer the latest Docker CLI, you can swap to docker-ce-cli via Docker's apt repo.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       docker.io \
       curl \
       ca-certificates \
       gnupg \
    && rm -rf /var/lib/apt/lists/*

# Force Docker CLI to use the host unix socket by default
ENV DOCKER_HOST=unix:///var/run/docker.sock

# Optional: preload GitHub host keys to ease SSH known_hosts verification
RUN mkdir -p /root/.ssh \
    && touch /root/.ssh/known_hosts \
    && ssh-keyscan -T 5 -H -t rsa,ecdsa,ed25519 github.com >> /root/.ssh/known_hosts || true

# Drop back to jenkins user for running Jenkins
USER jenkins