pipeline {
    agent any

    stages {

        stage('Detect Changed Services') {
            steps {
                script {
                    echo "Detecting changed services..."

                    // קבלת קבצים שהשתנו
                    def diff = sh(
                        script: "git diff --name-only origin/main...HEAD || true",
                        returnStdout: true
                    ).trim()

                    echo "Changed files:\n${diff}"

                    // הפקת שמות שירותים
                    changedServices = diff
                        .split('\n')
                        .collect { it.split('/')[0] }
                        .unique()
                        .findAll { it in ['user-service', 'transaction-service', 'notification-service'] }

                    if (changedServices.isEmpty()) {
                        echo "No services changed. Skipping CI."
                        currentBuild.result = 'SUCCESS'
                        return
                    }

                    echo "Services changed: ${changedServices}"
                }
            }
        }

        stage('Run CI for Changed Services') {
            when {
                expression { return changedServices && changedServices.size() > 0 }
            }
            steps {
                script {
                    def tasks = [:]

                    changedServices.each { svc ->
                        tasks[svc] = {
                            stage("CI for ${svc}") {
                                sh "bash shared/ci/lint.sh ${svc}"
                                sh "bash shared/ci/test.sh ${svc}"
                                sh "bash shared/ci/scan.sh ${svc}"
                            }
                        }
                    }

                    parallel tasks
                }
            }
        }
    }
}
