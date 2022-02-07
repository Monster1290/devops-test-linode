pipeline {
    agent none
    stages {
        stage('build') {
            agent { docker {
                image 'python:3.10.1-alpine'
                args '-u root --privileged'
            } }
            steps {
                sh 'pip install -r requirements.txt'

                sh 'python app.py --build'
            }
        }

        stage('tests') {
            agent { docker {
                image 'python:3.10.1-alpine'
                args '-u root --privileged'
            } }
            steps {
                sh 'pip install -r requirements.txt'
                sh 'pytest -v --cov'
            }
        }

        stage('deploy') {
            agent {
                label 'linux'
            }

            when {
                branch 'main'
            }

            steps {
                // Save commit hash to file to future use in script block
                sh "echo ${GIT_COMMIT} > commit.txt"
                withCredentials([usernamePassword(credentialsId: 'docker-hub-cred', passwordVariable: 'DOCKER_HUB_PASS', usernameVariable: 'DOCKER_HUB_USER')]) {
                    sh './Jenkins/scripts/docker_hub_check_commit_tag.sh'
                }

                script {
                    // Getting commit hash value from file because env.GIT_COMMIT not passed to script block
                    def GIT_COMMIT = readFile('commit.txt').trim()
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-cred') {
                        docker.build('monster1290/test-repo').push("${GIT_COMMIT}")
                    }

                    docker.withServer('tcp://192.168.88.6:2375') {
                        docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-cred') {
                            docker.image("monster1290/test-repo:${GIT_COMMIT}").pull()
                            sh './Jenkins/scripts/stop_and_remove_image.sh'
                            docker.image("monster1290/test-repo:${GIT_COMMIT}").run('--name app --restart=always --detach -p 8080:8080')
                        }
                    }
                }
            }
        }
    }
}