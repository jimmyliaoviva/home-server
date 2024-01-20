pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                sh 'mkdir -p home-server'
                sh '''
                    mkdir -p ~/.ssh
                    echo "Host *" > ~/.ssh/config
                    echo "  StrictHostKeyChecking no" >> ~/.ssh/config
                    chmod 600 ~/.ssh/config
                    '''
                dir ('home-server') {
                    git branch: 'main', credentialsId: 'github', url: 'git@github.com:jimmyliaoviva/home-server.git'
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