#!/usr/bin/env bash
# Déploie une nouvelle image sur ECS (nouvelle révision de task definition + rolling update).
set -euo pipefail

CLUSTER="${ECS_CLUSTER:-event-management-cluster}"
SERVICE="${ECS_SERVICE:-event-management-service}"
AWS_REGION="${AWS_REGION:-eu-west-3}"
IMAGE_NAME="${IMAGE_NAME:?IMAGE_NAME requis}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG requis}"

NEW_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

# Sur l'agent Jenkins (souvent sans aws/jq), exécuter via un conteneur éphémère.
if [[ "${ECS_DEPLOY_IN_DOCKER:-}" != "1" ]] && { ! command -v aws >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; }; then
    if command -v docker >/dev/null 2>&1; then
        SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ecs-deploy.sh"
        echo "AWS CLI ou jq introuvable sur l'hôte — exécution via conteneur alpine"
        exec docker run --rm --entrypoint bash \
            -e ECS_DEPLOY_IN_DOCKER=1 \
            -e AWS_ACCESS_KEY_ID \
            -e AWS_SECRET_ACCESS_KEY \
            -e AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-$AWS_REGION}" \
            -e AWS_REGION="$AWS_REGION" \
            -e ECS_CLUSTER="$CLUSTER" \
            -e ECS_SERVICE="$SERVICE" \
            -e IMAGE_NAME="$IMAGE_NAME" \
            -e IMAGE_TAG="$IMAGE_TAG" \
            -v "${SCRIPT_PATH}:/ecs-deploy.sh:ro" \
            alpine:3.19 \
            -c 'apk add --no-cache aws-cli jq bash >/dev/null 2>&1 && bash /ecs-deploy.sh'
    fi
    command -v aws >/dev/null 2>&1 || { echo "AWS CLI introuvable"; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo "jq introuvable (brew install jq / apt install jq)"; exit 1; }
fi

echo "=== Déploiement ECS : ${NEW_IMAGE} ==="

TASK_ARN="$(aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$AWS_REGION" \
  --query 'services[0].taskDefinition' \
  --output text)"

aws ecs describe-task-definition \
  --task-definition "$TASK_ARN" \
  --region "$AWS_REGION" \
  --query 'taskDefinition' > /tmp/task-def.json

jq 'del(
  .taskDefinitionArn,
  .revision,
  .status,
  .requiresAttributes,
  .compatibilities,
  .registeredAt,
  .registeredBy
)' /tmp/task-def.json > /tmp/task-def-clean.json

jq --arg img "$NEW_IMAGE" \
  '(.containerDefinitions[] | select(.name == "backend") | .image) = $img' \
  /tmp/task-def-clean.json > /tmp/task-def-new.json

NEW_ARN="$(aws ecs register-task-definition \
  --region "$AWS_REGION" \
  --cli-input-json file:///tmp/task-def-new.json \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)"

aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --region "$AWS_REGION" \
  --task-definition "$NEW_ARN" \
  --force-new-deployment \
  --query 'service.{serviceName:serviceName,taskDefinition:taskDefinition,desiredCount:desiredCount}' \
  --output table

echo "Déploiement lancé : $NEW_ARN"
echo "Suivi : aws ecs wait services-stable --cluster $CLUSTER --services $SERVICE --region $AWS_REGION"
