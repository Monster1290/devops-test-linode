// This pipline uses git commit hash as tag for docker images
pipeline {
    agent none
    
    environment {
        AGENT_PYTHON_IMAGE = "python:3.10.1-alpine"
        AGENT_IMAGE_ARGS = "-u root --privileged"
        DOCKER_REGISTRY = "https://index.docker.io/v1/"
        DOCKER_HUB_REPO = "monster1290/test-repo"
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

        // This stage launches app for tests purposes. Only manual execution by users possible.
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
                // Save commit into file to reuse in script block.
                sh "echo ${GIT_COMMIT} > ${GIT_COMMIT_FILE}"

                // Check that current git commit hash not presented as tag in registry. If so then this deploy must not proceed
                withCredentials([usernamePassword(credentialsId: "docker-hub-cred", passwordVariable: "DOCKER_HUB_PASS", usernameVariable: "DOCKER_HUB_USER")]) {
                     sh "./Jenkins/scripts/docker_hub_check_commit_tag.sh"
                }

                script {
                    def GIT_COMMIT = readFile(GIT_COMMIT_FILE).trim()
                    docker.withRegistry(DOCKER_REGISTRY, "docker-hub-cred") {
                        docker.build(DOCKER_HUB_REPO).push(GIT_COMMIT)
                    }

                    input message:"Should we start rollout process?"

                    // Get path to executables to pass into python agent image
                    def kubectl_path = sh(encoding: 'UTF-8', returnStdout: true, script:"which kubectl").trim()
                    def kubectl_argo_rollouts_path = sh(encoding: 'UTF-8', returnStdout: true, script:"which kubectl-argo-rollouts").trim()

                    docker.image(AGENT_PYTHON_IMAGE).inside(AGENT_IMAGE_ARGS + " -v $kubectl_path:$kubectl_path -v $kubectl_argo_rollouts_path:$kubectl_argo_rollouts_path") {
                        withCredentials([file(credentialsId: 'k8s-config', variable: 'KUBECONFIG')]) {
                            // Manual dependency installation for python scripts
                            sh "pip install kubernetes"

                            // Parse canary stages from k8s rollout resource and output as json
                            def canary_stages_json = sh(encoding: 'UTF-8', returnStdout: true, script:"python3 ./Jenkins/scripts/get_k8s_canary_steps.py $K8S_ROLLOUT_NAME").trim()
                            // Parse json
                            def canary_stages = readJSON text:canary_stages_json
                            // Get current stable image for rollout
                            def stable_image = sh(encoding: 'UTF-8', returnStdout: true, script:"kubectl argo rollouts get rollouts $K8S_ROLLOUT_NAME | grep -m 1 stable | awk '{print \$2}'")
                            def i = 0

                            echo "Starting canary rollout process"
                            sh "kubectl argo rollouts set image $K8S_ROLLOUT_NAME $K8S_ROLLOUT_NAME=${DOCKER_HUB_REPO}:${GIT_COMMIT}"

                            // Loop through canary stages. Between stages manual promotion is required
                            for (canary_stage in canary_stages) {
                                // Loop through canary steps. Each stage contains one or more steps. Between steps exists pause statements (see argo rollouts docs)
                                for (canary_step in canary_stage) {
                                    // Wait when rollout reaches desired step after manual promotion or after pause statement.
                                    sh "python3 ./Jenkins/scripts/wait_k8s_canary_step.py $canary_step $K8S_ROLLOUT_NAME"
                                    echo "Canary rollout reached $canary_step %"
                                }

                                // Break loop if all steps are passed
                                if (i == canary_stages.size() - 1) {
                                    break
                                }

                                // Ask for rollout promotion
                                i++
                                def is_promote_rollout = input message: 'Promote rollout? [yes/no]', parameters: [booleanParam(defaultValue: false, name: "Promote")]

                                if (is_promote_rollout) {
                                    // Promote rollout
                                    sh "kubectl argo rollouts promote $K8S_ROLLOUT_NAME"
                                } else {
                                    // Abort rollout and return to stable image
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