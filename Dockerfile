# syntax=docker/dockerfile:1
FROM node:20-alpine
WORKDIR /workspace
ARG REV_NO
LABEL org.opencontainers.image.title="jenkins-node-demo" \
      org.opencontainers.image.description="Simple Node server for Jenkins Docker deployment" \
      org.opencontainers.image.revision=$REV_NO
COPY app.js ./app.js
EXPOSE 3006
CMD ["node","app.js"]