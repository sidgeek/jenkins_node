## 准备 nodejs 工程

##### 1) 在 github 创建一个 web 项目

```
拉取代码到本地，通过npm init初始化一个nodejs项目
根目录创建app.js,内容如下:

"use strict";

var http = require("http");

const app = http.createServer((req, res) => {
  res.end("hello world3");
});

app.listen(3000, "0.0.0.0");
```

##### 2) 添加 Dockerfile 文件

```
根目录创建Dockerfile,内容如下:
# ********** setp 1 **********
FROM node:12-alpine3.12 as builder
LABEL maintainer="xxx<xxx@gmail.com>"

# Create app directory
WORKDIR /workspace

# Install app dependencies
COPY package.json yarn.lock ./

RUN yarn

# Bundle app source
COPY . .
# RUN npm run build


# ********** setp 2 **********
FROM node:12-alpine3.12
WORKDIR /workspace

COPY --from=builder /workspace/node_modules node_modules
COPY --from=builder /workspace/app.js app

CMD ["node", "app"]

EXPOSE 3000

```

##### 3) 添加 Jenkinsfile 文件（复用宿主机 Docker）

```
根目录创建 Jenkinsfile，使用宿主机的 `/var/run/docker.sock`，所有 docker 指令都在 `docker:24-cli` 容器中执行：

node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image_name = "jenkins-node-demo"
    def image_full = ""
    def dockerArgs = "-v /var/run/docker.sock:/var/run/docker.sock"

    stage('Checkout'){
        checkout scm
        rev_no = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
        image_full = "${image_name}:${rev_no}"
        echo "REV_NO=${rev_no}, IMAGE=${image_full}"
    }

    stage('Build Image'){
        docker.image('docker:24-cli').inside(dockerArgs) {
            sh 'docker --version'
            sh "docker build -t ${image_full} -f Dockerfile --build-arg REV_NO=${rev_no} ."
        }
    }

    stage('Smoke Test'){
        docker.image('docker:24-cli').inside(dockerArgs) {
            sh 'docker rm -f node-demo-test || true'
            sh "docker run --name node-demo-test -p 3001:3000 -d ${image_full}"
            sh 'sleep 2'
            sh 'curl -sf http://localhost:3001/ | grep -q "hello world"'
            sh 'docker rm -f node-demo-test || true'
        }
    }

    stage('Deploy'){
        docker.image('docker:24-cli').inside(dockerArgs) {
            sh 'docker rm -f node-demo || true'
            sh "docker run --name node-demo -p 3000:3000 -d --rm ${image_full}"
        }
    }
}

```

##### 4) 在宿主机中让 Jenkins 容器可以执行 docker 指令

- 前提检查：
  - `docker version`、`docker ps`（确认宿主机 Docker 正常）
  - `ls -l /var/run/docker.sock`（确认 socket 存在）
  - 记录 socket 组ID：`stat -c '%g' /var/run/docker.sock`（得到如 `999` 的数字）

- 重建 Jenkins 容器并挂载宿主机 socket（推荐非 root 运行，授权到 socket 组）：
  - 停止旧容器：`docker stop jenkins && docker rm jenkins`
  - 运行 Jenkins：
    - `docker run -d --name jenkins --restart=always -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock --group-add $(stat -c '%g' /var/run/docker.sock) jenkins/jenkins:lts`
  - 若宿主机启用 SELinux，可将挂载改为：`-v /var/run/docker.sock:/var/run/docker.sock:z`；或临时使用 `--privileged`（不推荐）。

- 在 Jenkins 容器内安装 Docker CLI（只需 CLI，不需守护进程）：
  - `docker exec -u root -it jenkins bash -lc "apt-get update && apt-get install -y docker.io || apt-get install -y docker-ce-cli"`

- 权限修复（如果遇到 `permission denied`）：
  - 在容器内创建与宿主机 socket 相同 GID 的 `docker` 组并将 `jenkins` 用户加入：
    - `docker exec -u root jenkins bash -lc "groupadd -g $(stat -c '%g' /var/run/docker.sock) docker || true && usermod -aG docker jenkins"`
    - `docker restart jenkins`
  - 简化但不够安全的方式：以 root 运行 Jenkins 容器：
    - `docker run -d --name jenkins -u root --restart=always -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts`

- 验证：
  - `docker exec jenkins docker --version`
  - `docker exec jenkins docker ps`
  - 在 Jenkins 中重跑流水线，日志应显示 `docker --version` 与 `docker build` 成功。

- Docker Compose 示例（SELinux 主机建议 `:z`）：
  - `docker-compose.yml` 片段：
    ```yaml
    services:
      jenkins:
        image: jenkins/jenkins:lts
        container_name: jenkins
        restart: always
        ports:
          - "8080:8080"
          - "50000:50000"
        volumes:
          - jenkins_home:/var/jenkins_home
          - /var/run/docker.sock:/var/run/docker.sock:z
        # 更安全：将容器加入宿主机 docker.sock 的组
        group_add:
          - ${DOCKER_SOCK_GID}
        # 简化但不够安全的方式
        # user: root
    volumes:
      jenkins_home:
    ```

##### 5) 使用自定义 Jenkins 镜像（预装 Docker CLI）

- 在项目根目录新增 `Dockerfile.jenkins`（已随本仓库提供），基于 `jenkins/jenkins:latest` 预装 `docker.io`：
  ```dockerfile
  FROM jenkins/jenkins:latest
  USER root
  RUN apt-get update && apt-get install -y --no-install-recommends docker.io \
      && rm -rf /var/lib/apt/lists/*
  USER jenkins
  ```

- 构建镜像：
  - `docker build -f Dockerfile.jenkins -t my-jenkins-with-docker .`

- 运行（复用宿主机 Docker）：
  - `docker run -d --name jenkins --restart=always -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock --group-add $(stat -c '%g' /var/run/docker.sock) my-jenkins-with-docker`
  - SELinux 主机可将挂载改为 `-v /var/run/docker.sock:/var/run/docker.sock:z`

- Docker Compose 示例：
  ```yaml
  services:
    jenkins:
      image: my-jenkins-with-docker
      container_name: jenkins
      restart: always
      ports:
        - "8080:8080"
        - "50000:50000"
      volumes:
        - jenkins_home:/var/jenkins_home
        - /var/run/docker.sock:/var/run/docker.sock:z
      group_add:
        - ${DOCKER_SOCK_GID}
      # 或者使用 root（简化但不够安全）：
      # user: root
  volumes:
    jenkins_home:
  ```
## 一键启动 Jenkins（含 Docker CLI）

本仓库提供 `jenkins.Dockerfile` 与 `docker-compose.yml`，可在宿主机上一次性启动 Jenkins，并在容器内直接使用 Docker CLI，复用宿主机的 `docker.sock`。

### 前置条件
- 宿主机已安装 Docker 与 Docker Compose（Docker Desktop 或 `docker compose` 插件）。
- 宿主机 Docker 守护进程正在运行。

### 启动步骤
1. 构建并启动 Jenkins：
   - `docker compose up -d`
2. 观察日志与健康检查：
   - `docker compose logs -f jenkins`
   - 健康检查会访问 `http://localhost:8080/login`，若成功则容器处于 healthy。
3. 获取初始管理员密码：
   - `docker exec -it jenkins bash -lc 'cat /var/jenkins_home/secrets/initialAdminPassword'`
4. 打开浏览器访问 Jenkins：
   - `http://<宿主机IP>:8080/`

### 端口与挂载说明
- 端口：默认映射 `8080:8080`（Web UI）、`50000:50000`（JNLP Agent，可按需移除）。
- 数据：使用命名卷 `jenkins_home` 持久化 Jenkins 数据。
- Docker：挂载宿主机 `/var/run/docker.sock` 到容器，容器内设置 `DOCKER_HOST=unix:///var/run/docker.sock` 强制走本地 Unix 套接字。

### SELinux 与权限
- 已在 compose 中添加 `:z`（共享标签）与 `security_opt: label=disable`，通常可避免 SELinux 的套接字访问限制。
- 如仍遇到权限问题，可临时添加 `privileged: true` 验证，或改用非 root 并通过 `group_add` 加入 docker.sock 的组 GID（需要在 compose 文件中手动填写 GID）。

### 停止与清理
- 停止：`docker compose down`
- 停止并移除数据卷（慎用）：`docker compose down -v`

### 定制
- 若需最新 Docker CLI，可在 `jenkins.Dockerfile` 中改为安装 `docker-ce-cli`（Docker 官方 apt 源）。
- 若不需要 JNLP 端口，删除 compose 中的 `50000:50000` 映射。
