pipeline {
    agent any

    environment {
        DOCKERHUB_REPOSITORY = 'event-management1'
        COMPOSER_ALLOW_SUPERUSER = '1'
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
        LOCAL_IMAGE = "events-app:${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Build automatique de l\'application') {
            steps {
                sh '''
                    find app bootstrap config database public resources routes tests -type f \
                        \\( -name "* 2.*" -o -name "* 3.*" \\) -delete 2>/dev/null || true

                    docker run --rm -v "$PWD:/app" -w /app node:20-alpine sh -c "
                        npm ci
                        npm run build
                    "

                    docker run --rm -v "$PWD:/app" -w /app php:8.2-cli bash -c "
                        apt-get update -qq
                        apt-get install -y -qq git unzip libzip-dev libsqlite3-dev curl
                        docker-php-ext-install pdo pdo_sqlite zip
                        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                        composer install --prefer-dist --no-interaction --no-progress
                        php artisan --version
                    "
                '''
            }
        }

        stage('Exécution des tests (si disponibles)') {
            steps {
                sh '''
                    if [ -d tests ] && [ -f phpunit.xml ]; then
                        docker run --rm -v "$PWD:/app" -w /app php:8.2-cli bash -c "
                            apt-get update -qq
                            apt-get install -y -qq git unzip libzip-dev libsqlite3-dev curl
                            docker-php-ext-install pdo pdo_sqlite zip
                            curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                            cp .env.example .env
                            composer install --prefer-dist --no-interaction --no-progress
                            php artisan key:generate
                            php artisan test
                        "
                    else
                        echo "Aucun test disponible, étape ignorée."
                    fi
                '''
            }
        }

        stage('Vérification de la qualité du code') {
            steps {
                sh '''
                    if [ -f vendor/bin/pint ]; then
                        docker run --rm -v "$PWD:/app" -w /app php:8.2-cli ./vendor/bin/pint --test
                    else
                        echo "Laravel Pint non disponible, étape ignorée."
                    fi
                '''
            }
        }

        stage('Construction des images Docker') {
            steps {
                sh """
                    docker build --pull -t ${LOCAL_IMAGE} .
                    docker tag ${LOCAL_IMAGE} events-app:latest
                """
            }
        }

        stage('Push automatique des images Docker') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                    expression { return env.TAG_NAME != null }
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh """
                        if echo "\$DOCKERHUB_REPOSITORY" | grep -q '/'; then
                            export IMAGE_NAME="\$DOCKERHUB_REPOSITORY"
                        else
                            export IMAGE_NAME="\$DOCKERHUB_USERNAME/\$DOCKERHUB_REPOSITORY"
                        fi

                        docker tag ${LOCAL_IMAGE} "\$IMAGE_NAME:\$IMAGE_TAG"
                        docker tag ${LOCAL_IMAGE} "\$IMAGE_NAME:latest"

                        echo "Images taguées pour le push :"
                        docker images "\$IMAGE_NAME"
                    """
                }
            }
        }

        stage('Publication sur un registry (Docker Hub)') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                    expression { return env.TAG_NAME != null }
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        if echo "$DOCKERHUB_REPOSITORY" | grep -q '/'; then
                            export IMAGE_NAME="$DOCKERHUB_REPOSITORY"
                        else
                            export IMAGE_NAME="$DOCKERHUB_USERNAME/$DOCKERHUB_REPOSITORY"
                        fi

                        echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

                        docker push "$IMAGE_NAME:$IMAGE_TAG"
                        docker push "$IMAGE_NAME:latest"
                    '''
                }
            }
        }

        stage('Préparation du déploiement sur l\'environnement cible') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    expression { return env.TAG_NAME != null }
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        if echo "$DOCKERHUB_REPOSITORY" | grep -q '/'; then
                            export IMAGE_NAME="$DOCKERHUB_REPOSITORY"
                        else
                            export IMAGE_NAME="$DOCKERHUB_USERNAME/$DOCKERHUB_REPOSITORY"
                        fi

                        cat > deploy.env <<EOF
IMAGE_NAME=\$IMAGE_NAME
IMAGE_TAG=\${TAG_NAME:-\$IMAGE_TAG}
DEPLOY_ENV=\${BRANCH_NAME:-production}
BUILD_NUMBER=\${BUILD_NUMBER}
GIT_COMMIT=\${GIT_COMMIT}
EOF

                        echo "=== Manifeste de déploiement ==="
                        cat deploy.env
                        echo ""
                        echo "=== Commandes de déploiement suggérées ==="
                        echo "docker pull \$IMAGE_NAME:\${TAG_NAME:-\$IMAGE_TAG}"
                        echo "docker compose -f docker-compose.prod.yml up -d"
                    '''
                }
                archiveArtifacts artifacts: 'deploy.env', fingerprint: true, allowEmptyArchive: false
            }
        }
    }

    post {
        success {
            echo 'Pipeline CI/CD terminé avec succès.'
        }
        failure {
            echo 'Pipeline CI/CD en échec.'
        }
        always {
            sh 'docker logout || true'
        }
    }
}