node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image_name = "jenkins-node-demo"
    def image_full = ""
    // 使用“工具箱容器”运行 docker CLI，并复用宿主机 docker.sock
    def dockerArgs = "-v /var/run/docker.sock:/var/run/docker.sock:z"
    def dockerReady = false

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
        // 非阻断诊断：打印详细信息并判定 dockerReady
        def status = sh(returnStatus: true, script: '''
          set -euo pipefail
          echo "== 用户与环境 =="
          id || true
          echo "== /var/run/docker.sock 权限 =="
          ls -l /var/run/docker.sock || true
          if command -v getenforce >/dev/null 2>&1; then
            echo "== SELinux 状态 =="
            getenforce || true
            ls -Z /var/run/docker.sock || true
          fi
          echo "== DOCKER_* 环境变量 =="
          env | grep -E '^DOCKER_|^CONTAINER_|^OCI_' || true

          if ! command -v docker >/dev/null 2>&1; then
            echo "ERROR: docker CLI 未安装于 Jenkins 容器。请在容器内安装 docker 客户端 (例如 apt-get install -y docker.io)，或使用包含 docker CLI 的镜像。" >&2
            exit 127
          fi

          if [ ! -S /var/run/docker.sock ]; then
            echo "ERROR: 未挂载宿主机 /var/run/docker.sock 到 Jenkins 容器。请在 docker run 中添加 -v /var/run/docker.sock:/var/run/docker.sock。" >&2
            exit 1
          fi

          echo "== 通过 unix socket 强制访问 Docker =="
          # 显式指定使用 unix socket，避免 DOCKER_HOST 误导向 TCP
          if docker -H unix:///var/run/docker.sock version >/dev/null 2>&1; then
            echo "PASS: docker -H unix:///var/run/docker.sock version 成功"
          else
            echo "尝试使用 curl 探测守护进程 _ping"
            if command -v curl >/dev/null 2>&1; then
              curl --unix-socket /var/run/docker.sock http://localhost/_ping || true
            else
              echo "curl 不存在，跳过 _ping 探测"
            fi
            echo "ERROR: 无法访问 Docker 守护进程。可能是权限或 SELinux 限制。" >&2
            exit 1
          fi
        ''')
        dockerReady = (status == 0)
        echo "dockerReady=${dockerReady}"
    }

    stage('Build Image'){
        if (!dockerReady) {
            echo '跳过 Build Image：docker 未就绪'
        } else {
            // 直接在 Jenkins 容器中使用已安装的 docker CLI 构建镜像
            sh """
              set -euo pipefail
              docker --version
              docker build -t ${image_full} -f Dockerfile --build-arg REV_NO=${rev_no} .
              docker tag ${image_full} ${image_name}:latest
            """
        }
    }
}