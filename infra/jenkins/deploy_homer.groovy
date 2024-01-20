pipeline {
    agent any
    stages {
        stage('run deploy playbook') {
            steps {
                sh 'ansible-playbook -i infra/jenkins/inventory infra/ansible/deploy_homer.yml'
            }
        }
    }
}