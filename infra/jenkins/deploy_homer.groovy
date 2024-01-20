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
                    dir ('home-server/infra/ansible') {
                        sh 'ls -al'
                        sh 'ansible-playbook -i inventory deploy-homer-playbook.yml'
                    }
                }
            }
        }
    }
}