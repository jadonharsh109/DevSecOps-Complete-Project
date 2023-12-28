pipeline {
    agent any

    tools{
        jdk "jdk17"
        nodejs "nodejs16"
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        API_KEY = "0e775d38damsh312b38c4f07187ep17a05ejsn994883147928"
        DOCKER_HUB_USERNAME = "jadonharsh"
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
                sh '''trivy fs . --format json -o trivy-check-report.json'''
            }
        }

        // Fail Build in case on CRITICAL issue with code!!

        // stage('Trivy Result') {
        //     steps {
        //         sh '''trivy fs . --exit-code 1 --severity CRITICAL --format json -o trivy-check-report.json'''
        //     }
        // }

        // stage ("Clean Workspace") {
        //     steps {
        //         cleanWs()
        //     }
        // }

        stage('Build Docker Images') {
            steps {
                sh "docker build --build-arg REACT_APP_RAPID_API_KEY=$API_KEY -t $DOCKER_HUB_USERNAME/youtube:latest Application/."
            }
        }

        stage('Deploy Docker Images') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker'){
                        sh "docker push $DOCKER_HUB_USERNAME/youtube:latest "
                    }
                }
                post{
                    always {
                        sh '''docker rmi $(docker images --filter "dangling=true" -q --no-trunc)'''
                    }
                }
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