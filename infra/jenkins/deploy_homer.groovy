pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                sh 'mkdir -p home-server'
                dir ('home-server') {
                    git branch: 'master', credentialsId: 'jimmyliaoviva', url: 'git@github.com:jimmyliaoviva/home-server.git'
                }
            }
        }
        stage('run deploy playbook') {
            steps {
                sh 'ansible-playbook -i infra/jenkins/inventory infra/ansible/deploy_homer.yml'
            }
        }
    }
}