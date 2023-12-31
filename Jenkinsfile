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
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh '''cd Application && $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=node-project -Dsonar.projectKey=node-project '''
                }   
            }
        }
        stage ("SonarQube QualityChecks") {
            steps{
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: "sonar-token"
                }
            }
        }

        stage('OWASP Analysis') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'owasp-scanner'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Trivy Analysis') {
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
            steps {
                sh "docker build --build-arg REACT_APP_RAPID_API_KEY=$API_KEY -t $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:latest Application/."
            }
        }

        stage('Run Docker Images') {
        when { expression { params.action == 'create'}}
            steps {
                sh "docker run -name $params.IMAGE_NAME -p 80:80 $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:latest"
            }

            post{
                success {
                    sh '''IP=$(curl https://ipinfo.io/ip) && echo "Staging Application is deployed at $IP"'''
                }
            }
        }

        stage('Run Docker Images') {
        when { expression { params.action == 'delete'}}
            steps {
                sh "docker rm -f $params.IMAGE_NAME"
            }
        }

        stage('Deploy Docker Images') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker'){
                        sh "docker push $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:latest "
                    }
                }
            }
            post{
                always {
                    sh '''docker rmi $(docker images --filter "dangling=true" -q --no-trunc)'''
                }
            }
        }

        stage('Test Docker Images') {
            steps {
                sh "trivy image $params.DOCKER_HUB_USERNAME/$params.IMAGE_NAME:latest -o trivy-image-report.json"
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