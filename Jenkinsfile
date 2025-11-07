node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image_name = "jenkins-node-demo"
    def image_full = ""
    def branch_name = ""

    stage('Checkout'){
        checkout scm
        rev_no = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
        // 兼容不同类型的 Jenkins 作业：优先环境变量，其次从远端分支包含关系推断
        branch_name = sh(returnStdout: true, script: '''
          set -euo pipefail
          if [ -n "${BRANCH_NAME:-}" ]; then
            echo "$BRANCH_NAME"
          elif [ -n "${GIT_BRANCH:-}" ]; then
            echo "${GIT_BRANCH#origin/}"
          elif [ -n "${CHANGE_BRANCH:-}" ]; then
            echo "$CHANGE_BRANCH"  # PR 构建分支
          else
            # 从包含当前提交的远端分支推断，取第一个匹配
            git branch -r --contains HEAD | sed -n '1{s#^ *origin/##;p}'
          fi
        ''').trim()
        image_full = "${image_name}:${branch_name}-${rev_no}"
        echo "BRANCH=${branch_name}, REV_NO=${rev_no}, IMAGE=${image_full}"
    }

    stage('Build Image'){
        // 直接构建与标记镜像
        sh """
          set -euo pipefail
          docker --version
          docker build -t ${image_full} -f Dockerfile --build-arg REV_NO=${rev_no} .
          docker tag ${image_full} ${image_name}:${branch_name}-latest
          docker tag ${image_full} ${image_name}:latest
        """
    }

    stage('Deploy'){
        // 仅对 main、dev 分支执行部署
        if (!(branch_name in ['main','dev'])) {
            echo "跳过部署：非 main/dev 分支 (${branch_name})"
        } else {
            def containerName = "jn-app-${branch_name}"
            def hostPort = (branch_name == 'main') ? '3006' : '3007'
            sh """
              set -euo pipefail
              if docker ps -a --format '{{.Names}}' | grep -w ${containerName} >/dev/null 2>&1; then
                docker rm -f ${containerName} || true
              fi

              docker run -d \
                --name ${containerName} \
                --restart unless-stopped \
                -p ${hostPort}:3006 \
                ${image_name}:${branch_name}-${rev_no}

              docker inspect -f '{{ .Config.Image }}' ${containerName} | grep -q '${image_name}:${branch_name}-${rev_no}'
              docker logs --since 5s ${containerName} || true
            """
        }
    }
}