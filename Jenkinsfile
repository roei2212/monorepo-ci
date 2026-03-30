pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        SERVICES = "user-service,transaction-service,notification-service"
        REGISTRY = "your-docker-registry.example.com"   // למשל: docker.io/roei2212
        REGISTRY_CREDENTIALS = "docker-registry-creds"  // ID של credentials בג'נקינס
        SLACK_WEBHOOK_CREDENTIALS = "slack-webhook"     // ID של secret text / usernamePassword
    }

    triggers {
        pollSCM('H/2 * * * *') // או webhook – תלוי בהגדרה שלך
    }

    stages {

        stage('Pre-check: Branch Filter') {
            when {
                not {
                    anyOf {
                        branch 'main'
                        branch 'develop'
                    }
                }
            }
            steps {
                echo "Branch is not main/develop. Skipping CI."
                script { currentBuild.result = 'SUCCESS' }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Detect Changed Services') {
            steps {
                script {
                    echo "Detecting changed services..."

                    // קבצים שהשתנו בין הקומיט האחרון לקודם
                    def diff = sh(
                        script: "git diff --name-only HEAD~1 HEAD || true",
                        returnStdout: true
                    ).trim()

                    echo "Changed files:\n${diff}"

                    def allServices = ['user-service', 'transaction-service', 'notification-service']
                    def changedServicesLocal = [] as Set

                    if (diff) {
                        diff.split('\n').each { path ->
                            def top = path.tokenize('/')[0]
                            if (allServices.contains(top)) {
                                changedServicesLocal << top
                            }
                        }
                    }

                    if (changedServicesLocal.isEmpty()) {
                        echo "No services changed. Skipping CI."
                        currentBuild.result = 'SUCCESS'
                        // נשמור משתנה ריק כדי ששלבים אחרים ידלגו
                        env.CHANGED_SERVICES = ""
                    } else {
                        echo "Services changed: ${changedServicesLocal as List}"
                        env.CHANGED_SERVICES = (changedServicesLocal as List).join(',')
                    }
                }
            }
        }

        stage('Lint & Code Quality') {
            when {
                expression { return env.CHANGED_SERVICES?.trim() }
            }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.split(',')
                    def tasks = [:]

                    services.each { svc ->
                        tasks[svc] = {
                            stage("Lint: ${svc}") {
                                retry(2) {
                                    sh "bash shared/ci/lint.sh ${svc}"
                                }
                            }
                        }
                    }

                    parallel tasks + [failFast: true]
                }
            }
        }

        stage('Unit Tests') {
            when {
                expression { return env.CHANGED_SERVICES?.trim() }
            }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.split(',')
                    def tasks = [:]

                    services.each { svc ->
                        tasks[svc] = {
                            stage("Test: ${svc}") {
                                retry(2) {
                                    sh "bash shared/ci/test.sh ${svc}"
                                }
                                // דוחות JUnit (אם הסקריפטים מייצרים אותם)
                                junit allowEmptyResults: true, testResults: "${svc}/reports/junit/*.xml"
                                // כיסוי קוד – אפשר להרחיב לפי טכנולוגיה
                            }
                        }
                    }

                    parallel tasks + [failFast: true]
                }
            }
        }

        stage('Security Scans') {
            when {
                expression { return env.CHANGED_SERVICES?.trim() }
            }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.split(',')
                    def tasks = [:]

                    services.each { svc ->
                        tasks[svc] = {
                            stage("Security: ${svc}") {
                                retry(2) {
                                    sh "bash shared/ci/scan.sh ${svc}"
                                }
                            }
                        }
                    }

                    parallel tasks + [failFast: true]
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                expression { return env.CHANGED_SERVICES?.trim() }
            }
            steps {
                script {
                    def shortSha = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    def services = env.CHANGED_SERVICES.split(',')
                    def tasks = [:]

                    docker.withRegistry("https://${env.REGISTRY}", env.REGISTRY_CREDENTIALS) {
                        services.each { svc ->
                            tasks[svc] = {
                                stage("Docker: ${svc}") {
                                    retry(2) {
                                        sh """
                                          docker build -t ${env.REGISTRY}/${svc}:ci-${shortSha} ${svc}
                                          docker push ${env.REGISTRY}/${svc}:ci-${shortSha}
                                        """
                                    }
                                }
                            }
                        }

                        parallel tasks + [failFast: true]
                    }
                }
            }
        }

        stage('Manual Approval – Ready to Deploy') {
            when {
                expression { return env.CHANGED_SERVICES?.trim() }
            }
            steps {
                script {
                    input message: "Approve that build is READY TO DEPLOY (no deploy will be done here).", ok: "Approve"
                }
            }
        }
    }

    post {
        success {
            script {
                echo "Pipeline SUCCESS"
                sendNotification("SUCCESS")
            }
        }
        failure {
            script {
                echo "Pipeline FAILURE"
                sendNotification("FAILURE")
            }
        }
        unstable {
            script {
                echo "Pipeline UNSTABLE"
                sendNotification("UNSTABLE")
            }
        }
    }
}

def sendNotification(String status) {
    // שימוש ב‑credentials בלי לחשוף סוד
    withCredentials([string(credentialsId: env.SLACK_WEBHOOK_CREDENTIALS, variable: 'SLACK_WEBHOOK')]) {
        sh """
          curl -X POST -H 'Content-type: application/json' \
            --data '{\"text\": \"Jenkins CI for monorepo finished with status: ${status}\"}' \
            "$SLACK_WEBHOOK"
        """
    }
}
