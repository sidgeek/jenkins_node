node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image_name = "jenkins-node-demo"
    def image_full = ""
    // 使用“工具箱容器”运行 docker CLI，并复用宿主机 docker.sock
    def dockerArgs = "-v /var/run/docker.sock:/var/run/docker.sock"

    stage('Checkout'){
        // 预置 GitHub host key，避免严格校验失败
        sh '''
          set -euo pipefail
          mkdir -p "$HOME/.ssh"
          touch "$HOME/.ssh/known_hosts"
          ssh-keyscan -T 5 -H -t rsa,ecdsa,ed25519 github.com >> "$HOME/.ssh/known_hosts" || true
        '''
        checkout scm
        rev_no = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
        image_full = "${image_name}:${rev_no}"
        echo "REV_NO=${rev_no}, IMAGE=${image_full}"
    }

    stage('Preflight Docker'){
        // 在 Jenkins 容器本身检查 docker 命令与 docker.sock 可用性
        sh '''
          set -euo pipefail
          if [ ! -S /var/run/docker.sock ]; then
            echo "ERROR: 未挂载宿主机 /var/run/docker.sock 到 Jenkins 容器。请在 docker run 中添加 -v /var/run/docker.sock:/var/run/docker.sock。" >&2
            exit 1
          fi
          # 尝试与宿主机 Docker 通信
          if ! docker version >/dev/null 2>&1; then
            echo "ERROR: 无法访问 Docker 守护进程。请检查权限：以 root 运行容器，或为 Jenkins 用户加入 docker.sock 对应的组 (使用 --group-add)。" >&2
            exit 1
          fi
          if ! command -v docker >/dev/null 2>&1; then
            echo "ERROR: docker CLI 未安装于 Jenkins 容器。请在容器内安装 docker 客户端 (例如 apt-get install -y docker.io)，或使用包含 docker CLI 的镜像。" >&2
            exit 127
          fi
          echo "Docker CLI 与 docker.sock 检查通过。"
        '''
    }

    stage('Build Image'){
        // 在工具箱容器 docker:24-cli 中执行 docker CLI
        docker.image('docker:24-cli').inside(dockerArgs) {
            sh 'docker --version'
            // sh "docker build -t ${image_full} -f Dockerfile --build-arg REV_NO=${rev_no} ."
            // sh "docker tag ${image_full} ${image_name}:latest"
        }
    }

    // stage('Smoke Test'){
    //     docker.image('docker:24-cli').inside(dockerArgs) {
    //         sh 'docker rm -f node-demo-test || true'
    //         sh "docker run --name node-demo-test -p 3001:3000 -d ${image_full}"
    //         sh 'sleep 2'
    //         sh 'curl -sf http://localhost:3001/ | grep -q "hello world"'
    //         sh 'docker rm -f node-demo-test || true'
    //     }
    // }

    // stage('Deploy'){
    //     docker.image('docker:24-cli').inside(dockerArgs) {
    //         sh 'docker rm -f node-demo || true'
    //         sh "docker run --name node-demo -p 3000:3000 -d --rm ${image_full}"
    //     }
    // }
}