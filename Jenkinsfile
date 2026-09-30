pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    // Check GitHub every 5 minutes (simple option; a webhook is the alternative)
    triggers { pollSCM('H/5 * * * *') }

    // Run manually with a build number (e.g. 5) to roll back to that version
    parameters {
        string(name: 'ROLLBACK_TO', defaultValue: '',
               description: 'Leave EMPTY for a normal CI/CD run. Enter an older build number (e.g. 5) to roll back.')
    }

    // ---- Environment configuration ----
    environment {
        IMAGE_TAG            = "${env.BUILD_NUMBER}"
        COMPOSE_PROJECT_NAME = 'contactbook'
        MYSQL_DATABASE       = 'contactbook'
        MYSQL_USER           = 'contactuser'
        // Secrets come from Jenkins > Manage Jenkins > Credentials (never from Git)
        MYSQL_PASSWORD       = credentials('mysql-app-password')
        MYSQL_ROOT_PASSWORD  = credentials('mysql-root-password')
        APP_URL              = 'http://localhost:8081'
        STATE_DIR            = "${env.JENKINS_HOME}/contactbook-state"
        TRIVY_SEVERITY       = 'HIGH,CRITICAL'
        KEEP_IMAGES          = '5'
    }

    stages {
        stage('Checkout') {
            when { expression { !params.ROLLBACK_TO } }
            steps {
                checkout scm
                sh '''
                    git log -1 --oneline
                    docker version --format 'Docker {{.Server.Version}}'
                    docker compose version
                '''
            }
        }

        stage('Build & Test') {
            when { expression { !params.ROLLBACK_TO } }
            steps {
                // The "test" stage in backend/Dockerfile runs pytest; a failing test fails the build
                sh 'docker build --target test -t contactbook-backend-test:${BUILD_NUMBER} backend'
            }
        }

        stage('Build Docker Images') {
            when { expression { !params.ROLLBACK_TO } }
            steps {
                sh 'docker compose build'
                sh 'docker images --filter "reference=contactbook-*"'
            }
        }

        stage('Trivy Security Scan') {
            when { expression { !params.ROLLBACK_TO } }
            steps {
                sh 'bash scripts/trivy_scan.sh'
            }
        }

        stage('Deploy') {
            when { expression { !params.ROLLBACK_TO } }
            steps {
                script { env.DEPLOY_STARTED = 'true' }
                sh 'bash scripts/deploy.sh'
            }
        }

        stage('Health Check') {
            when { expression { !params.ROLLBACK_TO } }
            steps {
                sh 'bash scripts/health_check.sh "$APP_URL/api/health"'
                sh 'docker compose ps'
                // Remember this version as the "last known good" release
                sh 'mkdir -p "$STATE_DIR" && echo "$IMAGE_TAG" > "$STATE_DIR/current_tag"'
            }
        }

        stage('Cleanup Old Images') {
            when { expression { !params.ROLLBACK_TO } }
            steps {
                sh 'bash scripts/cleanup_images.sh'
            }
        }

        stage('Manual Rollback') {
            when { expression { params.ROLLBACK_TO } }
            steps {
                sh 'bash scripts/rollback.sh "$ROLLBACK_TO"'
            }
        }
    }

    post {
        failure {
            script {
                // Automatic rollback: only if we had already started deploying
                if (env.DEPLOY_STARTED == 'true') {
                    echo 'Deploy or health check FAILED - rolling back to the last good version'
                    sh '''
                        if [ -f "$STATE_DIR/current_tag" ]; then
                            bash scripts/rollback.sh "$(cat "$STATE_DIR/current_tag")"
                        else
                            echo "No earlier release recorded - nothing to roll back to."
                            docker compose logs --tail=50 || true
                        fi
                    '''
                }
            }
        }
        always {
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            sh 'docker rmi contactbook-backend-test:${BUILD_NUMBER} || true'
        }
    }
}
