pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                sh 'mkdir -p home-server'
                dir ('home-server') {
                    git branch: 'JT-7_add_jenkins-ansible', credentialsId: 'github', url: 'git@github.com:jimmyliaoviva/home-server.git'
                }
            }
        }
        stage('run deploy playbook') {
            steps {
                script {
                    dir ('/home-server/home-server/infra/ansible') {
                        sh 'ls -al'
                        sh 'ansible-playbook -i inventory deploy-homer-playbook.yml'
                    }
                }
            }
        }
    }
}