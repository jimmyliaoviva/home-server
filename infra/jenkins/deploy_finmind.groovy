pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                sh 'mkdir -p finmind'
                dir ('finmind') {
                    git branch: 'JT-9_add_finmind', credentialsId: 'github', url: 'git@github.com:jimmyliaoviva/home-server.git'
                }
            }
        }
        stage('run deploy playbook') {
            steps {
                script {
                    dir ('home-server/infra/ansible') {
                        sshagent(credentials: ['portainer2']) {
                                withCredentials([string(credentialsId: 'portainer_password', variable: 'PASS')]) {
                            sh '''
                                echo "$SSH_KEY" > temp_key.pem
                                chmod 600 temp_key.pem
                            '''
                            sh '''ansible-playbook -i inventory deploy-finmind-playbook.yml \
                                -e "ansible_become_pass=${PASS}" \
                                -e "github_key='''+ temp_key.pem + '''"
                                '''
                                }
                        }
                    }
                }
            }
        }
    }
}
