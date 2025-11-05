node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image_name = "jenkins-node-demo"
    def image_full = ""
    // 复用宿主机 docker：挂载 /var/run/docker.sock 到 Jenkins 运行环境
    def docker_sock = "/var/run/docker.sock"
    def api_base = "http://localhost"

    stage('Checkout'){
        checkout scm
        rev_no = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
        image_full = "${image_name}:${rev_no}"
        echo "REV_NO=${rev_no}, IMAGE=${image_full}"
        // 简单可达性检查
        sh """
          set -euo pipefail
          curl --fail --silent --show-error --unix-socket ${docker_sock} ${api_base}/_ping | grep -q OK
        """
    }

    stage('Build Image'){
        // 使用 Docker Remote API 构建镜像，无需 docker CLI
        sh """
          set -euo pipefail
          tar -C "$WORKSPACE" -cf - . \
          | curl --fail --silent --show-error --unix-socket ${docker_sock} \
                 -X POST -H "Content-Type: application/x-tar" \
                 --data-binary @- \
                 "${api_base}/build?t=${image_full}&dockerfile=Dockerfile"
          # 额外打上 latest 标签
          curl --fail --silent --show-error --unix-socket ${docker_sock} \
               -X POST "${api_base}/images/${image_full}/tag?repo=${image_name}&tag=latest"
        """
    }

    stage('Smoke Test'){
        sh """
          set -euo pipefail
          # 删除旧容器（忽略不存在的情况）
          curl --silent --unix-socket ${docker_sock} -X DELETE "${api_base}/containers/node-demo-test?force=true" || true

          # 创建并映射端口 3001->3000
          cat > /tmp/create-node-demo-test.json <<'EOF'
          {
            "Image": "${image_full}",
            "Cmd": ["node","app.js"],
            "HostConfig": {
              "AutoRemove": true,
              "PortBindings": {"3000/tcp": [{"HostPort": "3001"}]}
            },
            "ExposedPorts": {"3000/tcp": {}}
          }
EOF
          curl --fail --silent --show-error --unix-socket ${docker_sock} \
               -X POST -H "Content-Type: application/json" \
               --data-binary @/tmp/create-node-demo-test.json \
               "${api_base}/containers/create?name=node-demo-test"

          # 启动容器
          curl --fail --silent --show-error --unix-socket ${docker_sock} -X POST \
               "${api_base}/containers/node-demo-test/start"

          # 验证服务响应
          sleep 2
          curl -sf http://localhost:3001/ | grep -q "hello world"

          # 清理测试容器
          curl --silent --unix-socket ${docker_sock} -X DELETE "${api_base}/containers/node-demo-test?force=true" || true
        """
    }

    stage('Deploy'){
        sh """
          set -euo pipefail
          # 删除旧容器（忽略不存在的情况）
          curl --silent --unix-socket ${docker_sock} -X DELETE "${api_base}/containers/node-demo?force=true" || true

          # 创建并映射端口 3000->3000，后台运行
          cat > /tmp/create-node-demo.json <<'EOF'
          {
            "Image": "${image_full}",
            "Cmd": ["node","app.js"],
            "HostConfig": {
              "AutoRemove": true,
              "PortBindings": {"3000/tcp": [{"HostPort": "3000"}]}
            },
            "ExposedPorts": {"3000/tcp": {}}
          }
EOF
          curl --fail --silent --show-error --unix-socket ${docker_sock} \
               -X POST -H "Content-Type: application/json" \
               --data-binary @/tmp/create-node-demo.json \
               "${api_base}/containers/create?name=node-demo"

          # 启动容器
          curl --fail --silent --show-error --unix-socket ${docker_sock} -X POST \
               "${api_base}/containers/node-demo/start"
        """
    }
}