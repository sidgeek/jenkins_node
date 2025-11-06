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
}