pipeline {
    agent any

    stages {
        stage('Init') {
            steps {
                echo "Jenkins Pipeline Started"
            }
        }

        stage('Run CI Scripts') {
            steps {
                sh 'bash shared/ci/lint.sh user-service'
                sh 'bash shared/ci/test.sh user-service'
                sh 'bash shared/ci/scan.sh user-service'
            }
        }
    }
}
