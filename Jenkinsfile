node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image_name = "jenkins-node-demo"
    def image_full = ""
    // 使用 Jenkins Docker 插件：需要 Jenkins 运行环境可访问宿主机 docker（通常通过挂载 /var/run/docker.sock）

    stage('Checkout'){
        // Preload GitHub SSH host keys to satisfy strict host key checking
        sh '''
          set -euo pipefail
          mkdir -p "$HOME/.ssh"
          touch "$HOME/.ssh/known_hosts"
          # Import GitHub host keys (rsa/ecdsa/ed25519). If ssh-keyscan missing, this will no-op.
          ssh-keyscan -T 5 -H -t rsa,ecdsa,ed25519 github.com >> "$HOME/.ssh/known_hosts" || true
        '''
        checkout scm
        rev_no = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
        image_full = "${image_name}:${rev_no}"
        echo "REV_NO=${rev_no}, IMAGE=${image_full}"
        // 可选：如果你希望在这里做可达性检查，可在 Build 阶段打印 docker 版本
    }

    stage('Build Image'){
        // 使用 Jenkins Docker 插件构建镜像
        def app = docker.build("${image_full}", "-f Dockerfile --build-arg REV_NO=${rev_no} .")
        // 可选：打 latest 标签（本地）
        sh "docker tag ${image_full} ${image_name}:latest"
    }

    stage('Smoke Test'){
        sh '''
          docker rm -f node-demo-test || true
          docker run --name node-demo-test -p 3001:3000 -d ${image_full}
          sleep 2
          curl -sf http://localhost:3001/ | grep -q "hello world"
          docker rm -f node-demo-test || true
        '''
    }

    stage('Deploy'){
        sh '''
          docker rm -f node-demo || true
          docker run --name node-demo -p 3000:3000 -d --rm ${image_full}
        '''
    }
}