pipeline {
    agent any

    tools{
        jdk "jdk17"
        nodejs "nodejs16"
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        API_KEY = "0e775d38damsh312b38c4f07187ep17a05ejsn994883147928"
        DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1187472599043805335/5xoeKJ9NtiPp0tbS1B7c8yJb8BzTVu1NOPQscRJIpXXy4VrmFn2j9pJAqwa6q9g3N9Xz"
    }

    parameters{
        string (name: 'DOCKER_HUB_USERNAME', defaultValue: 'jadonharsh', description: 'Docker Hub Username')
        string (name: 'IMAGE_NAME', defaultValue: 'youtube', description: 'Docker Image Name')
        choice (name: 'action', choices: 'create\ndelete', description: 'Select create or destroy.')
    }

    stages{
        
        // Retrive Email of an Latest Committer in GitHub
        stage('Retrieve Committer Email') {
            steps {
                script {
                    committerEmail = sh(
                        script: "git log -1 --pretty=format:%ae",
                        returnStdout: true
                    ).trim()
                    echo "Committer email: ${committerEmail}"
                }
            }
        }


        // SonarQube Code Testing (NodeJs)
        stage("SonarQube Analysis and QualityChecks") {
            when { expression { params.action == 'create'}}
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh '''cd Application && $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=node-project -Dsonar.projectKey=node-project '''
                }   
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: "sonar-token"
                }
            }
        }


        // OWasp Vulnerabilities Testing (Entire Dir)
        stage('OWASP Analysis') {
        when { expression { params.action == 'create'}}
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'owasp-scanner'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }


        // Trivy Code & Misconfiguration Testing (Entire Dir)
        stage('Trivy Analysis and Result') {
            when { expression { params.action == 'create'}}
            steps {
                sh "trivy fs . --format json -o trivy-fs-report.json"
                // Uncomment the following lines if you want to fail the build on critical issues
                // sh '''trivy fs . --exit-code 1 --severity CRITICAL --format json -o trivy-check-report.json'''
            }
        }


        // Building Docker Images and Running them locally (Jenkins Machine)
        stage('Build and Run Docker Images') {
            when { expression { params.action == 'create'}}
            steps {
                sh "docker build --build-arg REACT_APP_RAPID_API_KEY=$API_KEY -t $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:latest Application/."
                sh """
                    docker rm -f ${params.IMAGE_NAME}
                    docker run --name ${params.IMAGE_NAME} -p 80:80 -d ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:latest
                """
            }
            // Printing the Local Ip of Staging Application
            post {
                success {
                    sh '''IP=$(curl https://ipinfo.io/ip) && echo "Staging Application is deployed at $IP"'''
                }
            }
        }


        // Deploying Docker Images with "latest" & "BUILD_NUMBER" Tags for Versioning
        stage('Deploy Docker Images and Cleanup') {
            when { expression { params.action == 'create'}}
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker'){
                        sh """
                            docker tag ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:latest ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}
                            docker push ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:latest
                            docker push ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}
                        """
                    }
                }
            }
            // Remove the Unused Docker Images except the "latest" Tag
            post{
                success {
                    sh """
                        docker rmi \$(docker images --filter "dangling=true" -q --no-trunc)
                        docker rmi ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}
                    """ 
                }
            }
        }


        // Testing Docker Images which was Uploaded to DockerHub
        stage('Test Docker Images') {
        when { expression { params.action == 'create'}}
            steps {
                sh "trivy image $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:$BUILD_NUMBER -o trivy-image-report.json"
            }
        }


        // Configuring AWS Credentials required for Deployment in EKS Cluster through HELM Charts
        stage('AWS Configure and Deploy on K8s') {
        when { expression { params.action == 'create'}}
            steps {
                script {
                // Configuring AWS Credentials which will help in authenticating EKS cluster 
                    withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY', secretKeyVariable: 'AWS_SECRET_KEY')]){
                        sh ''' 
                            aws configure set aws_access_key_id "${AWS_ACCESS_KEY}"
                            aws configure set aws_secret_access_key "${AWS_SECRET_KEY}"
                            aws configure set region "ap-south-1"
                            aws configure set output "json"
                            
                        '''
                        // Uncomment the following lines if you want to copy .kubeconfig file from EKS Cluster
                        // sh "aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster"
                    }
                
                // Installing HELM Charts along with variable "IMAGE_ID".
                    withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kube_config', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                        sh """
                            helm upgrade --install --force ${params.IMAGE_NAME} Helm-Charts --set IMAGE_ID=${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}
                        """
                        sh 'kubectl describe svc/my-app-service | grep "LoadBalancer Ingress"'
                    }
                }
            }
        }


        // Removing the Running Docker Containers
        stage('Removing Running Containers') {
        when { expression { params.action == 'delete'}}
            steps {
                sh "docker rm -f $params.IMAGE_NAME"
            }
        }


        // Uninstalling HELM Charts
        stage('Delete on K8s') {
        when { expression { params.action == 'delete'}}
            steps {
                withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kube_config', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                    sh "helm uninstall $params.IMAGE_NAME"
                }
            }
        }


        // Deleting unused Docker Images & Workspace 
        stage('Cleanup') {
        when { expression { params.action == 'delete'}}
            steps {
                sh "docker container prune -f"
                cleanWs()
            }
        }
    }

    // Pusing Notifications to the Discord Channels Using WebHooks
    post {
        failure {
            echo 'Discord Notifications'
            discordSend description: "${JOB_NAME} Triggered By GitHub Push (${committerEmail})", footer: "${BUILD_NUMBER} Build Failed!!" , link: BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: DISCORD_WEBHOOK
        }
        success {
            echo 'Discord Notifications'
            discordSend description: "${JOB_NAME} Triggered By GitHub Push (${committerEmail})", footer: "${BUILD_NUMBER} Build Success!!", link: BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: DISCORD_WEBHOOK
        }
    }
}