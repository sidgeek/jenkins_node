# syntax=docker/dockerfile:1
FROM node:20-alpine AS builder
WORKDIR /workspace
ENV COREPACK_ENABLE_DOWNLOAD=1
RUN corepack enable && corepack prepare pnpm@9.12.0 --activate
COPY package.json ./
RUN pnpm install --prod --no-optional
COPY app.js ./app.js

FROM node:20-alpine
WORKDIR /workspace
ARG REV_NO
LABEL org.opencontainers.image.title="jenkins-node-demo" \
      org.opencontainers.image.description="Simple Node server for Jenkins Docker deployment" \
      org.opencontainers.image.revision=$REV_NO
COPY --from=builder /workspace/node_modules ./node_modules
COPY --from=builder /workspace/app.js ./app.js
EXPOSE 3000
CMD ["node","app.js"]