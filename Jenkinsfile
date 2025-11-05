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