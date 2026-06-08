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
        stage('Vérification Docker') {
            steps {
                script {
                    def dockerAvailable = sh(
                        script: 'command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1',
                        returnStatus: true
                    ) == 0

                    if (!dockerAvailable) {
                        error '''Docker n''est pas disponible sur cet agent Jenkins.

Installez Docker sur le nœud Jenkins (obligatoire pour ce pipeline) :

  Si Jenkins tourne dans Docker, relancez-le avec :
    -v /var/run/docker.sock:/var/run/docker.sock

  Puis, dans le conteneur Jenkins :
    apt-get update && apt-get install -y docker.io
    usermod -aG docker jenkins

  Redémarrez Jenkins et relancez le pipeline.'''
                    }
                }
            }
        }

        stage('Build automatique de l\'application') {
            steps {
                sh '''
                    find app bootstrap config database public resources routes tests -type f \
                        \\( -name "* 2.*" -o -name "* 3.*" \\) -delete 2>/dev/null || true

                    # Envoi du code via tar (compatible Jenkins-in-Docker sur Mac)
                    # npm/vite doivent être silencieux : toute sortie stdout corrompt le tar binaire
                    mkdir -p "$WORKSPACE/public/build"
                    tar -C "$WORKSPACE" -cf - . | docker run --rm -i -w /app node:20-alpine sh -c '
                        set -e
                        tar -xf - -C /app
                        npm ci >/dev/null 2>&1 || npm install >/dev/null 2>&1
                        npm run build >/dev/null 2>&1
                        tar -cf /tmp/vite-assets.tar -C public/build .
                        base64 /tmp/vite-assets.tar
                    ' | base64 -d | tar -C "$WORKSPACE/public/build" -xf -
                    test -f "$WORKSPACE/public/build/manifest.json" || {
                        echo "Erreur : public/build/manifest.json introuvable après npm run build"
                        exit 1
                    }

                    tar -C "$WORKSPACE" -cf - . | docker run --rm -i -w /app php:8.2-cli bash -c '
                        apt-get update -qq
                        apt-get install -y -qq git unzip libzip-dev libsqlite3-dev
                        docker-php-ext-install pdo pdo_sqlite zip
                        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                        tar -xf - -C /app
                        composer install --prefer-dist --no-interaction --no-progress
                        php artisan --version
                    '
                '''
            }
        }

        stage('Exécution des tests (si disponibles)') {
            steps {
                sh '''
                    if [ -d tests ] && [ -f phpunit.xml ]; then
                        tar -C "$WORKSPACE" -cf - . | docker run --rm -i -w /app php:8.2-cli bash -c '
                            apt-get update -qq
                            apt-get install -y -qq git unzip libzip-dev libsqlite3-dev
                            docker-php-ext-install pdo pdo_sqlite zip
                            curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                            tar -xf - -C /app
                            composer install --prefer-dist --no-interaction --no-progress
                            cp -n .env.example .env 2>/dev/null || true
                            php artisan key:generate --force
                            php artisan test
                        '
                    else
                        echo "Aucun test disponible, étape ignorée."
                    fi
                '''
            }
        }

        stage('Vérification de la qualité du code') {
            steps {
                sh '''
                    tar -C "$WORKSPACE" -cf - . | docker run --rm -i -w /app php:8.2-cli bash -c '
                        apt-get update -qq
                        apt-get install -y -qq git unzip libzip-dev libsqlite3-dev
                        docker-php-ext-install pdo pdo_sqlite zip
                        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                        tar -xf - -C /app
                        composer install --prefer-dist --no-interaction --no-progress
                        if [ -f vendor/bin/pint ]; then
                            ./vendor/bin/pint --test
                        else
                            echo "Laravel Pint non disponible, étape ignorée."
                        fi
                    '
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
                // branch 'master' ne fonctionne qu'en Multibranch ; GIT_BRANCH couvre les jobs SCM classiques
                expression {
                    if (env.TAG_NAME?.trim()) {
                        return true
                    }
                    def branch = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: '').replaceFirst(/^origin\//, '').trim()
                    return branch in ['master', 'main', 'develop']
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
                expression {
                    if (env.TAG_NAME?.trim()) {
                        return true
                    }
                    def branch = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: '').replaceFirst(/^origin\//, '').trim()
                    return branch in ['master', 'main', 'develop']
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
                expression {
                    if (env.TAG_NAME?.trim()) {
                        return true
                    }
                    def branch = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: '').replaceFirst(/^origin\//, '').trim()
                    return branch in ['master', 'main']
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
IMAGE_NAME=$IMAGE_NAME
IMAGE_TAG=${TAG_NAME:-$IMAGE_TAG}
DEPLOY_ENV=${BRANCH_NAME:-production}
BUILD_NUMBER=${BUILD_NUMBER}
GIT_COMMIT=${GIT_COMMIT}
ECS_CLUSTER=${ECS_CLUSTER:-event-management-cluster}
ECS_SERVICE=${ECS_SERVICE:-event-management-service}
AWS_REGION=${AWS_REGION:-eu-west-3}
EOF

                        echo "=== Manifeste de déploiement ==="
                        cat deploy.env
                    '''
                }
                archiveArtifacts artifacts: 'deploy.env', fingerprint: true, allowEmptyArchive: false
            }
        }

        stage('Déploiement Kubernetes') {
            options {
                timeout(time: 25, unit: 'MINUTES')
            }
            when {
                expression {
                    if (env.DEPLOY_MINIKUBE == 'false') {
                        return false
                    }
                    if (env.TAG_NAME?.trim()) {
                        return true
                    }
                    def branch = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: '').replaceFirst(/^origin\//, '').trim()
                    return branch in ['master', 'main']
                }
            }
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
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

                            export IMAGE_TAG="${TAG_NAME:-$IMAGE_TAG}"
                            export HELM_RELEASE="${HELM_RELEASE:-eventapp}"
                            export K8S_NAMESPACE="${K8S_NAMESPACE:-default}"
                            export PATH="${HOME}/.local/bin:${PATH}"

                            chmod +x scripts/k8s-tools.sh scripts/minikube-setup.sh scripts/k8s-deploy.sh scripts/k8s-monitoring-deploy.sh
                            ./scripts/minikube-setup.sh
                            ./scripts/k8s-deploy.sh
                        '''
                    }
                }
            }
        }

        stage('Monitoring Kubernetes') {
            options {
                timeout(time: 15, unit: 'MINUTES')
            }
            when {
                expression {
                    if (env.DEPLOY_MINIKUBE == 'false') {
                        return false
                    }
                    if (env.TAG_NAME?.trim()) {
                        return true
                    }
                    def branch = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: '').replaceFirst(/^origin\//, '').trim()
                    return branch in ['master', 'main']
                }
            }
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    sh '''
                        export PATH="${HOME}/.local/bin:${PATH}"
                        chmod +x scripts/k8s-tools.sh scripts/k8s-monitoring-deploy.sh
                        ./scripts/k8s-monitoring-deploy.sh
                    '''
                }
            }
        }

        stage('Déploiement ECS (AWS)') {
            when {
                expression {
                    if (env.TAG_NAME?.trim()) {
                        return true
                    }
                    def branch = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: '').replaceFirst(/^origin\//, '').trim()
                    return branch in ['master', 'main']
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    ),
                    // Username = AWS_ACCESS_KEY_ID, Password = AWS_SECRET_ACCESS_KEY
                    // (pas besoin du plugin AmazonWebServicesCredentialsBinding)
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        if echo "$DOCKERHUB_REPOSITORY" | grep -q '/'; then
                            export IMAGE_NAME="$DOCKERHUB_REPOSITORY"
                        else
                            export IMAGE_NAME="$DOCKERHUB_USERNAME/$DOCKERHUB_REPOSITORY"
                        fi

                        export IMAGE_TAG="${TAG_NAME:-$IMAGE_TAG}"
                        export ECS_CLUSTER="${ECS_CLUSTER:-event-management-cluster}"
                        export ECS_SERVICE="${ECS_SERVICE:-event-management-service}"
                        export AWS_REGION="${AWS_REGION:-eu-west-3}"
                        export AWS_DEFAULT_REGION="$AWS_REGION"

                        chmod +x scripts/ecs-deploy.sh
                        ./scripts/ecs-deploy.sh
                    '''
                }
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
            sh 'command -v docker >/dev/null 2>&1 && docker logout || true'
        }
    }
}
