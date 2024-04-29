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
                                                file(credentialsId: 'github_key', variable: 'SSH_KEY')]) {
                            sh '''
                                chnmod 600 "${SSH_KEY}"
                                ls -l "${SSH_KEY}" 
                            '''
                            sh """ansible-playbook -i inventory deploy-finmind-playbook.yml \
                                -e "ansible_become_pass=${PASS} github_key=${SSH_KEY}" 
                                """
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
