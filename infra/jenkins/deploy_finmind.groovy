pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                sh 'mkdir -p home-server'
                dir ('home-server') {
                    git branch: 'JT-9_add_finmind', credentialsId: 'github', url: 'git@github.com:jimmyliaoviva/home-server.git'
                }
            }
        }
        stage('run deploy playbook') {
            steps {
                script {
                    dir ('home-server/infra/ansible') {
                        sshagent(credentials: ['portainer2']) {
                                withCredentials([string(credentialsId: 'portainer_password', variable: 'PASS'),
                                                sshUserPrivateKey(credentialsId: 'github', keyFileVariable: 'SSH_KEY')]) {
                            sh '''
                                echo "${SSH_KEY}" > temp_key.pem
                                chmod 600 temp_key.pem
                            '''
                            sh '''ansible-playbook -i inventory deploy-finmind-playbook.yml \
                                -e "ansible_become_pass=${PASS}" \
                                -e "github_key=temp_key.pem"
                                '''
                                }
                        }
                    }
                }
            }
        }
    }
    post {
        // Clean after build
        always {
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: true,
                    disableDeferredWipeout: true,
                    notFailBuild: true,
                    patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                               [pattern: '.propsfile', type: 'EXCLUDE']])
        }
    }
}
