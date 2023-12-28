pipeline {
    agent any

    stages{
        stage ("Hello World") {
            steps {
                echo "hello world from jenkins"
            }
        }
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
    }

    post {
        failure {
            echo 'Discord Notifications'
            discordSend description: "DevSecOps Pipeline Build by ${committerEmail}", footer: BUILD_NUMBER, link: BUILD_URL, result: "Build Failed!!", title: JOB_NAME, webhookURL: "https://discord.com/api/webhooks/1187472599043805335/5xoeKJ9NtiPp0tbS1B7c8yJb8BzTVu1NOPQscRJIpXXy4VrmFn2j9pJAqwa6q9g3N9Xz"
        }
        success {
            echo 'Discord Notifications'
            discordSend description: "DevSecOps Pipeline Build by ${committerEmail}", footer: BUILD_NUMBER, link: BUILD_URL, result: "Build Successfull!!", title: JOB_NAME, webhookURL: "https://discord.com/api/webhooks/1187472599043805335/5xoeKJ9NtiPp0tbS1B7c8yJb8BzTVu1NOPQscRJIpXXy4VrmFn2j9pJAqwa6q9g3N9Xz"
        }
}
}