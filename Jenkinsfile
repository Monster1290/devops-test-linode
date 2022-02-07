pipeline {
    agent none
    
    environment {
        AGENT_PYTHON_IMAGE = "python:3.10.1-alpine"
        AGENT_IMAGE_ARGS = "-u root --privileged"
        DOCKER_REGISTRY = "https://index.docker.io/v1/"
        DOCKER_HUB_REPO = "monster1290/test-repo"
        PROD_SRV_ADDR = "192.168.88.6"
        PROD_SRV_DOCKER_SOCKET = "tcp://${PROD_SRV_ADDR}:2375"
        GIT_COMMIT_FILE = "commit.txt"
    }
    
    stages {
        stage("build") {
            agent { docker {
                image AGENT_PYTHON_IMAGE
                args AGENT_IMAGE_ARGS
                reuseNode true
            } }
            steps {
                sh "pip install -r requirements.txt"
                sh "python app.py --build"
            }
        }

        stage("tests") {
            agent { docker {
                image AGENT_PYTHON_IMAGE
                args AGENT_IMAGE_ARGS
                reuseNode true
            } }
            steps {
                sh "pip install -r requirements.txt"
                sh "pytest -v --cov"
            }
        }

        stage("deploy") {
            agent {
                label "linux"
            }

            when {
                branch "main"
            }

            steps {
                sh "echo ${GIT_COMMIT} > ${GIT_COMMIT_FILE}"
                withCredentials([usernamePassword(credentialsId: "docker-hub-cred", passwordVariable: "DOCKER_HUB_PASS", usernameVariable: "DOCKER_HUB_USER")]) {
                     sh "./Jenkins/scripts/docker_hub_check_commit_tag.sh"
                }

                script {
                    def GIT_COMMIT = readFile(GIT_COMMIT_FILE).trim()
                    docker.withRegistry(DOCKER_REGISTRY, "docker-hub-cred") {
                        docker.build(DOCKER_HUB_REPO).push(GIT_COMMIT)
                    }

                    docker.withServer(PROD_SRV_DOCKER_SOCKET) {
                        docker.withRegistry(DOCKER_REGISTRY, "docker-hub-cred") {
                            docker.image("${DOCKER_HUB_REPO}:${GIT_COMMIT}").pull()
                            sh "./Jenkins/scripts/stop_and_remove_image.sh"
                            docker.image("${DOCKER_HUB_REPO}:${GIT_COMMIT}")
                                .run("--name app --restart=always --detach -p 8080:8080")
                        }
                    }
                }
            }
        }
    }
}