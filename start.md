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

##### 3) 添加 Jenkinsfile 文件

```
根目录创建Jenkinsfile,内容如下:
node {
    properties([disableConcurrentBuilds()])
    def app
    def rev_no = ""
    def build_arg = ""
    def registry_address = "https://registry.hub.docker.com"

    stage('Initialize'){
        def dockerHome = tool 'myDocker'
        env.PATH = "${dockerHome}/bin:${env.PATH}"
    }

    stage("Pull GIT Repo") {
        checkout scm
        echo "pull repo"
        dir('webrtc') {
            git branch: 'main',
                credentialsId: 'my_jenkins_private',
                url: 'git@github.com:sidgeek/webRTC.git';
            // ARES-1285 Create a version file in jenkins pipeline
            rev_no = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
        }
    }

    stage("Build image") {
        echo "Build"
        build_arg += "-f ./Dockerfile --build-arg REV_NO=${rev_no} ."
        app = docker.build "sidshi/testdemo", build_arg;
    }

    stage("push docker image to dockhub") {
        echo "push"
        // docker.withRegistry(registry_address, "docker-registry") {
        //     app.push()
        //     pushNginxImageSuccess = true
        // }
    }
    stage('deploy image on machinice') {
        echo "deploy"
        sh 'docker stop mydemo || true'
        sh 'docker run -p 3000:3000 -d --rm --name mydemo sidshi/testdemo'
    }
}

```
