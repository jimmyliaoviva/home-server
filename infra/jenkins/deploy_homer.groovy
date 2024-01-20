pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                sh 'mkdir -p home-server'
                dir ('home-server') {
                    git branch: 'main', credentialsId: 'github', url: 'git@github.com:jimmyliaoviva/home-server.git'
                }
            }
        }
        stage('run deploy playbook') {
            steps {
                script {
                    dir ('home-server') {
                        sh 'ansible-playbook ./infra/deploy-homer-playbook.yml'
                    }
                }
            }
        }
    }
}