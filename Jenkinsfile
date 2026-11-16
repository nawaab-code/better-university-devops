// Better University Campus API - declarative pipeline (Component 1).
// Checkout -> Test -> Build -> archive the versioned fat JAR.
pipeline {
    agent any

    options {
        skipDefaultCheckout(true)          // the Checkout stage does it explicitly
        timestamps()
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
    }

    // Poll GitHub every minute; a new commit on main starts a build.
    triggers {
        pollSCM('* * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    def scmVars = checkout scm
                    env.SHORT_SHA = scmVars.GIT_COMMIT.take(7)
                    // Version = <build number>-<short commit sha>, e.g. 7-3fa9c21
                    env.APP_VERSION = "${env.BUILD_NUMBER}-${env.SHORT_SHA}"
                    currentBuild.displayName = "#${env.BUILD_NUMBER} v${env.APP_VERSION}"
                    currentBuild.description = "bu-campus-api ${env.APP_VERSION}"
                }
                echo "Building version ${env.APP_VERSION}"
            }
        }

        stage('Test') {
            steps {
                sh 'java -version && ./gradlew --version | head -8'
                sh './gradlew test --console=plain'
            }
            post {
                always {
                    junit testResults: 'build/test-results/test/*.xml', allowEmptyResults: false
                }
            }
        }

        stage('Build') {
            steps {
                sh "./gradlew build -x test -PappVersion=${env.APP_VERSION} --console=plain"
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: 'build/libs/*-all.jar', fingerprint: true
        }
        failure {
            echo 'Build failed - see the console output above.'
        }
    }
}
