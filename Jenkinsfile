pipeline {
    agent any

    tools{
        jdk "jdk17"
        nodejs "nodejs16"
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        API_KEY = "0e775d38damsh312b38c4f07187ep17a05ejsn994883147928"
    }

    parameters{
        string (name: 'DOCKER_HUB_USERNAME', defaultValue: 'jadonharsh', description: 'Docker Hub Username')
        string (name: 'IMAGE_NAME', defaultValue: 'youtube', description: 'Docker Image Name')
        choice (name: 'action', choices: 'create\ndelete', description: 'Select create or destroy.')
    }

    stages{
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

        stage ("SonarQube Analysis") {
        when { expression { params.action == 'create'}}
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh '''cd Application && $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=node-project -Dsonar.projectKey=node-project '''
                }   
            }
        }
        stage ("SonarQube QualityChecks") {
        when { expression { params.action == 'create'}}
            steps{
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: "sonar-token"
                }
            }
        }

        stage('OWASP Analysis') {
        when { expression { params.action == 'create'}}
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'owasp-scanner'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Trivy Analysis') {
        when { expression { params.action == 'create'}}
            steps {
                sh '''trivy fs . --format json -o trivy-fs-report.json'''
            }
        }

        // Fail Build in case on CRITICAL issue with code!!

        // stage('Trivy Result') {
        //     steps {
        //         sh '''trivy fs . --exit-code 1 --severity CRITICAL --format json -o trivy-check-report.json'''
        //     }
        // }

        stage('Build Docker Images') {
        when { expression { params.action == 'create'}}
            steps {
                sh "docker build --build-arg REACT_APP_RAPID_API_KEY=$API_KEY -t $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:latest Application/."
            }
        }

        stage('Run Docker Containers') {
        when { expression { params.action == 'create'}}
            steps {
                sh """docker rm -f ${params.IMAGE_NAME} && docker run --name ${params.IMAGE_NAME} -p 80:80 -d ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:latest"""
            }

            post{
                success {
                    sh '''IP=$(curl https://ipinfo.io/ip) && echo "Staging Application is deployed at $IP"'''
                }
            }
        }

        stage('Delete Docker Containers') {
        when { expression { params.action == 'delete'}}
            steps {
                sh "docker rm -f $params.IMAGE_NAME"
            }
        }

        stage('Deploy Docker Images') {
        when { expression { params.action == 'create'}}
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker'){
                        sh """
                        docker tag ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:latest ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}
                        docker tag ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:latest
                        docker push ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}
                        """
                    }
                }
            }
            post{
                always {
                    sh """
                    docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
                    docker rmi ${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Test Docker Images') {
        when { expression { params.action == 'create'}}
            steps {
                sh "trivy image $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:$BUILD_NUMBER -o trivy-image-report.json"
            }
        }

        stage('AWS Configure') {
            steps {
                withCredentials([aws(credentialsId: 'aws-cred', accessKeyVariable: 'AWS_ACCESS_KEY', secretKeyVariable: 'AWS_SECRET_KEY')]){
                    sh ''' aws configure set aws_access_key_id "${AWS_ACCESS_KEY}" && aws configure set aws_secret_access_key "${AWS_SECRET_KEY}" && aws configure set region "ap-south-1" && aws configure set output "json"'''
                }
            }
        }

        stage('Deploy on K8s') {
        when { expression { params.action == 'create'}}
            steps {
                withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kube_config', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                    sh """helm upgrade --install --force microservice-charts Helm-Charts --set IMAGE_ID=${params.DOCKER_HUB_USERNAME}/${params.IMAGE_NAME}:${BUILD_NUMBER}"""
                }
            }
        }

        stage('Delete on K8s') {
        when { expression { params.action == 'delete'}}
            steps {
                withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kube_config', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                    sh "kubectl delete -f Application/deployment.yml"
                }
            }
        }

        stage ("Clean Workspace") {
        when { expression { params.action == 'delete'}}
            steps {
                cleanWs()
            }
        }
    }

    post {
        failure {
            echo 'Discord Notifications'
            discordSend description: "${JOB_NAME} Triggered By GitHub Push (${committerEmail})", footer: "${BUILD_NUMBER} Build Failed!!" , link: BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: "https://discord.com/api/webhooks/1187472599043805335/5xoeKJ9NtiPp0tbS1B7c8yJb8BzTVu1NOPQscRJIpXXy4VrmFn2j9pJAqwa6q9g3N9Xz"
        }
        success {
            echo 'Discord Notifications'
            discordSend description: "${JOB_NAME} Triggered By GitHub Push (${committerEmail})", footer: "${BUILD_NUMBER} Build Success!!", link: BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: "https://discord.com/api/webhooks/1187472599043805335/5xoeKJ9NtiPp0tbS1B7c8yJb8BzTVu1NOPQscRJIpXXy4VrmFn2j9pJAqwa6q9g3N9Xz"
        }
    }
}