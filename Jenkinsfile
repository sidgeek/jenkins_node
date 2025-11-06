node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image_name = "jenkins-node-demo"
    def image_full = ""

    stage('Checkout'){
        checkout scm
        rev_no = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
        image_full = "${image_name}:${rev_no}"
        echo "REV_NO=${rev_no}, IMAGE=${image_full}"
    }

    stage('Build Image'){
        // 直接构建与标记镜像
        sh """
          set -euo pipefail
          docker --version
          docker build -t ${image_full} -f Dockerfile --build-arg REV_NO=${rev_no} .
          docker tag ${image_full} ${image_name}:latest
        """
    }

    stage('Deploy'){
        // 停旧容器并以当前提交镜像启动
        sh """
          set -euo pipefail
          # 停止并删除旧容器（如果存在）
          if docker ps -a --format '{{.Names}}' | grep -w jn-app >/dev/null 2>&1; then
            docker rm -f jn-app || true
          fi

          # 使用版本化标签运行新容器，避免 latest 混淆
          docker run -d \
            --name jn-app \
            --restart unless-stopped \
            -p 3000:3000 \
            ${image_name}:${rev_no}

          # 简单健康检查与镜像确认
          docker inspect -f '{{ .Config.Image }}' jn-app | grep -q '${image_name}:${rev_no}'
          docker logs --since 5s jn-app || true
        """
    }
}