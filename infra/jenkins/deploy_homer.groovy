pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                sh 'mkdir -p home-server'
                dir ('home-server') {
                    git branch: 'master', credentialsId: 'github', url: 'git@github.com:jimmyliaoviva/home-server.git'
                }
            }
        }
        stage('run deploy playbook') {
            steps {
                script {
                    dir ('home-server') {
                        sh 'ansible-playbook -i infra//inventory infra/deploy-homer-playbook.yml'
                    }
                }
            }
        }
    }
}