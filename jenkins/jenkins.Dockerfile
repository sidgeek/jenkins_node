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
       xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Add Docker official apt repo for CLI and install docker-ce-cli
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian trixie stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; arch="$(uname -m)"; \
    case "$arch" in \
      x86_64) node_arch="x64" ;; \
      aarch64) node_arch="arm64" ;; \
      armv7l) node_arch="armv7l" ;; \
      *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    node_version="v20.17.0"; \
    url="https://mirrors.tencent.com/nodejs-release/${node_version}/node-${node_version}-linux-${node_arch}.tar.xz"; \
    alt="https://nodejs.org/dist/${node_version}/node-${node_version}-linux-${node_arch}.tar.xz"; \
    curl -fsSL "$url" -o /tmp/node.tar.xz || curl -fsSL "$alt" -o /tmp/node.tar.xz; \
    mkdir -p /usr/local/lib/nodejs; \
    tar -xJf /tmp/node.tar.xz -C /usr/local/lib/nodejs; \
    ln -sf /usr/local/lib/nodejs/node-${node_version}-linux-${node_arch}/bin/node /usr/local/bin/node; \
    ln -sf /usr/local/lib/nodejs/node-${node_version}-linux-${node_arch}/bin/npm /usr/local/bin/npm; \
    ln -sf /usr/local/lib/nodejs/node-${node_version}-linux-${node_arch}/bin/npx /usr/local/bin/npx; \
    ln -sf /usr/local/lib/nodejs/node-${node_version}-linux-${node_arch}/bin/corepack /usr/local/bin/corepack; \
    rm -f /tmp/node.tar.xz; \
    npm install -g pnpm; \
    ln -sf /usr/local/lib/nodejs/node-${node_version}-linux-${node_arch}/bin/pnpm /usr/local/bin/pnpm

# Optional: preload GitHub host keys to ease SSH known_hosts verification
RUN mkdir -p /root/.ssh \
    && touch /root/.ssh/known_hosts \
    && ssh-keyscan -T 5 -H -t rsa,ecdsa,ed25519 github.com >> /root/.ssh/known_hosts || true

# Drop back to jenkins user for running Jenkins
USER jenkins