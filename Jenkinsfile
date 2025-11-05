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