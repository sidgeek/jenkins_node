node {
    properties([disableConcurrentBuilds()])
    def rev_no = ""
    def image
    def image_name = "jenkins-node-demo"

    stage('Initialize'){
        def dockerHome = tool 'myDocker'
        env.PATH = "${dockerHome}/bin:${env.PATH}"
    }

    stage('Checkout'){
        checkout scm
        rev_no = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
    }

    stage('Build Image'){
        image = docker.build("${image_name}:${rev_no}", "-f Dockerfile --build-arg REV_NO=${rev_no} .")
    }

    stage('Smoke Test'){
        sh 'docker rm -f node-demo-test || true'
        sh "docker run --name node-demo-test -p 3001:3000 -d ${image.imageName()}"
        sh 'sleep 2'
        sh 'curl -sf http://localhost:3001/ | grep -q \"hello world\"'
        sh 'docker rm -f node-demo-test || true'
    }

    stage('Deploy'){
        sh 'docker rm -f node-demo || true'
        sh "docker run --name node-demo -p 3000:3000 -d --rm ${image.imageName()}"
    }
}