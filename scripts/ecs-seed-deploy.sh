#!/usr/bin/env bash
# Déploie la dernière image Jenkins sur ECS (nécessaire après ajout EventSeeder / photos).
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-azaziop/event-management1}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG requis (ex. tag du dernier build Jenkins)}"
AWS_REGION="${AWS_REGION:-eu-west-3}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export IMAGE_NAME IMAGE_TAG AWS_REGION ECS_CLUSTER="${ECS_CLUSTER:-event-management-cluster}" ECS_SERVICE="${ECS_SERVICE:-event-management-service}"

echo "=== Déploiement image ${IMAGE_NAME}:${IMAGE_TAG} sur ECS ==="
"${SCRIPT_DIR}/ecs-deploy.sh"

echo ""
echo "Attente stabilisation du service (2–5 min)..."
aws ecs wait services-stable \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE}" \
    --region "${AWS_REGION}"

echo ""
echo "=== Déploiement terminé ==="
echo "Les événements de démo sont insérés au démarrage via migration (migrate --force)."
echo "Rechargez l'URL ALB dans le navigateur."
