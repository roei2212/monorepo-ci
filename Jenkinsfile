pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        SERVICES = "user-service,transaction-service,notification-service"
        REGISTRY_CREDENTIALS = "Dockerhub-roei"
    }

    stages {

        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Detect Changed Services') {
            steps {
                script {
                    def diff = sh(
                        script: "git diff --name-only HEAD~1 HEAD || true",
                        returnStdout: true
                    ).trim()

                    def all = ['user-service','transaction-service','notification-service']
                    def changed = [] as Set

                    diff.split('\n').each { f ->
                        def top = f.tokenize('/')[0]
                        if (all.contains(top)) changed << top
                    }

                    env.CHANGED_SERVICES = changed ? changed.join(',') : ""
                    echo "Changed services: ${env.CHANGED_SERVICES}"
                }
            }
        }

        /* -------------------------
           LINT
        -------------------------- */
        stage('Lint') {
            when { expression { env.CHANGED_SERVICES } }
            steps {
                script {
                    def tasks = [:]

                    env.CHANGED_SERVICES.split(',').each { svc ->
                        tasks[svc] = {
                            stage("Lint: ${svc}") {

                                if (svc == "user-service") {
                                    docker.image('node:18').inside {
                                        sh "bash shared/ci/lint.sh ${svc}"
                                    }
                                }

                                if (svc == "transaction-service") {
                                    docker.image('python:3.11').inside {
                                        sh "pip install flake8 pylint"
                                        sh "bash shared/ci/lint.sh ${svc}"
                                    }
                                }

                                if (svc == "notification-service") {
                                    docker.image('golang:1.22').inside {
                                        sh "bash shared/ci/lint.sh ${svc}"
                                    }
                                }
                            }
                        }
                    }

                    parallel tasks
                }
            }
        }

        /* -------------------------
           TESTS
        -------------------------- */
        stage('Tests') {
            when { expression { env.CHANGED_SERVICES } }
            steps {
                script {
                    def tasks = [:]

                    env.CHANGED_SERVICES.split(',').each { svc ->
                        tasks[svc] = {
                            stage("Test: ${svc}") {

                                if (svc == "user-service") {
                                    docker.image('node:18').inside {
                                        sh "bash shared/ci/test.sh ${svc}"
                                    }
                                }

                                if (svc == "transaction-service") {
                                    docker.image('python:3.11').inside {
                                        sh "pip install pytest pytest-cov"
                                        sh "bash shared/ci/test.sh ${svc}"
                                    }
                                }

                                if (svc == "notification-service") {
                                    docker.image('golang:1.22').inside {
                                        sh "bash shared/ci/test.sh ${svc}"
                                    }
                                }
                            }
                        }
                    }

                    parallel tasks
                }
            }
        }

        /* -------------------------
           SECURITY
        -------------------------- */
        stage('Security') {
            when { expression { env.CHANGED_SERVICES } }
            steps {
                script {
                    def tasks = [:]

                    env.CHANGED_SERVICES.split(',').each { svc ->
                        tasks[svc] = {
                            stage("Security: ${svc}") {

                                if (svc == "user-service") {
                                    docker.image('node:18').inside {
                                        sh "bash shared/ci/scan.sh ${svc}"
                                    }
                                }

                                if (svc == "transaction-service") {
                                    docker.image('python:3.11').inside {
                                        sh "pip install bandit"
                                        sh "bash shared/ci/scan.sh ${svc}"
                                    }
                                }

                                if (svc == "notification-service") {
                                    docker.image('golang:1.22').inside {
                                        sh "bash shared/ci/scan.sh ${svc}"
                                    }
                                }
                            }
                        }
                    }

                    parallel tasks
                }
            }
        }

        /* -------------------------
           DOCKER BUILD & PUSH
        -------------------------- */
        stage('Docker Build & Push') {
            when { expression { env.CHANGED_SERVICES } }
            steps {
                script {
                    def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def tasks = [:]

                    env.CHANGED_SERVICES.split(',').each { svc ->
                        tasks[svc] = {
                            stage("Docker: ${svc}") {

                                withDockerRegistry([url: "https://index.docker.io/v1/", credentialsId: env.REGISTRY_CREDENTIALS]) {
                                    sh """
                                        docker build -t roei2212/${svc}:${sha} ${svc}
                                        docker push roei2212/${svc}:${sha}
                                    """
                                }

                            }
                        }
                    }

                    parallel tasks
                }
            }
        }
    }

    post {
        success { echo "SUCCESS" }
        failure { echo "FAILURE" }
    }
}
