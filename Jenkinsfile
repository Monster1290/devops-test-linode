pipeline {
    agent none
    
    environment {
        AGENT_PYTHON_IMAGE = "python:3.10.1-alpine"
        AGENT_IMAGE_ARGS = "-u root --privileged"
        DOCKER_REGISTRY = "https://index.docker.io/v1/"
        DOCKER_HUB_REPO = "monster1290/test-repo"
        PROD_SRV_ADDR = "192.168.88.7"
        PROD_SRV_DOCKER_SOCKET = "tcp://${PROD_SRV_ADDR}:2375"
        GIT_COMMIT_FILE = "commit.txt"
        K8S_ROLLOUT_NAME = "demo-app"
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

        stage("Deliver for development") {
            agent {
                label "staging"
            }

            when {
                not { branch "main" }
                // Check that current execution made by user
                expression { currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause) != null }
            }

            steps {
            	script {
	                docker.image(AGENT_PYTHON_IMAGE).pull()
	                def STAGING_PORT = sh(encoding: 'UTF-8', returnStdout: true, script: './Jenkins/scripts/get_free_service_port.sh').trim()
	                def STAGING_IP = sh(encoding: 'UTF-8', returnStdout: true, script: 'python3 ./Jenkins/scripts/get_host_ip.py').trim()
	                docker.image(AGENT_PYTHON_IMAGE).inside(AGENT_IMAGE_ARGS + " -p $STAGING_PORT:8080"){
	                    sh 'pip install -r requirements.txt'
	                    sh 'python app.py &'
	                    echo "Web is accessible via http://$STAGING_IP:$STAGING_PORT/"
	                    input message: 'Finished using the web site? (Click "Proceed" to continue)'
	                }
	            }
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

                    input message:"Should we start rollout process?"

                    docker.image(AGENT_PYTHON_IMAGE).inside(AGENT_IMAGE_ARGS + "-v $(which kubectl):$(which kubectl) -v $(which kubectl-argo-rollouts):$(which kubectl-argo-rollouts)") {
                        withCredentials([file(credentialsId: 'k8s-config', variable: 'KUBECONFIG')]) {
                            sh "pip install kubernetes"

                            import groovy.json.JsonSlurper
                            def canary_stages_json = sh(encoding: 'UTF-8', returnStdout: true, script:"python3 ./Jenkins/scripts/get_k8s_canary_steps.py $K8S_ROLLOUT_NAME").trim()
                            def canary_stages = new JsonSlurper().parseText(canary_stages_json)
                            def stable_image = sh(encoding: 'UTF-8', returnStdout: true, script:"kubectl argo rollouts get rollouts $K8S_ROLLOUT_NAME | grep -m 1 stable | awk '{print $2}'")

                            echo "Starting canary rollout process"
                            sh "kubectl argo rollouts set image $K8S_ROLLOUT_NAME $K8S_ROLLOUT_NAME=${DOCKER_HUB_REPO}:${GIT_COMMIT}"

                            for (canary_stage in canary_stages) {
                                for (canary_step in canary_stage) {
                                    sh "python3 ./Jenkins/scripts/wait_k8s_canary_step.py $canary_step $K8S_ROLLOUT_NAME"
                                    echo "Canary rollout reached $canary_step\%"
                                }

                                input message: 'Promote rollout?', parameters: [choice(choices: ['Promote', 'Abort'], name: 'promote_choice')]

                                if (promote_choice == 'Promote') {
                                    sh "kubectl argo rollouts promote $K8S_ROLLOUT_NAME"
                                } else {
                                    sh "kubectl argo rollouts abort $K8S_ROLLOUT_NAME"
                                    sh "kubectl argo rollouts set image $K8S_ROLLOUT_NAME $K8S_ROLLOUT_NAME=$stable_image"
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}