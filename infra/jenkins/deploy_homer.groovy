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
                    dir ('home-server/infra/ansible') {
                        sshagent(credentials: ['portainer']) {
                                withCredentials(string(credentialsId: 'portainer_password', variable: 'PASS')) {

                            sh 'ansible-playbook -i inventory deploy-homer-playbook.yml -e "ansible_become_pass=${PASS}"'
                            }
                        }
                    }
                }
            }
        }
    }
}