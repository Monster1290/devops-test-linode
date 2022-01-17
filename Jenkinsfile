pipeline {
    agent { docker { image 'python:3.10.1-alpine' } }
    stages {
        stage('build') {
            steps {
                sh 'pip install -r requirements.txt'
            }

            steps {
                sh 'python app.py --build'
            }
        }

        stage('tests') {
            steps {
                pytest -v --cov
            }
        }

        stage('deploy') {
            agent any

            when {
                branch "main"
            }

            steps {
                sh './Jenkins/scripts/docker_hub_check_commit_tag.sh'
                docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-cred') {
                    docker.build('monster1290/test-repo').push('${GIT_COMMIT}')
                }

                docker.withServer('tcp://192.168.64.6:2375') {
                    docker.image('monster1290/test-repo:${GIT_COMMIT}').pull()
                    sh './Jenkins/scripts/stop_and_remove_image.sh'
                    docker.image('monster1290/test-repo:${GIT_COMMIT}').run('--name app --restart=always --detach -p 8080:8080')
                }

            }
        }
    }
}